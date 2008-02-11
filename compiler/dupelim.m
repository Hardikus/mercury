%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sw=4 et
%-----------------------------------------------------------------------------%
% Copyright (C) 1995-2007 The University of Melbourne.
% This file may only be copied under the terms of the GNU General
% Public License - see the file COPYING in the Mercury distribution.
%-----------------------------------------------------------------------------%
%
% File: dupelim.m.
% Author: zs.
%
% This module eliminate some duplicate code sequences.
%
% Our algorithm has the following stages.
%
% 1.    Divide the code of the procedure into basic blocks.
%
% 2.    For each block, compute a standard form, which is its most general
%       generalization.
%
% 3.    Find out which sets of blocks have the same standard form.
%
% 4.    For each set of blocks with the same standard form, find out
%       which blocks are not fallen into and can thus be eliminated,
%       and choose which blocks will be eliminated.
%
% 5.    For each set of blocks with the same standard form, compute
%       their most specific common generalization (which must exist),
%       and substitute this code for the code of the copy of the block
%       that step 4 has decided to keep.
%
% 6.    Convert the (possibly reduced) list of basic blocks back to a
%       list of instructions and substitute all references to the labels
%       starting eliminated blocks to refer to their noneliminated version.
%
% Generalizing an rval, lval or instruction involves replacing field references
% with known tags with field references with unknown tags. Generalizing a block
% involves generalizing its constituent instructions, removing comments, and
% possibly adding a goto at the end to represent falling through to the next
% label. In all other ways the original and the generalized version will be
% identical.
% 
%-----------------------------------------------------------------------------%
 
:- module ll_backend.dupelim.
:- interface.

:- import_module ll_backend.llds.
:- import_module mdbcomp.prim_data.

:- import_module counter.
:- import_module list.

%-----------------------------------------------------------------------------%

:- pred dupelim_main(proc_label::in, counter::in, counter::out,
    list(instruction)::in, list(instruction)::out) is det.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- import_module libs.compiler_util.
:- import_module ll_backend.basic_block.
:- import_module ll_backend.opt_util.

:- import_module bool.
:- import_module map.
:- import_module maybe.
:- import_module pair.
:- import_module set.
:- import_module svmap.
:- import_module svset.

%-----------------------------------------------------------------------------%

    % A std_map maps a list of standardized instructions to the list
    % of labels whose basic blocks have that standardized form.
    %
:- type std_map == map(list(instr), list(label)).

    % cluster(Exemplar, OtherLabels) means that references to labels
    % in OtherLabels can be replaced with references to Exemplar
    % once its block has been replaced with the most specific
    % generalization of the blocks started by Exemplar and OtherLabels.
    % OtherLabels must be nonempty.
    %
:- type cluster
    --->    cluster(label, list(label)).

dupelim_main(ProcLabel, !C, Instrs0, Instrs) :-
    create_basic_blocks(Instrs0, Comments, ProcLabel, !C, _NewLabels,
        LabelSeq0, BlockMap0),
    map.init(StdMap0),
    set.init(Fixed0),
    dupelim_build_maps(LabelSeq0, BlockMap0, StdMap0, StdMap, Fixed0, Fixed),
    map.values(StdMap, StdList),
    find_clusters(StdList, Fixed, [], Clusters),
    (
        Clusters = [],
        % We don't want to introduce any incidental changes
        % if we cannot eliminate any blocks.
        Instrs = Instrs0
    ;
        Clusters = [_ | _],
        map.init(ReplMap0),
        process_clusters(Clusters, LabelSeq0, LabelSeq, BlockMap0, BlockMap,
            ReplMap0, ReplMap),
        flatten_basic_blocks(LabelSeq, BlockMap, Instrs1),
        opt_util.replace_labels_instruction_list(Instrs1, Instrs2,
            ReplMap, yes, no),
        Instrs = Comments ++ Instrs2
    ).

%-----------------------------------------------------------------------------%

    % dupelim_build_maps builds up a map mapping standardized instruction
    % sequences to the label(s) that start basic blocks with that standardized
    % form, and a set showing which labels are fallen into.
    %
:- pred dupelim_build_maps(list(label)::in, block_map::in,
    std_map::in, std_map::out, set(label)::in, set(label)::out) is det.

dupelim_build_maps([], _, !StdMap, !Fixed).
dupelim_build_maps([Label | Labels], BlockMap, !StdMap, !Fixed) :-
    map.lookup(BlockMap, Label, BlockInfo),
    BlockInfo = block_info(_, _, Instrs, _, _, MaybeFallThrough),
    standardize_instr_block(Instrs, MaybeFallThrough, StdInstrs),
    ( map.search(!.StdMap, StdInstrs, Cluster) ->
        svmap.det_update(StdInstrs, [Label | Cluster], !StdMap)
    ;
        svmap.det_insert(StdInstrs, [Label], !StdMap)
    ),
    (
        MaybeFallThrough = yes(FallIntoLabel),
        svset.insert(FallIntoLabel, !Fixed)
    ;
        MaybeFallThrough = no
    ),
    list.foldl(add_pragma_pref_labels, Instrs, !Fixed),
    dupelim_build_maps(Labels, BlockMap, !StdMap, !Fixed).

:- pred add_pragma_pref_labels(instruction::in,
    set(label)::in, set(label)::out) is det.

add_pragma_pref_labels(Instr, !FoldFixed) :-
    (
        Instr = llds_instr(foreign_proc_code(_, _, _, MaybeFixedLabel,
            MaybeLayoutLabel, MaybeOnlyLayoutLabel, _, _, _), _)
    ->
        (
            MaybeFixedLabel = yes(FixedLabel),
            svset.insert(FixedLabel, !FoldFixed)
        ;
            MaybeFixedLabel = no
        ),
        (
            MaybeLayoutLabel = yes(LayoutLabel),
            svset.insert(LayoutLabel, !FoldFixed)
        ;
            MaybeLayoutLabel = no
        ),
        (
            MaybeOnlyLayoutLabel = yes(OnlyLayoutLabel),
            svset.insert(OnlyLayoutLabel, !FoldFixed)
        ;
            MaybeOnlyLayoutLabel = no
        )
    ;
        true
    ).

    % For each set of labels that start basic blocks with identical standard
    % forms, find_clusters finds out whether we can eliminate some of those
    % blocks; if yes, it decides which blocks can be eliminated and which
    % other block should stand in their place.
    %
    % If two or more blocks have the same standardized form, it may be possible
    % to eliminate all but one of the blocks. However, blocks that can be
    % fallen into cannot be eliminated. (Actually, they could, but only by
    % inserting a goto, and full jumpopt would then undo the elimination of
    % the block.) Similarly, blocks whose starting label is referred to by C
    % code cannot be eliminated. (Actually, they could, but only by doing
    % surgery on C code strings, which is not a good idea.)
    %
:- pred find_clusters(list(list(label))::in, set(label)::in,
    list(cluster)::in, list(cluster)::out) is det.

find_clusters([], _, !Clusters).
find_clusters([Labels | LabelsList], Fixed, !Clusters) :-
    (
        Labels = [_, _ | _],
        % The rest of the condition is relatively expensive, so don't do it
        % if there aren't at least two labels whose blocks have the same
        % standardized form.
        IsFallenInto = (pred(Label::in) is semidet :-
            set.member(Label, Fixed)
        ),
        list.filter(IsFallenInto, Labels, FixedLabels, NonFixedLabels),
        NonFixedLabels = [FirstNonFixed | OtherNonFixed]
    ->
        (
            FixedLabels = [ChosenLabel | _],
            Cluster = cluster(ChosenLabel, NonFixedLabels)
        ;
            FixedLabels = [],
            Cluster = cluster(FirstNonFixed, OtherNonFixed)
        ),
        !:Clusters = [Cluster | !.Clusters]
    ;
        true
    ),
    find_clusters(LabelsList, Fixed, !Clusters).

%-----------------------------------------------------------------------------%

    % For each cluster, a set of blocks in which all but one are to be
    % eliminated favor of the remaining one, find their most specific common
    % generalization (which must exist), and substitute this code for the code
    % of the copy of the block that is to be kept. Remove the eliminated labels
    % from the label sequence and map them to their replacements.
    %
:- pred process_clusters(list(cluster)::in, list(label)::in, list(label)::out,
    block_map::in, block_map::out,
    map(label, label)::in, map(label, label)::out) is det.

process_clusters([], !LabelSeq, !BlockMap, !ReplMap).
process_clusters([Cluster | Clusters], !LabelSeq, !BlockMap, !ReplMap) :-
    Cluster = cluster(Exemplar, ElimLabels),
    map.lookup(!.BlockMap, Exemplar, ExemplarInfo0),
    ExemplarInfo0 = block_info(ExLabel, ExLabelInstr, ExInstrs0,
        ExFallInto, ExSideLabels, ExMaybeFallThrough),
    expect(unify(Exemplar, ExLabel), this_file, "exemplar label mismatch"),
    process_elim_labels(ElimLabels, ExInstrs0, !LabelSeq, !.BlockMap,
        Exemplar, !ReplMap, UnifiedInstrs,
        ExMaybeFallThrough, UnifiedMaybeFallThrough),
    ExemplarInfo = block_info(ExLabel, ExLabelInstr, UnifiedInstrs,
        ExFallInto, ExSideLabels, UnifiedMaybeFallThrough),
    svmap.det_update(Exemplar, ExemplarInfo, !BlockMap),
    process_clusters(Clusters, !LabelSeq, !BlockMap, !ReplMap).

    % Given the current form of a basic block (instructions and fallthrough),
    % compute its most specific generalization with the basic blocks headed
    % by the given labels, whose basic blocks are to be eliminated.
    %
    % On the same traversal of the list of to-be-eliminated labels, remove each
    % such label from the sequence of labels whose basic blocks will make up
    % the final code of the procedure, and add the mapping of the eliminated
    % label to the replacement (exemplar) label to the set of substitutions
    % that will need to be done.
    %
:- pred process_elim_labels(list(label)::in, list(instruction)::in,
    list(label)::in, list(label)::out, block_map::in,
    label::in, map(label, label)::in, map(label, label)::out,
    list(instruction)::out, maybe(label)::in, maybe(label)::out) is det.

process_elim_labels([], Instrs, !LabelSeq, _, _, !ReplMap, Instrs,
        !MaybeFallThrough).
process_elim_labels([ElimLabel | ElimLabels], Instrs0, !LabelSeq, BlockMap,
        Exemplar, !ReplMap, Instrs, !MaybeFallThrough) :-
    map.lookup(BlockMap, ElimLabel, ElimLabelInfo),
    ElimLabelInfo = block_info(ElimLabel2, _, ElimInstrs,
        _, _, ElimMaybeFallThrough),
    expect(unify(ElimLabel, ElimLabel2), this_file, "elim label mismatch"),
    (
        most_specific_block(Instrs0, !.MaybeFallThrough, ElimInstrs,
            ElimMaybeFallThrough, Instrs1, !:MaybeFallThrough)
    ->
        list.delete_all(!.LabelSeq, ElimLabel, !:LabelSeq),
        map.det_insert(!.ReplMap, ElimLabel, Exemplar, !:ReplMap),
        process_elim_labels(ElimLabels, Instrs1, !LabelSeq, BlockMap,
            Exemplar, !ReplMap, Instrs, !MaybeFallThrough)
    ;
        unexpected(this_file,
            "blocks with same standard form don't antiunify")
    ).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

    % The code of this section is concerned with computing the standard
    % form (most general generalization) of a sequence of instructions.
    %
    % If a block can fall through, we add a goto to the following label
    % at the end. This way, it will match with other blocks that have
    % identical (standardized) content except for an explicit goto to our
    % fallthrough label.
    %
:- pred standardize_instr_block(list(instruction)::in, maybe(label)::in,
    list(instr)::out) is det.

standardize_instr_block(Instrs0, MaybeFallThrough, Uinstrs) :-
    standardize_instrs(Instrs0, Uinstrs1),
    (
        MaybeFallThrough = yes(Label),
        Goto = goto(code_label(Label)),
        Uinstrs = Uinstrs1 ++ [Goto]
    ;
        MaybeFallThrough = no,
        Uinstrs = Uinstrs1
    ).

    % Compute the standard form of a sequence of instructions.
    %
:- pred standardize_instrs(list(instruction)::in, list(instr)::out) is det.

standardize_instrs([], []).
standardize_instrs([llds_instr(Instr, _) | Instrs], StdInstrs) :-
    standardize_instrs(Instrs, StdInstrs1),
    standardize_instr(Instr, StdInstr),
    ( StdInstr = comment(_) ->
        StdInstrs = StdInstrs1
    ;
        StdInstrs = [StdInstr | StdInstrs1]
    ).

    % Compute the standard form of an instruction.
    %
:- pred standardize_instr(instr::in, instr::out) is det.

standardize_instr(Instr0, Instr) :-
    (
        Instr0 = assign(Lval0, Rval0),
        standardize_lval(Lval0, Lval),
        standardize_rval(Rval0, Rval),
        Instr = assign(Lval, Rval)
    ;
        Instr0 = keep_assign(Lval0, Rval0),
        standardize_lval(Lval0, Lval),
        standardize_rval(Rval0, Rval),
        Instr = keep_assign(Lval, Rval)
    ;
        Instr0 = if_val(Rval0, CodeAddr),
        standardize_rval(Rval0, Rval),
        Instr = if_val(Rval, CodeAddr)
    ;
        Instr0 = save_maxfr(Lval0),
        standardize_lval(Lval0, Lval),
        Instr = save_maxfr(Lval)
    ;
        Instr0 = restore_maxfr(Lval0),
        standardize_lval(Lval0, Lval),
        Instr = restore_maxfr(Lval)
    ;
        Instr0 = incr_hp(Lval0, MaybeTag, MaybeOffset, Rval0, Msg,
            MayUseAtomic, MaybeRegionRval0, MaybeReuse0),
        standardize_lval(Lval0, Lval),
        standardize_rval(Rval0, Rval),
        (
            MaybeRegionRval0 = yes(RegionRval0),
            standardize_rval(RegionRval0, RegionRval),
            MaybeRegionRval = yes(RegionRval)
        ;
            MaybeRegionRval0 = no,
            MaybeRegionRval = MaybeRegionRval0
        ),
        (
            MaybeReuse0 = llds_reuse(ReuseRval0, MaybeFlagLval0),
            standardize_rval(ReuseRval0, ReuseRval),
            (
                MaybeFlagLval0 = yes(FlagLval0),
                standardize_lval(FlagLval0, FlagLval),
                MaybeFlagLval = yes(FlagLval)
            ;
                MaybeFlagLval0 = no,
                MaybeFlagLval = no
            ),
            MaybeReuse = llds_reuse(ReuseRval, MaybeFlagLval)
        ;
            MaybeReuse0 = no_llds_reuse,
            MaybeReuse = no_llds_reuse
        ),
        Instr = incr_hp(Lval, MaybeTag, MaybeOffset, Rval, Msg,
            MayUseAtomic, MaybeRegionRval, MaybeReuse)
    ;
        Instr0 = mark_hp(Lval0),
        standardize_lval(Lval0, Lval),
        Instr = mark_hp(Lval)
    ;
        Instr0 = restore_hp(Rval0),
        standardize_rval(Rval0, Rval),
        Instr = restore_hp(Rval)
    ;
        Instr0 = region_fill_frame(FillOp, EmbeddedStackFrame, IdRval0,
            NumLval0, AddrLval0),
        standardize_rval(IdRval0, IdRval),
        standardize_lval(NumLval0, NumLval),
        standardize_lval(AddrLval0, AddrLval),
        Instr = region_fill_frame(FillOp, EmbeddedStackFrame, IdRval,
            NumLval, AddrLval)
    ;
        Instr0 = region_set_fixed_slot(SetOp, EmbeddedStackFrame, ValueRval0),
        standardize_rval(ValueRval0, ValueRval),
        Instr = region_set_fixed_slot(SetOp, EmbeddedStackFrame, ValueRval)
    ;
        Instr0 = free_heap(Rval0),
        standardize_rval(Rval0, Rval),
        Instr = free_heap(Rval)
    ;
        Instr0 = store_ticket(Lval0),
        standardize_lval(Lval0, Lval),
        Instr = store_ticket(Lval)
    ;
        Instr0 = reset_ticket(Rval0, Reason),
        standardize_rval(Rval0, Rval),
        Instr = reset_ticket(Rval, Reason)
    ;
        Instr0 = mark_ticket_stack(Lval0),
        standardize_lval(Lval0, Lval),
        Instr = mark_ticket_stack(Lval)
    ;
        Instr0 = prune_tickets_to(Rval0),
        standardize_rval(Rval0, Rval),
        Instr = prune_tickets_to(Rval)
    ;
        Instr0 = init_sync_term(Lval0, N),
        standardize_lval(Lval0, Lval),
        Instr = init_sync_term(Lval, N)
    ;
        Instr0 = join_and_continue(Lval0, Label),
        standardize_lval(Lval0, Lval),
        Instr = join_and_continue(Lval, Label)
    ;
        ( Instr0 = comment(_)
        ; Instr0 = livevals(_)
        ; Instr0 = block(_, _, _)
        ; Instr0 = llcall(_, _, _, _, _, _)
        ; Instr0 = mkframe(_, _)
        ; Instr0 = label(_)
        ; Instr0 = goto(_)
        ; Instr0 = computed_goto(_, _)
        ; Instr0 = arbitrary_c_code(_, _, _)
        ; Instr0 = push_region_frame(_, _)
        ; Instr0 = use_and_maybe_pop_region_frame(_, _)
        ; Instr0 = discard_ticket
        ; Instr0 = prune_ticket
        ; Instr0 = incr_sp(_, _, _)
        ; Instr0 = decr_sp(_)
        ; Instr0 = decr_sp_and_return(_)
        ; Instr0 = fork_new_child(_, _)
        ; Instr0 = foreign_proc_code(_, _, _, _, _, _, _, _, _)
        ),
        Instr = Instr0
    ).

    % Compute the standard form of an lval.
    %
:- pred standardize_lval(lval::in, lval::out) is det.

standardize_lval(Lval0, Lval) :-
    (
        ( Lval0 = reg(_, _)
        ; Lval0 = succip
        ; Lval0 = maxfr
        ; Lval0 = curfr
        ; Lval0 = hp
        ; Lval0 = sp
        ; Lval0 = parent_sp
        ; Lval0 = temp(_, _)
        ; Lval0 = stackvar(_)
        ; Lval0 = parent_stackvar(_)
        ; Lval0 = framevar(_)
        ; Lval0 = succip_slot(_)
        ; Lval0 = redoip_slot(_)
        ; Lval0 = succfr_slot(_)
        ; Lval0 = redofr_slot(_)
        ; Lval0 = prevfr_slot(_)
        ; Lval0 = mem_ref(_)
        ; Lval0 = global_var_ref(_)
        ),
        Lval = Lval0
    ;
        Lval0 = field(_, Addr, FieldNum),
        Lval = field(no, Addr, FieldNum)
    ;
        Lval0 = lvar(_),
        unexpected(this_file, "lvar in standardize_lval")
    ).

    % Compute the standard form of an rval.
    %
:- pred standardize_rval(rval::in, rval::out) is det.

standardize_rval(Rval0, Rval) :-
    (
        Rval0 = lval(Lval0),
        standardize_lval(Lval0, Lval),
        Rval = lval(Lval)
    ;
        ( Rval0 = mkword(_, _)
        ; Rval0 = const(_)
        ; Rval0 = mem_addr(_)
        ),
        Rval = Rval0
    ;
        Rval0 = unop(Unop, Rval0L),
        standardize_rval(Rval0L, RvalL),
        Rval = unop(Unop, RvalL)
    ;
        Rval0 = binop(Binop, Rval0L, Rval0R),
        standardize_rval(Rval0L, RvalL),
        standardize_rval(Rval0R, RvalR),
        Rval = binop(Binop, RvalL, RvalR)
    ;
        Rval0 = var(_),
        unexpected(this_file, "var in standardize_rval")
    ).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

    % This predicate computes the most specific code sequence that
    % generalizes both input sequences.
    %
    % If a block can fall through, we add a goto to the following label
    % at the end. This way, it will match with other blocks that have
    % identical (standardized) content except for an explicit goto to our
    % fallthrough label.
    %
:- pred standardize_block(list(instruction)::in, maybe(label)::in,
    list(instruction)::out) is det.

standardize_block(Instrs, MaybeFallThrough, StdInstrs) :-
    (
        MaybeFallThrough = yes(Label),
        (
            list.last(Instrs, LastInstr),
            LastInstr = llds_instr(goto(code_label(Label)), _)
        ->
            StdInstrs = Instrs
        ;
            Goto = llds_instr(goto(code_label(Label)), ""),
            StdInstrs = Instrs ++ [Goto]
        )
    ;
        MaybeFallThrough = no,
        StdInstrs = Instrs
    ).

:- pred most_specific_block(list(instruction)::in, maybe(label)::in,
    list(instruction)::in, maybe(label)::in,
    list(instruction)::out, maybe(label)::out) is semidet.

most_specific_block(Instrs1, MaybeFallThrough1,
        Instrs2, MaybeFallThrough2, Instrs, MaybeFallThrough) :-
    standardize_block(Instrs1, MaybeFallThrough1, StdInstrs1),
    standardize_block(Instrs2, MaybeFallThrough2, StdInstrs2),
    most_specific_instrs(StdInstrs1, StdInstrs2, Instrs),
    % A basic block cannot be empty after standardization, since
    % standardization adds a goto to basic blocks that previously
    % had no executable instructions. While most_specific_instrs
    % can delete comments from its input instruction sequences,
    % it cannot delete executable instructions.
    list.last_det(Instrs, LastInstr),
    ( LastInstr = llds_instr(goto(code_label(Label)), _) ->
        MaybeFallThrough = yes(Label)
    ;
        MaybeFallThrough = no
    ).

:- pred most_specific_instrs(list(instruction)::in, list(instruction)::in,
    list(instruction)::out) is semidet.

most_specific_instrs(InstrsA, InstrsB, Instrs) :-
    (
        InstrsA = [InstrA | TailA],
        InstrsB = [InstrB | TailB]
    ->
        InstrA = llds_instr(UinstrA, CommentA),
        InstrB = llds_instr(UinstrB, CommentB),
        (
            most_specific_instr(UinstrA, UinstrB, yes(Uinstr))
        ->
            ( CommentA = CommentB ->
                Comment = CommentA
            ;
                Comment = "unified intruction"
            ),
            Instr = llds_instr(Uinstr, Comment),
            most_specific_instrs(TailA, TailB, Tail),
            Instrs = [Instr | Tail]
        ;
            UinstrA = comment(_)
        ->
            most_specific_instrs(TailA, InstrsB, Instrs)
        ;
            UinstrB = comment(_)
        ->
            most_specific_instrs(InstrsA, TailB, Instrs)
        ;
            fail
        )
    ;
        InstrsA = [],
        InstrsB = []
    ->
        Instrs = []
    ;
        InstrsA = [InstrA | TailA],
        InstrA = llds_instr(comment(_), _)
    ->
        most_specific_instrs(TailA, InstrsB, Instrs)
    ;
        InstrsB = [InstrB | TailB],
        InstrB = llds_instr(comment(_), _)
    ->
        most_specific_instrs(InstrsA, TailB, Instrs)
    ;
        fail
    ).

    % This predicate computes the most specific instruction that
    % generalizes both input instructions.
    %
:- pred most_specific_instr(instr::in, instr::in, maybe(instr)::out) is det.

most_specific_instr(InstrA, InstrB, MaybeInstr) :-
    (
        InstrA = assign(LvalA, RvalA),
        (
            InstrB = assign(LvalB, RvalB),
            most_specific_lval(LvalA, LvalB, Lval),
            most_specific_rval(RvalA, RvalB, Rval)
        ->
            MaybeInstr = yes(assign(Lval, Rval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = keep_assign(LvalA, RvalA),
        (
            InstrB = keep_assign(LvalB, RvalB),
            most_specific_lval(LvalA, LvalB, Lval),
            most_specific_rval(RvalA, RvalB, Rval)
        ->
            MaybeInstr = yes(keep_assign(Lval, Rval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = if_val(RvalA, CodeAddrA),
        (
            InstrB = if_val(RvalB, CodeAddrB),
            most_specific_rval(RvalA, RvalB, Rval),
            CodeAddrA = CodeAddrB
        ->
            MaybeInstr = yes(if_val(Rval, CodeAddrA))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = incr_hp(LvalA, MaybeTag, MaybeOffset, RvalA, Msg,
            MayUseAtomic, MaybeRegionRvalA, MaybeReuseA),
        (
            InstrB = incr_hp(LvalB, MaybeTag, MaybeOffset, RvalB, Msg,
                MayUseAtomic, MaybeRegionRvalB, MaybeReuseB),
            most_specific_lval(LvalA, LvalB, Lval),
            most_specific_rval(RvalA, RvalB, Rval),
            (
                MaybeRegionRvalA = yes(RegionRvalA),
                MaybeRegionRvalB = yes(RegionRvalB),
                most_specific_rval(RegionRvalA, RegionRvalB, RegionRval),
                MaybeRegionRval = yes(RegionRval)
            ;
                MaybeRegionRvalA = no,
                MaybeRegionRvalB = no,
                MaybeRegionRval = no
            ),
            (
                MaybeReuseA = llds_reuse(ReuseRvalA, MaybeFlagLvalA),
                MaybeReuseB = llds_reuse(ReuseRvalB, MaybeFlagLvalB),
                most_specific_rval(ReuseRvalA, ReuseRvalB, ReuseRval),
                (
                    MaybeFlagLvalA = yes(FlagLvalA),
                    MaybeFlagLvalB = yes(FlagLvalB),
                    most_specific_lval(FlagLvalA, FlagLvalB, FlagLval),
                    MaybeFlagLval = yes(FlagLval)
                ;
                    MaybeFlagLvalA = no,
                    MaybeFlagLvalB = no,
                    MaybeFlagLval = no
                ),
                MaybeReuse = llds_reuse(ReuseRval, MaybeFlagLval)
            ;
                MaybeReuseA = no_llds_reuse,
                MaybeReuseB = no_llds_reuse,
                MaybeReuse = no_llds_reuse
            )
        ->
            MaybeInstr = yes(incr_hp(Lval, MaybeTag, MaybeOffset, Rval,
                Msg, MayUseAtomic, MaybeRegionRval, MaybeReuse))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = mark_hp(LvalA),
        (
            InstrB = mark_hp(LvalB),
            most_specific_lval(LvalA, LvalB, Lval)
        ->
            MaybeInstr = yes(mark_hp(Lval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = restore_hp(RvalA),
        (
            InstrB = restore_hp(RvalB),
            most_specific_rval(RvalA, RvalB, Rval)
        ->
            MaybeInstr = yes(restore_hp(Rval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = free_heap(RvalA),
        (
            InstrB = free_heap(RvalB),
            most_specific_rval(RvalA, RvalB, Rval)
        ->
            MaybeInstr = yes(free_heap(Rval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = push_region_frame(StackId, EmbeddedStackFrame),
        (
            InstrB = push_region_frame(StackId, EmbeddedStackFrame)
        ->
            MaybeInstr = yes(push_region_frame(StackId, EmbeddedStackFrame))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = region_fill_frame(FillOp, EmbeddedStackFrame,
            IdRvalA, NumLvalA, AddrLvalA),
        (
            InstrB = region_fill_frame(FillOp, EmbeddedStackFrame,
                IdRvalB, NumLvalB, AddrLvalB),
            most_specific_rval(IdRvalA, IdRvalB, IdRval),
            most_specific_lval(NumLvalA, NumLvalB, NumLval),
            most_specific_lval(AddrLvalA, AddrLvalB, AddrLval)
        ->
            MaybeInstr = yes(region_fill_frame(FillOp, EmbeddedStackFrame,
                IdRval, NumLval, AddrLval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = region_set_fixed_slot(SetOp, EmbeddedStackFrame,
            ValueRvalA),
        (
            InstrB = region_set_fixed_slot(SetOp, EmbeddedStackFrame,
                ValueRvalB),
            most_specific_rval(ValueRvalA, ValueRvalB, ValueRval)
        ->
            MaybeInstr = yes(region_set_fixed_slot(SetOp, EmbeddedStackFrame,
                ValueRval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = use_and_maybe_pop_region_frame(UseOp, EmbeddedStackFrame),
        (
            InstrB = use_and_maybe_pop_region_frame(UseOp, EmbeddedStackFrame)
        ->
            MaybeInstr = yes(use_and_maybe_pop_region_frame(UseOp,
                EmbeddedStackFrame))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = store_ticket(LvalA),
        (
            InstrB = store_ticket(LvalB),
            most_specific_lval(LvalA, LvalB, Lval)
        ->
            MaybeInstr = yes(store_ticket(Lval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = reset_ticket(RvalA, Reason),
        (
            InstrB = reset_ticket(RvalB, Reason),
            most_specific_rval(RvalA, RvalB, Rval)
        ->
            MaybeInstr = yes(reset_ticket(Rval, Reason))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = mark_ticket_stack(LvalA),
        (
            InstrB = mark_ticket_stack(LvalB),
            most_specific_lval(LvalA, LvalB, Lval)
        ->
            MaybeInstr = yes(mark_ticket_stack(Lval))
        ;
            MaybeInstr = no
        )
    ;
        InstrA = prune_tickets_to(RvalA),
        (
            InstrB = prune_tickets_to(RvalB),
            most_specific_rval(RvalA, RvalB, Rval)
        ->
            MaybeInstr = yes(prune_tickets_to(Rval))
        ;
            MaybeInstr = no
        )
    ;
        ( InstrA = livevals(_)
        ; InstrA = block(_, _, _)
        ; InstrA = llcall(_, _, _, _, _, _)
        ; InstrA = mkframe(_, _)
        ; InstrA = label(_)
        ; InstrA = goto(_)
        ; InstrA = computed_goto(_, _)
        ; InstrA = arbitrary_c_code(_, _, _)
        ; InstrA = save_maxfr(_)
        ; InstrA = restore_maxfr(_)
        ; InstrA = discard_ticket
        ; InstrA = prune_ticket
        ; InstrA = incr_sp(_, _, _)
        ; InstrA = decr_sp(_)
        ; InstrA = decr_sp_and_return(_)
        ; InstrA = foreign_proc_code(_, _, _, _, _, _, _, _, _)
        ; InstrA = fork_new_child(_, _)
        ; InstrA = init_sync_term(_, _)
        ; InstrA = join_and_continue(_, _)
        ),
        ( InstrA = InstrB ->
            MaybeInstr = yes(InstrA)
        ;
            MaybeInstr = no
        )
    ;
        InstrA = comment(_),
        MaybeInstr = no
    ).

    % This predicate computes the most specific lval that
    % generalizes both input lvals.
    %
:- pred most_specific_lval(lval::in, lval::in, lval::out) is semidet.

most_specific_lval(LvalA, LvalB, Lval) :-
    (
        ( LvalA = reg(_, _)
        ; LvalA = succip
        ; LvalA = maxfr
        ; LvalA = curfr
        ; LvalA = hp
        ; LvalA = sp
        ; LvalA = parent_sp
        ; LvalA = temp(_, _)
        ; LvalA = stackvar(_)
        ; LvalA = parent_stackvar(_)
        ; LvalA = framevar(_)
        ; LvalA = succip_slot(_)
        ; LvalA = redoip_slot(_)
        ; LvalA = redofr_slot(_)
        ; LvalA = succfr_slot(_)
        ; LvalA = prevfr_slot(_)
        ; LvalA = mem_ref(_)
        ),
        LvalA = LvalB,
        Lval = LvalA
    ;
        LvalA = field(MaybeTagA, Addr, FieldNum),
        LvalB = field(MaybeTagB, Addr, FieldNum),
        ( MaybeTagA = MaybeTagB ->
            MaybeTag = MaybeTagA
        ;
            MaybeTag = no
        ),
        Lval = field(MaybeTag, Addr, FieldNum)
    ;
        LvalA = lvar(_),
        unexpected(this_file, "lvar in most_specific_lval")
    ).

    % This predicate computes the most specific rval that
    % generalizes both input rvals.
    %
:- pred most_specific_rval(rval::in, rval::in, rval::out) is semidet.

most_specific_rval(RvalA, RvalB, Rval) :-
    (
        RvalA = lval(LvalA),
        RvalB = lval(LvalB),
        most_specific_lval(LvalA, LvalB, Lval),
        Rval = lval(Lval)
    ;
        RvalA = var(_),
        unexpected(this_file, "var in most_specific_rval")
    ;
        ( RvalA = mkword(_, _)
        ; RvalA = const(_)
        ; RvalA = mem_addr(_)
        ),
        RvalB = RvalA,
        Rval = RvalA
    ;
        RvalA = unop(Unop, RvalAL),
        RvalB = unop(Unop, RvalBL),
        most_specific_rval(RvalAL, RvalBL, RvalL),
        Rval = unop(Unop, RvalL)
    ;
        RvalA = binop(Binnop, RvalAL, RvalAR),
        RvalB = binop(Binnop, RvalBL, RvalBR),
        most_specific_rval(RvalAL, RvalBL, RvalL),
        most_specific_rval(RvalAR, RvalBR, RvalR),
        Rval = binop(Binnop, RvalL, RvalR)
    ).

%-----------------------------------------------------------------------------%

:- func this_file = string.

this_file = "dupelim.m".

%-----------------------------------------------------------------------------%
:- end_module dupelim.
%-----------------------------------------------------------------------------%
