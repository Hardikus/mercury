%---------------------------------------------------------------------------%
% Copyright (C) 1994-1998 The University of Melbourne.
% This file may only be copied under the terms of the GNU Library General
% Public License - see the file COPYING.LIB in the Mercury distribution.
%---------------------------------------------------------------------------%

% File: mercury_builtin.m.
% Main author: fjh.
% Stability: low.

% This file is automatically imported into every module.
% It is intended for things that are part of the language,
% but which are implemented just as normal user-level code
% rather than with special coding in the compiler.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- module mercury_builtin.
:- interface.

%-----------------------------------------------------------------------------%

% TYPES.

% The types `character', `int', `float', and `string',
% and the types `pred', `pred(T)', `pred(T1, T2)', `pred(T1, T2, T3)', ...
% and `func(T1) = T2', `func(T1, T2) = T3', `func(T1, T2, T3) = T4', ...
% are builtin and are implemented using special code in the
% type-checker.  (XXX TODO: report an error for attempts to redefine
% these types.)

% The type c_pointer can be used by predicates which use the C interface.
:- type c_pointer.

%-----------------------------------------------------------------------------%

% INSTS.

% The standard insts `free', `ground', and `bound(...)' are builtin
% and are implemented using special code in the parser and mode-checker.

% So are the standard unique insts `unique', `unique(...)',
% `mostly_unique', `mostly_unique(...)', and `clobbered'.
% The name `dead' is allowed as a synonym for `clobbered'.
% Similarly `mostly_dead' is a synonym for `mostly_clobbered'.

:- inst dead = clobbered.
:- inst mostly_dead = mostly_clobbered.

% The not yet properly supported `any' inst used for the
% constraint solver interface is also builtin.

% Higher-order predicate insts `pred(<modes>) is <detism>'
% and higher-order functions insts `func(<modes>) = <mode> is det'
% are also builtin.

%-----------------------------------------------------------------------------%

% MODES.

% The standard modes.

:- mode unused :: (free -> free).
:- mode output :: (free -> ground).
:- mode input :: (ground -> ground).

:- mode in :: (ground -> ground).
:- mode out :: (free -> ground).

:- mode in(Inst) :: (Inst -> Inst).
:- mode out(Inst) :: (free -> Inst).
:- mode di(Inst) :: (Inst -> clobbered).
:- mode mdi(Inst) :: (Inst -> mostly_clobbered).

% Unique modes.  These are still not fully implemented.

% unique output
:- mode uo :: free -> unique.

% unique input
:- mode ui :: unique -> unique.

% destructive input
:- mode di :: unique -> clobbered.

% "Mostly" unique modes (unique except that that may be referenced
% again on backtracking).

% mostly unique output
:- mode muo :: free -> mostly_unique.

% mostly unique input
:- mode mui :: mostly_unique -> mostly_unique.

% mostly destructive input
:- mode mdi :: mostly_unique -> mostly_clobbered.

% Higher-order predicate modes are builtin.

%-----------------------------------------------------------------------------%

% PREDICATES.

% copy/2 makes a deep copy of a data structure.  The resulting copy is a
% `unique' value, so you can use destructive update on it.

:- pred copy(T, T).
:- mode copy(ui, uo) is det.
:- mode copy(in, uo) is det.

% unsafe_promise_unique/2 is used to promise the compiler that you have a
% `unique' copy of a data structure, so that you can use destructive update.
% It is used to work around limitations in the current support for unique
% modes.  `unsafe_promise_unique(X, Y)' is the same as `Y = X' except that
% the compiler will assume that `Y' is unique.

:- pred unsafe_promise_unique(T, T).
:- mode unsafe_promise_unique(in, uo) is det.

% We define !/0 (and !/2 for dcgs) to be equivalent to `true'.  This is for
% backwards compatibility with Prolog systems.  But of course it only works
% if all your cuts are green cuts.

:- pred ! is det.

:- pred !(T, T).
:- mode !(di, uo) is det.
:- mode !(in, out) is det.

% In addition, the following predicate-like constructs are builtin:
%
%	:- pred (T = T).
%	:- pred (T \= T).
%	:- pred (pred , pred).
%	:- pred (pred ; pred).
%	:- pred (\+ pred).
%	:- pred (not pred).
%	:- pred (pred -> pred).
%	:- pred (if pred then pred).
%	:- pred (if pred then pred else pred).
%	:- pred (pred => pred).
%	:- pred (pred <= pred).
%	:- pred (pred <=> pred).
%
%	(pred -> pred ; pred).
%	some Vars pred
%	all Vars pred
%	call/N

%-----------------------------------------------------------------------------%

	% unify(X, Y) is true iff X = Y.
:- pred unify(T::in, T::in) is semidet.

:- type comparison_result ---> (=) ; (<) ; (>).

	% compare(Res, X, Y) binds Res to =, <, or >
	% depending on wheither X is =, <, or > Y in the
	% standard ordering.
:- pred compare(comparison_result, T, T).
:- mode compare(uo, ui, ui) is det.
:- mode compare(uo, ui, in) is det.
:- mode compare(uo, in, ui) is det.
:- mode compare(uo, in, in) is det.

%-----------------------------------------------------------------------------%

:- implementation.

% The things beyond this point are implementation details; they do
% not get included in the Mercury library library reference manual.

%-----------------------------------------------------------------------------%

:- interface.

	% unsafe_type_cast/2 is used internally by the compiler. Bad things
	% will happen if this is used in programs. This is generated inline
	% by the compiler.

:- pred unsafe_type_cast(T1, T2).
:- mode unsafe_type_cast(in, out) is det.
:- external(unsafe_type_cast/2).

% The following are used by the compiler, to implement polymorphism.
% They should not be used in programs.

	% index(X, N): if X is a discriminated union type, this is
	% true iff the top-level functor of X is the (N-1)th functor in its
	% type.  Otherwise, if X is a builtin type, N = -1, unless X is
	% of type int, in which case N = X.
:- pred index(T::in, int::out) is det.

:- pred builtin_unify_int(int::in, int::in) is semidet.
:- pred builtin_index_int(int::in, int::out) is det.
:- pred builtin_compare_int(comparison_result::uo, int::in, int::in) is det.

:- pred builtin_unify_character(character::in, character::in) is semidet.
:- pred builtin_index_character(character::in, int::out) is det.
:- pred builtin_compare_character(comparison_result::uo, character::in,
	character::in) is det.

:- pred builtin_unify_string(string::in, string::in) is semidet.
:- pred builtin_index_string(string::in, int::out) is det.
:- pred builtin_compare_string(comparison_result::uo, string::in, string::in)
	is det.

:- pred builtin_unify_float(float::in, float::in) is semidet.
:- pred builtin_index_float(float::in, int::out) is det.
:- pred builtin_compare_float(comparison_result::uo, float::in, float::in)
	is det.

:- pred builtin_unify_pred((pred)::in, (pred)::in) is semidet.
:- pred builtin_index_pred((pred)::in, int::out) is det.
:- pred builtin_compare_pred(comparison_result::uo, (pred)::in, (pred)::in)
	is det.

% The following two preds are used for index/1 or compare/3 on
% non-canonical types (types for which there is a `where equality is ...'
% declaration).
:- pred builtin_index_non_canonical_type(T::in, int::out) is det.
:- pred builtin_compare_non_canonical_type(comparison_result::uo,
		T::in, T::in) is det.

:- pred unused is det.

	% compare_error is used in the code generated for compare/3 preds
:- pred compare_error is erroneous.

	% The code generated by polymorphism.m always requires
	% the existence of a type_info functor, and requires
	% the existence of a base_type_info functor as well
	% when using --type-info {shared-,}one-or-two-cell.
	%
	% The actual arities of these two function symbols are variable;
	% they depend on the number of type parameters of the type represented
	% by the type_info, and how many predicates we associate with each
	% type.
	%
	% Note that, since these types look to the compiler as though they
	% are candidates to become no_tag types, special code is required in
	% type_util:type_is_no_tag_type/3.

:- type type_info(T) ---> type_info(base_type_info(T) /*, ... */).
:- type base_type_info(T) ---> base_type_info(int /*, ... */).

	% Note that, since these types look to the compiler as though they
	% are candidates to become no_tag types, special code is required in
	% type_util:type_is_no_tag_type/3.

:- type typeclass_info ---> typeclass_info(base_typeclass_info /*, ... */). 
:- type base_typeclass_info ---> typeclass_info(int /*, ... */). 

	% type_info_from_typeclass_info(TypeClassInfo, Index, TypeInfo)  
	% extracts TypeInfo from TypeClassInfo, where TypeInfo is the Indexth
	% type_info in the typeclass_info
	% 
	% Note: Index must be equal to the number of the desired type_info 
	% plus the number of superclasses for this class.
:- pred type_info_from_typeclass_info(typeclass_info, int, type_info(T)).
:- mode type_info_from_typeclass_info(in, in, out) is det.

	% superclass_from_typeclass_info(TypeClassInfo, Index, SuperClass)  
	% extracts SuperClass from TypeClassInfo where TypeInfo is the Indexth
	% superclass of the class.
:- pred superclass_from_typeclass_info(typeclass_info, int, typeclass_info).
:- mode superclass_from_typeclass_info(in, in, out) is det.

	% the builtin < operator on ints, used in the code generated
	% for compare/3 preds
:- pred builtin_int_lt(int, int).
:- mode builtin_int_lt(in, in) is semidet.
:- external(builtin_int_lt/2).

	% the builtin > operator on ints, used in the code generated
	% for compare/3 preds
:- pred builtin_int_gt(int, int).
:- mode builtin_int_gt(in, in) is semidet.
:- external(builtin_int_gt/2).

%-----------------------------------------------------------------------------%

:- implementation.
:- import_module require, string, std_util, int, float, char, string, list.

% Many of the predicates defined in this module are builtin -
% the compiler generates code for them inline.

:- pragma c_code(type_info_from_typeclass_info(TypeClassInfo::in, Index::in,
	TypeInfo::out), will_not_call_mercury,
" 
	TypeInfo = MR_typeclass_info_type_info(TypeClassInfo, Index);
").

:- pragma c_code(superclass_from_typeclass_info(TypeClassInfo0::in, Index::in,
	TypeClassInfo::out), will_not_call_mercury,
" 
	TypeClassInfo = 
		MR_typeclass_info_superclass_info(TypeClassInfo0, Index);
").

%-----------------------------------------------------------------------------%

!.
!(X, X).

%-----------------------------------------------------------------------------%

:- external(unify/2).
:- external(index/2).
:- external(compare/3).

%-----------------------------------------------------------------------------%

builtin_unify_int(X, X).

builtin_index_int(X, X).

builtin_compare_int(R, X, Y) :-
	( X < Y ->
		R = (<)
	; X = Y ->
		R = (=)
	;
		R = (>)
	).

builtin_unify_character(C, C).

builtin_index_character(C, N) :-
	char__to_int(C, N).

builtin_compare_character(R, X, Y) :-
	char__to_int(X, XI),
	char__to_int(Y, YI),
	( XI < YI ->
		R = (<)
	; XI = YI ->
		R = (=)
	;
		R = (>)
	).

builtin_unify_string(S, S).

builtin_index_string(_, -1).

builtin_compare_string(R, S1, S2) :-
	builtin_strcmp(Res, S1, S2),
	( Res < 0 ->
		R = (<)
	; Res = 0 ->
		R = (=)
	;
		R = (>)
	).

builtin_unify_float(F, F).

builtin_index_float(_, -1).

builtin_compare_float(R, F1, F2) :-
	( F1 < F2 ->
		R = (<)
	; F1 > F2 ->
		R = (>)
	;
		R = (=)
	).

:- pred builtin_strcmp(int, string, string).
:- mode builtin_strcmp(out, in, in) is det.

:- pragma c_code(builtin_strcmp(Res::out, S1::in, S2::in),
	will_not_call_mercury,
	"Res = strcmp(S1, S2);").

builtin_index_non_canonical_type(_, -1).

builtin_compare_non_canonical_type(Res, X, _Y) :-
	% suppress determinism warning
	( semidet_succeed ->
		string__append_list([
			"call to compare/3 for non-canonical type `",
			type_name(type_of(X)),
			"'"],
			Message),
		error(Message)
	;
		% the following is never executed
		Res = (<)
	).

:- external(builtin_unify_pred/2).
:- external(builtin_index_pred/2).
:- external(builtin_compare_pred/3).

unused :-
	( semidet_succeed ->
		error("attempted use of dead predicate")
	;
		% the following is never executed 
		true
	).

:- pragma c_header_code("#include ""mercury_type_info.h""").

:- pragma c_code("


#ifdef  USE_TYPE_LAYOUT

	/* base_type_layout definitions */ 

	/* base_type_layout for `int' */

const struct mercury_data___base_type_layout_int_0_struct {
	TYPE_LAYOUT_FIELDS
} mercury_data___base_type_layout_int_0 = {
	make_typelayout_for_all_tags(TYPELAYOUT_CONST_TAG, 
		mkbody(TYPELAYOUT_INT_VALUE))
};

	/* base_type_layout for `character' */

const struct mercury_data___base_type_layout_character_0_struct {
	TYPE_LAYOUT_FIELDS
} mercury_data___base_type_layout_character_0 = {
	make_typelayout_for_all_tags(TYPELAYOUT_CONST_TAG, 
		mkbody(TYPELAYOUT_CHARACTER_VALUE))
};

	/* base_type_layout for `string' */

const struct mercury_data___base_type_layout_string_0_struct {
	TYPE_LAYOUT_FIELDS
} mercury_data___base_type_layout_string_0 = {
	make_typelayout_for_all_tags(TYPELAYOUT_CONST_TAG, 
		mkbody(TYPELAYOUT_STRING_VALUE))
};

	/* base_type_layout for `float' */

const struct mercury_data___base_type_layout_float_0_struct {
	TYPE_LAYOUT_FIELDS
} mercury_data___base_type_layout_float_0 = {
	make_typelayout_for_all_tags(TYPELAYOUT_CONST_TAG, 
		mkbody(TYPELAYOUT_FLOAT_VALUE))
};

	/* base_type_layout for `void' */

const struct mercury_data___base_type_layout_void_0_struct {
	TYPE_LAYOUT_FIELDS
} mercury_data___base_type_layout_void_0 = {
	make_typelayout_for_all_tags(TYPELAYOUT_CONST_TAG, 
		mkbody(TYPELAYOUT_VOID_VALUE))
};

	/* base_type_functors definitions */

	/* base_type_functors for `int' */

const struct mercury_data___base_type_functors_int_0_struct {
	Integer f1;
} mercury_data___base_type_functors_int_0 = {
	MR_TYPEFUNCTORS_SPECIAL
};

	/* base_type_functors for `character' */

const struct mercury_data___base_type_functors_character_0_struct {
	Integer f1;
} mercury_data___base_type_functors_character_0 = {
	MR_TYPEFUNCTORS_SPECIAL
};

	/* base_type_functors for `string' */

const struct mercury_data___base_type_functors_string_0_struct {
	Integer f1;
} mercury_data___base_type_functors_string_0 = {
	MR_TYPEFUNCTORS_SPECIAL
};

	/* base_type_functors for `float' */

const struct mercury_data___base_type_functors_float_0_struct {
	Integer f1;
} mercury_data___base_type_functors_float_0 = {
	MR_TYPEFUNCTORS_SPECIAL
};

	/* base_type_functors for `void' */

const struct mercury_data___base_type_functors_void_0_struct {
	Integer f1;
} mercury_data___base_type_functors_void_0 = {
	MR_TYPEFUNCTORS_SPECIAL
};

#endif /* USE_TYPE_LAYOUT */

	/* base_type_infos definitions */

	/* base_type_info for `int' */

Declare_entry(mercury__builtin_unify_int_2_0);
Declare_entry(mercury__builtin_index_int_2_0);
Declare_entry(mercury__builtin_compare_int_3_0);
MR_STATIC_CODE_CONST struct mercury_data___base_type_info_int_0_struct {
	Integer f1;
	Code *f2;
	Code *f3;
	Code *f4;
#ifdef USE_TYPE_LAYOUT
	const Word *f5;
	const Word *f6;
	const Word *f7;
	const Word *f8;
#endif
} mercury_data___base_type_info_int_0 = {
	((Integer) 0),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_unify_int_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_index_int_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_compare_int_3_0)),
#ifdef  USE_TYPE_LAYOUT
	(const Word *) & mercury_data___base_type_layout_int_0,
	(const Word *) & mercury_data___base_type_functors_int_0,
	(const Word *) string_const(""mercury_builtin"", 15),
	(const Word *) string_const(""int"", 3)
#endif
};

	/* base_type_info for `character' */

Declare_entry(mercury__builtin_unify_character_2_0);
Declare_entry(mercury__builtin_index_character_2_0);
Declare_entry(mercury__builtin_compare_character_3_0);
MR_STATIC_CODE_CONST struct 
mercury_data___base_type_info_character_0_struct {
	Integer f1;
	Code *f2;
	Code *f3;
	Code *f4;
#ifdef USE_TYPE_LAYOUT
	const Word *f5;
	const Word *f6;
	const Word *f7;
	const Word *f8;
#endif
} mercury_data___base_type_info_character_0 = {
	((Integer) 0),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_unify_character_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_index_character_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_compare_character_3_0)),
#ifdef  USE_TYPE_LAYOUT
	(const Word *) & mercury_data___base_type_layout_character_0,
	(const Word *) & mercury_data___base_type_functors_character_0,
	(const Word *) string_const(""mercury_builtin"", 15),
	(const Word *) string_const(""character"", 9)
#endif
};

	/* base_type_info for `string' */

Declare_entry(mercury__builtin_unify_string_2_0);
Declare_entry(mercury__builtin_index_string_2_0);
Declare_entry(mercury__builtin_compare_string_3_0);
MR_STATIC_CODE_CONST struct mercury_data___base_type_info_string_0_struct {
	Integer f1;
	Code *f2;
	Code *f3;
	Code *f4;
#ifdef USE_TYPE_LAYOUT
	const Word *f5;
	const Word *f6;
	const Word *f7;
	const Word *f8;
#endif
} mercury_data___base_type_info_string_0 = {
	((Integer) 0),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_unify_string_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_index_string_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_compare_string_3_0)),
#ifdef  USE_TYPE_LAYOUT
	(const Word *) & mercury_data___base_type_layout_string_0,
	(const Word *) & mercury_data___base_type_functors_string_0,
	(const Word *) string_const(""mercury_builtin"", 15),
	(const Word *) string_const(""string"", 6)
#endif
};

	/* base_type_info for `float' */

Declare_entry(mercury__builtin_unify_float_2_0);
Declare_entry(mercury__builtin_index_float_2_0);
Declare_entry(mercury__builtin_compare_float_3_0);
MR_STATIC_CODE_CONST struct mercury_data___base_type_info_float_0_struct {
	Integer f1;
	Code *f2;
	Code *f3;
	Code *f4;
#ifdef USE_TYPE_LAYOUT
	const Word *f5;
	const Word *f6;
	const Word *f7;
	const Word *f8;
#endif
} mercury_data___base_type_info_float_0 = {
	((Integer) 0),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_unify_float_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_index_float_2_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__builtin_compare_float_3_0)),
#ifdef  USE_TYPE_LAYOUT
	(const Word *) & mercury_data___base_type_layout_float_0,
	(const Word *) & mercury_data___base_type_functors_float_0,
	(const Word *) string_const(""mercury_builtin"", 15),
	(const Word *) string_const(""float"", 5)
#endif
};

	/* base_type_info for `void' */

Declare_entry(mercury__unused_0_0);
MR_STATIC_CODE_CONST struct mercury_data___base_type_info_void_0_struct {
	Integer f1;
	Code *f2;
	Code *f3;
	Code *f4;
#ifdef USE_TYPE_LAYOUT
	const Word *f5;
	const Word *f6;
	const Word *f7;
	const Word *f8;
#endif
} mercury_data___base_type_info_void_0 = {
	((Integer) 0),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__unused_0_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__unused_0_0)),
	MR_MAYBE_STATIC_CODE(ENTRY(mercury__unused_0_0)),
#ifdef  USE_TYPE_LAYOUT
	(const Word *) & mercury_data___base_type_layout_void_0,
	(const Word *) & mercury_data___base_type_functors_void_0,
	(const Word *) string_const(""mercury_builtin"", 15),
	(const Word *) string_const(""void"", 4)
#endif
};

BEGIN_MODULE(builtin_types_module)

BEGIN_CODE

END_MODULE

/*
INIT sys_init_builtin_types_module
*/
extern ModuleFunc builtin_types_module;
extern void mercury__mercury_builtin__init(void);
void sys_init_builtin_types_module(void);
void sys_init_builtin_types_module(void) {

	builtin_types_module();

	/* 
	** We had better call this init() because we use the
	** labels for the special preds of int, float, pred, 
	** character and string. If they aren't initialized,
	** we might initialize the base_type_info with
	** garbage
	*/
	mercury__mercury_builtin__init();

	MR_INIT_BUILTIN_BASE_TYPE_INFO(
		mercury_data___base_type_info_int_0, _int_);
	MR_INIT_BUILTIN_BASE_TYPE_INFO(
		mercury_data___base_type_info_float_0, _float_);
	MR_INIT_BUILTIN_BASE_TYPE_INFO(
		mercury_data___base_type_info_character_0, _character_);
	MR_INIT_BUILTIN_BASE_TYPE_INFO(
		mercury_data___base_type_info_string_0, _string_);
	MR_INIT_BASE_TYPE_INFO_WITH_PRED(
		mercury_data___base_type_info_void_0, mercury__unused_0_0);
}

").

	% This is used by the code that the compiler generates for compare/3.
compare_error :-
	error("internal error in compare/3").

%-----------------------------------------------------------------------------%

:- external(unsafe_promise_unique/2).

% XXX This is now a compiler builtin. Once the changes
% have been installed, remove this code.
/* unsafe_promise_unique/2
	:- pred unsafe_promise_unique(T, T).
	:- mode unsafe_promise_unique(in, uo) is det.
*/

/* This doesn't work, due to the lack of support for aliasing.
:- pragma c_code(unsafe_promise_unique(X::in, Y::uo), will_not_call_mercury,
		"Y = X;").
*/

:- pragma c_code("
Define_extern_entry(mercury__unsafe_promise_unique_2_0);
MR_MAKE_STACK_LAYOUT_ENTRY(mercury__unsafe_promise_unique_2_0);

BEGIN_MODULE(unsafe_promise_unique_module)
	init_entry(mercury__unsafe_promise_unique_2_0);
BEGIN_CODE

Define_entry(mercury__unsafe_promise_unique_2_0);
#ifdef COMPACT_ARGS
	r1 = r2;
#else
	r3 = r2;
#endif
	proceed();

END_MODULE

/* Ensure that the initialization code for the above module gets run. */

/*
INIT sys_init_unsafe_promise_unique_module
*/
extern ModuleFunc unsafe_promise_unique_module;
void sys_init_unsafe_promise_unique_module(void);
	/* extra declaration to suppress gcc -Wmissing-decl warning */
void sys_init_unsafe_promise_unique_module(void) {
	unsafe_promise_unique_module();
}

").



%-----------------------------------------------------------------------------%

/* copy/2
	:- pred copy(T, T).
	:- mode copy(ui, uo) is det.
	:- mode copy(in, uo) is det.
*/

/*************
Using `pragma c_code' doesn't work, due to the lack of support for
aliasing, and in particular the lack of support for `ui' modes.
:- pragma c_code(copy(Value::ui, Copy::uo), "
	save_transient_registers();
	Copy = deep_copy(Value, TypeInfo_for_T, NULL, NULL);
	restore_transient_registers();
").
:- pragma c_code(copy(Value::in, Copy::uo), "
	save_transient_registers();
	Copy = deep_copy(Value, TypeInfo_for_T, NULL, NULL);
	restore_transient_registers();
").
*************/

:- external(copy/2).

:- pragma c_header_code("#include ""mercury_deep_copy.h""").

:- pragma c_code("
Define_extern_entry(mercury__copy_2_0);
Define_extern_entry(mercury__copy_2_1);
MR_MAKE_STACK_LAYOUT_ENTRY(mercury__copy_2_0);
MR_MAKE_STACK_LAYOUT_ENTRY(mercury__copy_2_1);

BEGIN_MODULE(copy_module)
	init_entry(mercury__copy_2_0);
	init_entry(mercury__copy_2_1);
BEGIN_CODE

#ifdef PROFILE_CALLS
  #define fallthru(target, caller) { tailcall((target), (caller)); }
#else
  #define fallthru(target, caller)
#endif

Define_entry(mercury__copy_2_0);
fallthru(ENTRY(mercury__copy_2_1), ENTRY(mercury__copy_2_0))
Define_entry(mercury__copy_2_1);
{
	Word value, copy, type_info;

	type_info = r1;
	value = r2;

	save_transient_registers();
	copy = deep_copy(value, (Word *) type_info, NULL, NULL);
	restore_transient_registers();

#ifdef	COMPACT_ARGS
	r1 = copy;
#else
	r3 = copy;
#endif

	proceed();
}
END_MODULE

/* Ensure that the initialization code for the above module gets run. */

/*
INIT sys_init_copy_module
*/
extern ModuleFunc copy_module;
void sys_init_copy_module(void);
	/* extra declaration to suppress gcc -Wmissing-decl warning */
void sys_init_copy_module(void) {
	copy_module();
}

").

%-----------------------------------------------------------------------------%

% The type c_pointer can be used by predicates which use the C interface.

:- pragma c_code("

/*
 * c_pointer has a special value reserved for its layout, since it needs to
 * be handled as a special case.
 */

#ifdef  USE_TYPE_LAYOUT

const struct mercury_data_mercury_builtin__base_type_layout_c_pointer_0_struct {
	TYPE_LAYOUT_FIELDS
} mercury_data_mercury_builtin__base_type_layout_c_pointer_0 = {
	make_typelayout_for_all_tags(TYPELAYOUT_CONST_TAG, 
		mkbody(TYPELAYOUT_C_POINTER_VALUE))
};

const struct
mercury_data_mercury_builtin__base_type_functors_c_pointer_0_struct {
	Integer f1;
} mercury_data_mercury_builtin__base_type_functors_c_pointer_0 = {
	MR_TYPEFUNCTORS_SPECIAL
};

#endif

Define_extern_entry(mercury____Unify___mercury_builtin__c_pointer_0_0);
Define_extern_entry(mercury____Index___mercury_builtin__c_pointer_0_0);
Define_extern_entry(mercury____Compare___mercury_builtin__c_pointer_0_0);
MR_MAKE_STACK_LAYOUT_ENTRY(mercury____Unify___mercury_builtin__c_pointer_0_0);
MR_MAKE_STACK_LAYOUT_ENTRY(mercury____Index___mercury_builtin__c_pointer_0_0);
MR_MAKE_STACK_LAYOUT_ENTRY(mercury____Compare___mercury_builtin__c_pointer_0_0);

BEGIN_MODULE(unify_c_pointer_module)
	init_entry(mercury____Unify___mercury_builtin__c_pointer_0_0);
	init_entry(mercury____Index___mercury_builtin__c_pointer_0_0);
	init_entry(mercury____Compare___mercury_builtin__c_pointer_0_0);

BEGIN_CODE
Define_entry(mercury____Unify___mercury_builtin__c_pointer_0_0);
	/*
	** For c_pointer, we assume that equality and comparison
	** can be based on object identity (i.e. using address comparisons).
	** This is correct for types like io__stream, and necessary since
	** the io__state contains a map(io__stream, filename).
	** However, it might not be correct in general...
	*/
	unify_output = (unify_input1 == unify_input2);
	proceed();

Define_entry(mercury____Index___mercury_builtin__c_pointer_0_0);
	index_output = -1;
	proceed();

Define_entry(mercury____Compare___mercury_builtin__c_pointer_0_0);
	compare_output = (compare_input1 == compare_input2 ? COMPARE_EQUAL :
			  compare_input1 < compare_input2 ? COMPARE_LESS :
			  COMPARE_GREATER);
	proceed();

END_MODULE

/* Ensure that the initialization code for the above module gets run. */
/*
INIT sys_init_unify_c_pointer_module
*/
extern ModuleFunc unify_c_pointer_module;
void sys_init_unify_c_pointer_module(void);
	/* duplicate declaration to suppress gcc -Wmissing-decl warning */
void sys_init_unify_c_pointer_module(void) {
	unify_c_pointer_module();
}

").


:- interface.

%
% The following predicates are used in code transformed by the table_gen pass
% of the compiler. The predicates fall into three categories :
% 1) 	Predicates to do lookups or insertions into the tables. This group
%	also contains function to create and initialise tables. There are
% 	currently two types of table used by the tabling system. 1) A subgoal
%	table, this is a table containing all of the subgoal calls that have
%	or are being processed for a given predicate. 2) An answer table, 
%	this is a table of all the answers a subgoal has returned. It is used
%	for duplicate answer elimination in the minimal model tabling 
%	scheme.
%
% 2)	Predicates to test and set the status of the tables. These predicates
%	expect either a subgoal or answer table node depending on their 
%	functionality.
%
% 3) 	Predicates to save answers into the tables. Answers are saved in
% 	an answer block, which is a vector of n elements where n is the number 
%	of output arguments of the predicate it belongs to. For	det and 
%	semidet tabling the answer block is connected directly to subgoal 
%	table nodes. In the case of nondet tabling answer blocks are connected 
%	to answered slots which are strung together to form a list. 
%
% All of the predicates with the impure declaration modify the table
% structures. Because the tables are persistent through backtracking, this
% causes the predicates to become impure. The predicates with the semipure
% directive only examine the trees but do not have any side effects.
% 

	% This type is used as a generic table: it can in fact represent two
	% types, either a subgoal_table or an answer_table. The subgoal_table
	% and answer_table types are differentiated by what they have at the
	% table nodes but not by the actual underling trie structure.
:- type ml_table.

	% This type is used in contexts where a node of a subgoal table is
	% expected.
:- type ml_subgoal_table_node.

	% This type is used in contexts where a node of an answer table is
	% expected.
:- type ml_answer_table_node.

	% This type is used in contexts where an answer slot is expected.
:- type ml_answer_slot.

	% This type is used in contexts where an answer block is expected.
:- type ml_answer_block.



	% This is a dummy predicate: its pred_proc_id, but not its code, 
	% is used. See the comment in compiler/table_gen.m for more 
	% information. 
:- impure pred get_table(ml_table).
:- mode get_table(out) is det.

	% Save important information in nondet table and initialise all of
	% its fields. If called on an already initialised table do nothing.
:- impure pred table_setup(ml_subgoal_table_node, ml_subgoal_table_node).
:- mode table_setup(in, out) is det.



	% Return all of the answer blocks stored in the given table.
:- semipure pred table_return_all_ans(ml_subgoal_table_node, ml_answer_block).
:- mode table_return_all_ans(in, out) is nondet.



	% Returns true if the given nondet table has returned some of its
	% answers.
:- semipure pred table_have_some_ans(ml_subgoal_table_node).
:- mode table_have_some_ans(in) is semidet.

	% Return true if the given nondet table has returned all of its
	% answers. 
:- semipure pred table_have_all_ans(ml_subgoal_table_node).
:- mode table_have_all_ans(in) is semidet.


	% Mark a table as having some answers.
:- impure pred table_mark_have_some_ans(ml_subgoal_table_node).
:- mode table_mark_have_some_ans(in) is det.

	% Make a table as having all of its answers.
:- impure pred table_mark_have_all_ans(ml_subgoal_table_node).
:- mode table_mark_have_all_ans(in) is det.


	% currently being evaluated (working on an answer).
:- semipure pred table_working_on_ans(ml_subgoal_table_node).
:- mode table_working_on_ans(in) is semidet.

	% Return false if the subgoal represented by the given table is
	% currently being evaluated (working on an answer).
:- semipure pred table_not_working_on_ans(ml_subgoal_table_node).
:- mode table_not_working_on_ans(in) is semidet.


	% Mark the subgoal represented by the given table as currently 
	% being evaluated (working on an answer).
:- impure pred table_mark_as_working(ml_subgoal_table_node).
:- mode table_mark_as_working(in) is det.

	% Mark the subgoal represented by the given table as currently 
	% not being evaluated (working on an answer).
:- impure pred table_mark_done_working(ml_subgoal_table_node).
:- mode table_mark_done_working(in) is det.
	


	% Report an error message about the current subgoal looping. 
:- pred table_loopcheck_error(string).
:- mode table_loopcheck_error(in) is erroneous.



%
% The following table_lookup_insert... predicates lookup or insert the second
% argument into the trie pointed to by the first argument. The value returned
% is a pointer to the leaf of the trie reached by the lookup. From the 
% returned leaf another trie may be connected.
% 
	% Lookup or insert an integer in the given table.
:- impure pred table_lookup_insert_int(ml_table, int, ml_table).
:- mode table_lookup_insert_int(in, in, out) is det.

	% Lookup or insert a character in the given trie.
:- impure pred table_lookup_insert_char(ml_table, character, ml_table).
:- mode table_lookup_insert_char(in, in, out) is det.

	% Lookup or insert a string in the given trie.
:- impure pred table_lookup_insert_string(ml_table, string, ml_table).
:- mode table_lookup_insert_string(in, in, out) is det.

	% Lookup or insert a float in the current trie.
:- impure pred table_lookup_insert_float(ml_table, float, ml_table).
:- mode table_lookup_insert_float(in, in, out) is det.

	% Lookup or inert an enumeration type in the given trie.
:- impure pred table_lookup_insert_enum(ml_table, int, T, ml_table).
:- mode table_lookup_insert_enum(in, in, in, out) is det.

	% Lookup or insert a monomorphic user defined type in the given trie.
:- impure pred table_lookup_insert_user(ml_table, T, ml_table).
:- mode table_lookup_insert_user(in, in, out) is det.

	% Lookup or insert a polymorphic user defined type in the given trie.
:- impure pred table_lookup_insert_poly(ml_table, T, ml_table).
:- mode table_lookup_insert_poly(in, in, out) is det.


	% Return true if the subgoal represented by the given table has an
	% answer. NOTE : this is only used for det and semidet procedures.
:- semipure pred table_have_ans(ml_subgoal_table_node).
:- mode table_have_ans(in) is semidet. 


	% Save the fact the the subgoal has succeeded in the given table.
:- impure pred table_mark_as_succeeded(ml_subgoal_table_node).
:- mode table_mark_as_succeeded(in) is det.

	% Save the fact the the subgoal has failed in the given table.
:- impure pred table_mark_as_failed(ml_subgoal_table_node).
:- mode table_mark_as_failed(in) is det.


	% Return true if the subgoal represented by the given table has a
	% true answer. NOTE : this is only used for det and semidet 
	% procedures.
:- semipure pred table_has_succeeded(ml_subgoal_table_node).
:- mode table_has_succeeded(in) is semidet. 

	% Return true if the subgoal represented by the given table has
	% failed. NOTE : this is only used for semidet procedures.
:- semipure pred table_has_failed(ml_subgoal_table_node).
:- mode table_has_failed(in) is semidet.


	% Create an answer block with the given number of slots and add it
	% to the given table.
:- impure pred table_create_ans_block(ml_subgoal_table_node, int, 
		ml_answer_block).
:- mode table_create_ans_block(in, in, out) is det.

	% Create a new slot in the answer list.
:- impure pred table_new_ans_slot(ml_subgoal_table_node, ml_answer_slot).
:- mode table_new_ans_slot(in, out) is det.

	% Save an integer answer in the given answer block at the given 
	% offset.
:- impure pred table_save_int_ans(ml_answer_block, int, int).
:- mode table_save_int_ans(in, in, in) is det.

	% Save a character answer in the given answer block at the given
	% offset.
:- impure pred table_save_char_ans(ml_answer_block, int, character).
:- mode table_save_char_ans(in, in, in) is det.

	% Save a string answer in the given answer block at the given
	% offset.
:- impure pred table_save_string_ans(ml_answer_block, int, string).
:- mode table_save_string_ans(in, in, in) is det.

	% Save a float answer in the given answer block at the given
	% offset.
:- impure pred table_save_float_ans(ml_answer_block, int, float).
:- mode table_save_float_ans(in, in, in) is det.

	% Save any type of answer in the given answer block at the given
	% offset.
:- impure pred table_save_any_ans(ml_answer_block, int, T).
:- mode table_save_any_ans(in, in, in) is det.


	% Restore an integer answer from the given answer block at the 
	% given offset. 
:- semipure pred table_restore_int_ans(ml_answer_block, int, int).
:- mode table_restore_int_ans(in, in, out) is det.

	% Restore a character answer from the given answer block at the     
	% given offset.
:- semipure pred table_restore_char_ans(ml_answer_block, int, character).
:- mode table_restore_char_ans(in, in, out) is det.

	% Restore a string answer from the given answer block at the
	% given offset.
:- semipure pred table_restore_string_ans(ml_answer_block, int, string).
:- mode table_restore_string_ans(in, in, out) is det.

	% Restore a float answer from the given answer block at the
	% given offset.
:- semipure pred table_restore_float_ans(ml_answer_block, int, float).
:- mode table_restore_float_ans(in, in, out) is det.

	% Restore any type of answer from the given answer block at the
	% given offset.
:- semipure pred table_restore_any_ans(ml_answer_block, int, T).
:- mode table_restore_any_ans(in, in, out) is det.


	% Return the table of answers already return to the given nondet
	% table. 
:- impure pred table_get_ans_table(ml_subgoal_table_node, ml_table).
:- mode table_get_ans_table(in, out) is det.

	% Return true if the answer represented by the given answer
	% table has not been returned to its parent nondet table.
:- semipure pred table_has_not_returned(ml_answer_table_node).
:- mode table_has_not_returned(in) is semidet.

	% Make the answer represented by the given answer table as
	% having been return to its parent nondet table.
:- impure pred table_mark_as_returned(ml_answer_table_node).
:- mode table_mark_as_returned(in) is det.

	% Save the state of the current subgoal and fail. When this subgoal 
	% is resumed answers are returned through the second argument.
	% The saved state will be used by table_resume/1 to resume the
	% subgoal.
:- impure pred table_suspend(ml_subgoal_table_node, ml_answer_block).
:- mode table_suspend(in, out) is nondet.

	% Resume all suspended subgoal calls. This predicate will resume each
	% of the suspended subgoals in turn until it reaches a fixed point at 
	% which all suspended subgoals have had all available answers returned
	% to them.
:- impure pred table_resume(ml_subgoal_table_node).
:- mode table_resume(in) is det. 

:- implementation.

:- type ml_table == c_pointer.
:- type ml_subgoal_table_node == c_pointer.
:- type ml_answer_table_node == c_pointer.
:- type ml_answer_slot == c_pointer.
:- type ml_answer_block == c_pointer.

:- pragma c_header_code("
	
	/* Used to mark the status of the table */
#define ML_UNINITIALIZED	0
#define ML_WORKING_ON_ANS	1
#define ML_FAILED		2
	/* The values 3..TYPELAYOUT_MAX_VARINT are reserved for future use */
#define ML_SUCCEEDED		TYPELAYOUT_MAX_VARINT 
	/* This or any greater value indicate that the subgoal has 
	** succeeded. */

").
	
	% This is a dummy procedure that never actually gets called.
	% See the comments in table_gen.m for its purpose.
:- pragma c_code(get_table(_T::out), will_not_call_mercury, "").

:- pragma c_code(table_working_on_ans(T::in), will_not_call_mercury, "
	SUCCESS_INDICATOR = (*((Word*) T) == ML_WORKING_ON_ANS);
").

:- pragma c_code(table_not_working_on_ans(T::in), will_not_call_mercury, "
	SUCCESS_INDICATOR = (*((Word*) T) != ML_WORKING_ON_ANS);
").

:- pragma c_code(table_mark_as_working(T::in), will_not_call_mercury, "
	*((Word*) T) = ML_WORKING_ON_ANS;
").

:- pragma c_code(table_mark_done_working(T::in), will_not_call_mercury, "
	*((Word*) T) = ML_UNINITIALIZED;
").


table_loopcheck_error(Message) :-
	error(Message).


:- pragma c_code(table_lookup_insert_int(T0::in, I::in, T::out), 
		will_not_call_mercury, "
	T = (Word) MR_TABLE_INT((Word**)T0, I);
").

:- pragma c_code(table_lookup_insert_char(T0::in, C::in, T::out), 
		will_not_call_mercury, "
	T = (Word) MR_TABLE_CHAR((Word **) T0, C);
").

:- pragma c_code(table_lookup_insert_string(T0::in, S::in, T::out), 
		will_not_call_mercury, "
	T = (Word) MR_TABLE_STRING((Word **) T0, S);
").

:- pragma c_code(table_lookup_insert_float(T0::in, F::in, T::out), 
		will_not_call_mercury, "
	T = (Word) MR_TABLE_FLOAT((Word **) T0, F);
").

:- pragma c_code(table_lookup_insert_enum(T0::in, R::in, V::in, T::out), 
		will_not_call_mercury, "
	T = (Word) MR_TABLE_ENUM((Word **) T0, R, V);
").

:- pragma c_code(table_lookup_insert_user(T0::in, V::in, T::out), 
		will_not_call_mercury, "
	T = (Word) MR_TABLE_ANY((Word **) T0, TypeInfo_for_T, V);
").

:- pragma c_code(table_lookup_insert_poly(T0::in, V::in, T::out), 
		will_not_call_mercury, "
	Word T1 = (Word) MR_TABLE_TYPE_INFO((Word **) T0, TypeInfo_for_T);
	T = (Word) MR_TABLE_ANY((Word **) T1, TypeInfo_for_T, V);
").

:- pragma c_code(table_have_ans(T::in), will_not_call_mercury, "
	if (*((Word*) T) == ML_FAILED || *((Word*) T) >= ML_SUCCEEDED) {
		SUCCESS_INDICATOR = TRUE;
	} else {
		SUCCESS_INDICATOR = FALSE;
	}
").

:- pragma c_code(table_has_succeeded(T::in), will_not_call_mercury, "
	SUCCESS_INDICATOR = (*((Word*) T) >= ML_SUCCEEDED)
").

:- pragma c_code(table_has_failed(T::in), will_not_call_mercury, "
	SUCCESS_INDICATOR = (*((Word*) T) == ML_FAILED);
").

:- pragma c_code(table_create_ans_block(T0::in, Size::in, T::out) ,"
	MR_TABLE_CREATE_ANSWER_BLOCK(T0, Size);
	T = T0;
").

:- pragma c_code(table_save_int_ans(T::in, Offset::in, I::in), 
		will_not_call_mercury, "
	MR_TABLE_SAVE_ANSWER(Offset, T, I,
		mercury_data___base_type_info_int_0);
").

:- pragma c_code(table_save_char_ans(T::in, Offset::in, C::in), 
		will_not_call_mercury, "
	MR_TABLE_SAVE_ANSWER(Offset, T, C,
		mercury_data___base_type_info_character_0);
").

:- pragma c_code(table_save_string_ans(T::in, Offset::in, S::in), 
		will_not_call_mercury, "
	MR_TABLE_SAVE_ANSWER(Offset, T, (Word) S,
		mercury_data___base_type_info_string_0);
").

:- pragma c_code(table_save_float_ans(T::in, Offset::in, F::in), 
		will_not_call_mercury, "
	MR_TABLE_SAVE_ANSWER(Offset, T, float_to_word(F),
		mercury_data___base_type_info_float_0);
").

:- pragma c_code(table_save_any_ans(T::in, Offset::in, V::in), 
		will_not_call_mercury, "
	MR_TABLE_SAVE_ANSWER(Offset, T, V, TypeInfo_for_T);
").

:- pragma c_code(table_mark_as_succeeded(T::in), will_not_call_mercury, "
	*((Word*) T) = ML_SUCCEEDED;
").

:- pragma c_code(table_mark_as_failed(T::in), will_not_call_mercury, "
	*((Word*) T) = ML_FAILED;
").


:- pragma c_code(table_restore_int_ans(T::in, Offset::in, I::out), 
		will_not_call_mercury, "
	I = (Integer) MR_TABLE_GET_ANSWER(Offset, T);
").

:- pragma c_code(table_restore_char_ans(T::in, Offset::in, C::out), 
		will_not_call_mercury, "
	C = (Char) MR_TABLE_GET_ANSWER(Offset, T);
").

:- pragma c_code(table_restore_string_ans(T::in, Offset::in, S::out), 
		will_not_call_mercury, "
	S = (String) MR_TABLE_GET_ANSWER(Offset, T);
").

:- pragma c_code(table_restore_float_ans(T::in, Offset::in, F::out), 
		will_not_call_mercury, "
	F = word_to_float(MR_TABLE_GET_ANSWER(Offset, T));
").

:- pragma c_code(table_restore_any_ans(T::in, Offset::in, V::out), 
		will_not_call_mercury, "
	V = (Word) MR_TABLE_GET_ANSWER(Offset, T);
").


:- pragma c_header_code("

/*
** The following structures are used by the code for non deterministic tabling.
*/ 

/* Used to hold a single answer. */
typedef struct {
	Word ans_num;
	Word ans;
} AnswerListNode;

/* Used to save the state of a subgoal */
typedef struct {
	Word *last_ret_ans;		/* Pointer to the last answer returned
					   to the node */
	Code *succ_ip;			/* Saved succip */
	Word *s_p;			/* Saved SP */
	Word *cur_fr;			/* Saved curfr */
	Word *max_fr;			/* Saved maxfr */
	Word non_stack_block_size;	/* Size of saved non stack block */
	Word *non_stack_block;		/* Saved non stack */
	Word det_stack_block_size;	/* Size of saved det stack block */
	Word *det_stack_block;		/* Saved det stack */
} SuspendListNode;

typedef enum {
   	have_no_ans,
	have_some_ans,
	have_all_ans
} TableStatus;

/* Used to save info about a single subgoal in the table */  
typedef struct {
	TableStatus status;		/* Status of subgoal */
	Word answer_table;		/* Table of answers returned by the
					   subgoal */
	Word num_ans;			/* Number of answers returned by the
					   subgoal */
	Word answer_list;		/* List of answers returned by the
					   subgoal */
	Word *answer_list_tail;		/* Pointer to the tail of the answer
					   list. This is used to update the
					   tail rather than the head of the
					   ans list. */
	Word suspend_list;		/* List of suspended calls to the
					   subgoal */
	Word *suspend_list_tail;	/* Ditto for answer_list_tail */
	Word *non_stack_bottom;		/* Pointer to the bottom point of
					   the nondet stack from which to
					   copy */
	Word *det_stack_bottom;		/* Pointer to the bottom point of
					   the det stack from which to copy */
					   
} NondetTable;

	/* Flag used to indicate the answer has been returned */
#define ML_ANS_NOT_RET  0
#define ML_ANS_RET      1

	/* 
	** Cast a Word to a NondetTable*: saves on typing and improves 
	** readability. 
	*/
#define NON_TABLE(T)  (*(NondetTable **)T)
").


:- pragma c_code(table_setup(T0::in, T::out), will_not_call_mercury, "
	/* Init the table if this is the first time me see it */
	if (NON_TABLE(T0) == NULL) {
		NON_TABLE(T0) = (NondetTable *) table_allocate(
			sizeof(NondetTable));
		NON_TABLE(T0)->status = have_no_ans;
		NON_TABLE(T0)->answer_table = (Word) NULL;
		NON_TABLE(T0)->num_ans = 0;
		NON_TABLE(T0)->answer_list = list_empty();
		NON_TABLE(T0)->answer_list_tail =
			&NON_TABLE(T0)->answer_list;
		NON_TABLE(T0)->suspend_list = list_empty();
		NON_TABLE(T0)->suspend_list_tail =
			&NON_TABLE(T0)->suspend_list;
		NON_TABLE(T0)->non_stack_bottom = curprevfr;
		NON_TABLE(T0)->det_stack_bottom = MR_sp;
	}
	T = T0;
").


table_return_all_ans(T, A) :-
	semipure table_return_all_ans_list(T, AnsList),
	list__member(Node, AnsList),
	semipure table_return_all_ans_2(Node, A).

:- semipure pred table_return_all_ans_list(ml_table, list(ml_table)).
:- mode table_return_all_ans_list(in, out) is det.

:- pragma c_code(table_return_all_ans_list(T::in, A::out),
		 will_not_call_mercury, "
	A = NON_TABLE(T)->answer_list;
").

:- semipure pred table_return_all_ans_2(ml_table, ml_table).
:- mode table_return_all_ans_2(in, out) is det.

:- pragma c_code(table_return_all_ans_2(P::in, A::out), 
		will_not_call_mercury, "
	A = (Word) &((AnswerListNode*) P)->ans;
").

:- pragma c_code(table_get_ans_table(T::in, AT::out), 
		will_not_call_mercury, "
	AT = (Word) &(NON_TABLE(T)->answer_table);
").

:- pragma c_code(table_have_all_ans(T::in),"
	SUCCESS_INDICATOR = (NON_TABLE(T)->status == have_all_ans);
").

:- pragma c_code(table_have_some_ans(T::in), will_not_call_mercury, "
	SUCCESS_INDICATOR = (NON_TABLE(T)->status == have_some_ans);
").

:- pragma c_code(table_has_not_returned(T::in), will_not_call_mercury, "
	SUCCESS_INDICATOR = (*((Word*) T) == ML_ANS_NOT_RET);
").



:- pragma c_code(table_mark_have_all_ans(T::in), will_not_call_mercury, "
	NON_TABLE(T)->status = have_all_ans; 
").

:- pragma c_code(table_mark_have_some_ans(T::in), will_not_call_mercury, "
	NON_TABLE(T)->status = have_some_ans; 
").

:- pragma c_code(table_mark_as_returned(T::in), will_not_call_mercury, "
	*((Word *) T) = ML_ANS_RET;
").


:- external(table_suspend/2).
:- external(table_resume/1).

:- pragma c_code("

/* 
** The following procedure saves the state of the mercury runtime 
** so that it may be used in the table_resume procedure below to return 
** answers through this saved state. The procedure table_suspend is 
** declared as nondet but the code below is obviously of detism failure, 
** the reason for this is quite simple. Normally when a nondet proc
** is called it will first return all of its answers and then fail. In the 
** case of calls to this procedure this is reversed first the call will fail
** then later on, when the answers are found, answers will be returned.
** It is also important to note that the answers are returned not from the 
** procedure that was originally called (table_suspend) but from the procedure
** table_resume. So essentially what is below is the code to do the initial 
** fail; the code to return the answers is in table_resume.  
*/ 	
Define_extern_entry(mercury__table_suspend_2_0);
MR_MAKE_STACK_LAYOUT_ENTRY(mercury__table_suspend_2_0);
BEGIN_MODULE(table_suspend_module)
	init_entry_sl(mercury__table_suspend_2_0);
BEGIN_CODE

Define_entry(mercury__table_suspend_2_0);
	mkframe(mercury__table_suspend/2, 0, ENTRY(do_fail));
{
	Word *non_stack_top =  MR_maxfr;
	Word *det_stack_top =  MR_sp;
	Word *non_stack_bottom = NON_TABLE(r1)->non_stack_bottom;
	Word *det_stack_bottom = NON_TABLE(r1)->det_stack_bottom;
	Word non_stack_delta = non_stack_top - non_stack_bottom;
	Word det_stack_delta = det_stack_top - det_stack_bottom;
	Word ListNode;
	SuspendListNode *Node = table_allocate(sizeof(SuspendListNode));

	Node->last_ret_ans = &(NON_TABLE(r1)->answer_list);
	
	Node->non_stack_block_size = non_stack_delta;
	Node->non_stack_block = table_allocate(non_stack_delta);
	table_copy_mem((void *)Node->non_stack_block, (void *)non_stack_bottom, 
		non_stack_delta);	
		
	Node->det_stack_block_size = det_stack_delta;
	Node->det_stack_block = table_allocate(det_stack_delta);
	table_copy_mem((void *)Node->det_stack_block, (void *)det_stack_bottom, 
		det_stack_delta);

	Node->succ_ip = MR_succip;
	Node->s_p = MR_sp;
	Node->cur_fr = MR_curfr;
	Node->max_fr = MR_maxfr;

	ListNode = MR_table_list_cons(Node, *NON_TABLE(r1)->suspend_list_tail);
	*NON_TABLE(r1)->suspend_list_tail = ListNode;
	NON_TABLE(r1)->suspend_list_tail = &list_tail(ListNode);
}
	fail();	
END_MODULE

/*
** The following structure is used to hold the state and variables used in 
** the table_resume procedure. The state and variables must be held in a 
** globally rooted structure as the process of resuming overwrites the mercury 
** and C stacks. A new stack is used to avoid this overwriting. This stack is
** defined and accessed by the following macros and global variables. 
*/
typedef struct {
	NondetTable *table;
	Word non_stack_block_size;
	Word *non_stack_block;
	Word det_stack_block_size;
	Word *det_stack_block;
	
	Code *succ_ip;
	Word *s_p;
	Word *cur_fr;
	Word *max_fr;

	Word changed;
	Word num_ans, new_num_ans;
	Word suspend_list;
	SuspendListNode *suspend_node;
	Word ans_list;
	AnswerListNode *ansNode;
} ResumeStackNode;


Integer ML_resumption_sp = -1;
Word ML_resumption_stack_size = 4;	/* Half the initial size of 
					   the stack in ResumeStackNode's */

ResumeStackNode** ML_resumption_stack = NULL;

#define ML_RESUME_PUSH()						\
	do {								\
		++ML_resumption_sp;					\
		if (ML_resumption_sp >= ML_resumption_stack_size ||	\
				ML_resumption_stack == NULL) 		\
		{							\
			ML_resumption_stack_size =			\
				ML_resumption_stack_size*2;		\
			ML_resumption_stack = table_reallocate(		\
				ML_resumption_stack,			\
				ML_resumption_stack_size*sizeof(	\
					ResumeStackNode*));		\
		}							\
		ML_resumption_stack[ML_resumption_sp] = table_allocate(	\
			sizeof(ResumeStackNode));			\
	} while (0)
	
#define ML_RESUME_POP()							\
	do {								\
		if (ML_resumption_sp < 0) {				\
			fatal_error(""resumption stack underflow"");	\
		}							\
		table_free(ML_resumption_stack[ML_resumption_sp]);	\
		--ML_resumption_sp;					\
	} while (0)

#define ML_RESUME_VAR							\
	ML_resumption_stack[ML_resumption_sp]

/*
** The procedure defined below restores answers to suspended nodes. It 
** works by restoring the states saved when calls to table_suspend were
** made. By restoring the states saved in table_suspend and then returning
** answers it is essentially returning answers out of the call to table_suspend
** not out of the call to table_resume. 
** This procedure iterates until it has returned all answers to all
** suspend nodes. The iteration is a fixpoint type as each time an answer
** is returned to a suspended node it has the chance of introducing more
** answers and/or suspended nodes.  
*/
Define_extern_entry(mercury__table_resume_1_0);
Declare_label(mercury__table_resume_1_0_ChangeLoop);
Declare_label(mercury__table_resume_1_0_ChangeLoopDone);
Declare_label(mercury__table_resume_1_0_SolutionsListLoop);
Declare_label(mercury__table_resume_1_0_AnsListLoop);
Declare_label(mercury__table_resume_1_0_AnsListLoopDone1);
Declare_label(mercury__table_resume_1_0_AnsListLoopDone2);
Declare_label(mercury__table_resume_1_0_SkipAns);
Declare_label(mercury__table_resume_1_0_RedoPoint);

MR_MAKE_STACK_LAYOUT_ENTRY(mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_ChangeLoop, mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_ChangeLoopDone, mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_SolutionsListLoop, mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_AnsListLoop, mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_AnsListLoopDone1, mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_AnsListLoopDone2, mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_SkipAns, mercury__table_resume_1_0);
MR_MAKE_STACK_LAYOUT_INTERNAL_WITH_ENTRY(
	mercury__table_resume_1_0_RedoPoint, mercury__table_resume_1_0);

BEGIN_MODULE(table_resume_module)
	init_entry_sl(mercury__table_resume_1_0);
	init_label_sl(mercury__table_resume_1_0_ChangeLoop);
	init_label_sl(mercury__table_resume_1_0_ChangeLoopDone);
	init_label_sl(mercury__table_resume_1_0_SolutionsListLoop);
	init_label_sl(mercury__table_resume_1_0_AnsListLoop);
	init_label_sl(mercury__table_resume_1_0_AnsListLoopDone1);
	init_label_sl(mercury__table_resume_1_0_AnsListLoopDone2);
	init_label_sl(mercury__table_resume_1_0_SkipAns);
	init_label_sl(mercury__table_resume_1_0_RedoPoint);
BEGIN_CODE

Define_entry(mercury__table_resume_1_0);
	/* Check that we have answers to return and nodes to return 
	   them to. */
	if (list_is_empty(NON_TABLE(r1)->answer_list) ||
			list_is_empty(NON_TABLE(r1)->suspend_list)) 
		proceed(); 
	

	/* Save the current state. */	
	ML_RESUME_PUSH();
	ML_RESUME_VAR->table = NON_TABLE(r1);
	ML_RESUME_VAR->non_stack_block_size = (char *) MR_maxfr -
		(char *) ML_RESUME_VAR->table->non_stack_bottom;
	ML_RESUME_VAR->det_stack_block_size = (char *) MR_sp - 
		(char *) ML_RESUME_VAR->table->det_stack_bottom;
	ML_RESUME_VAR->succ_ip = MR_succip;
	ML_RESUME_VAR->s_p = MR_sp;
	ML_RESUME_VAR->cur_fr = MR_curfr;
	ML_RESUME_VAR->max_fr = MR_maxfr;

	ML_RESUME_VAR->changed = 1;
	
	ML_RESUME_VAR->non_stack_block = (Word *) table_allocate(
		ML_RESUME_VAR->non_stack_block_size);
	table_copy_mem(ML_RESUME_VAR->non_stack_block, 
		ML_RESUME_VAR->table->non_stack_bottom, 
		ML_RESUME_VAR->non_stack_block_size);
	
	ML_RESUME_VAR->det_stack_block = (Word *) table_allocate(
		ML_RESUME_VAR->det_stack_block_size);
	table_copy_mem(ML_RESUME_VAR->det_stack_block, 
		ML_RESUME_VAR->table->det_stack_bottom, 
		ML_RESUME_VAR->det_stack_block_size);

	/* If the number of ans or suspended nodes has changed. */
Define_label(mercury__table_resume_1_0_ChangeLoop);
	if (! ML_RESUME_VAR->changed)
		GOTO_LABEL(mercury__table_resume_1_0_ChangeLoopDone);
		
	ML_RESUME_VAR->suspend_list = ML_RESUME_VAR->table->suspend_list;

	ML_RESUME_VAR->changed = 0;
	ML_RESUME_VAR->num_ans = ML_RESUME_VAR->table->num_ans;

	/* For each of the suspended nodes */	
Define_label(mercury__table_resume_1_0_SolutionsListLoop);
	if (list_is_empty(ML_RESUME_VAR->suspend_list))
		GOTO_LABEL(mercury__table_resume_1_0_ChangeLoop);

	ML_RESUME_VAR->suspend_node = (SuspendListNode *)list_head(
		ML_RESUME_VAR->suspend_list);
	
	ML_RESUME_VAR->ans_list = *ML_RESUME_VAR->suspend_node->
			last_ret_ans;
	
	if (list_is_empty(ML_RESUME_VAR->ans_list))
		GOTO_LABEL(mercury__table_resume_1_0_AnsListLoopDone2);
			
	ML_RESUME_VAR->ansNode = (AnswerListNode *)list_head(
		ML_RESUME_VAR->ans_list);


	/* 
	** Restore the state of the suspended node and return the answer 
	** through the redoip we saved when the node was originally 
	** suspended 
	*/ 
	
								
	table_copy_mem(ML_RESUME_VAR->table->non_stack_bottom, 
		ML_RESUME_VAR->suspend_node->non_stack_block,
		ML_RESUME_VAR->suspend_node->non_stack_block_size);
				
	table_copy_mem(ML_RESUME_VAR->table->det_stack_bottom, 
		ML_RESUME_VAR->suspend_node->det_stack_block,
		ML_RESUME_VAR->suspend_node->det_stack_block_size);

	MR_succip = ML_RESUME_VAR->suspend_node->succ_ip;
	MR_sp = ML_RESUME_VAR->suspend_node->s_p;
	MR_curfr = ML_RESUME_VAR->suspend_node->cur_fr;
	MR_maxfr = ML_RESUME_VAR->suspend_node->max_fr;

	bt_redoip(maxfr) = LABEL(mercury__table_resume_1_0_RedoPoint);

	/* 
	** For each answer not returned to the node whose state we are
	** currently in.
	*/
Define_label(mercury__table_resume_1_0_AnsListLoop);
#ifdef COMPACT_ARGS	
	r1 = (Word) &ML_RESUME_VAR->ansNode->ans;
#else
	r2 = (word) &ML_RESUME_VAR->ansNode->ans;
#endif

	/* 
	** Return the answer though the point where suspend should have
	** returned.
	*/
	succeed();

Define_label(mercury__table_resume_1_0_RedoPoint);
	update_prof_current_proc(LABEL(mercury__table_resume_1_0));
	
	ML_RESUME_VAR->ans_list = list_tail(ML_RESUME_VAR->ans_list);

	if (list_is_empty(ML_RESUME_VAR->ans_list))
		GOTO_LABEL(mercury__table_resume_1_0_AnsListLoopDone1);

	ML_RESUME_VAR->ansNode = (AnswerListNode *)list_head(
		ML_RESUME_VAR->ans_list);

	GOTO_LABEL(mercury__table_resume_1_0_AnsListLoop);

Define_label(mercury__table_resume_1_0_AnsListLoopDone1);
	if (ML_RESUME_VAR->num_ans == ML_RESUME_VAR->table->num_ans)
		ML_RESUME_VAR->changed = 0;
	else 
		ML_RESUME_VAR->changed = 1;
	

	ML_RESUME_VAR->suspend_node->last_ret_ans =
		 &ML_RESUME_VAR->ans_list;

Define_label(mercury__table_resume_1_0_AnsListLoopDone2);
	ML_RESUME_VAR->suspend_list = list_tail(ML_RESUME_VAR->suspend_list);
	GOTO_LABEL(mercury__table_resume_1_0_SolutionsListLoop);

Define_label(mercury__table_resume_1_0_SkipAns);
	ML_RESUME_VAR->ans_list = list_tail(ML_RESUME_VAR->ans_list);
	GOTO_LABEL(mercury__table_resume_1_0_AnsListLoop);
	
Define_label(mercury__table_resume_1_0_ChangeLoopDone);
	/* Restore the original state we had when this proc was called */ 
	
	table_copy_mem(ML_RESUME_VAR->table->non_stack_bottom, 
		ML_RESUME_VAR->non_stack_block,
		ML_RESUME_VAR->non_stack_block_size);
	table_free(ML_RESUME_VAR->non_stack_block);

	table_copy_mem(ML_RESUME_VAR->table->det_stack_bottom, 
		ML_RESUME_VAR->det_stack_block,
		ML_RESUME_VAR->det_stack_block_size);
	table_free(ML_RESUME_VAR->det_stack_block);

	MR_succip = ML_RESUME_VAR->succ_ip;
	MR_sp = ML_RESUME_VAR->s_p;
	MR_curfr = ML_RESUME_VAR->cur_fr;
	MR_maxfr = ML_RESUME_VAR->max_fr;

	ML_RESUME_POP();
	
	proceed();
END_MODULE

/* Ensure that the initialization code for the above module gets run. */
/*
INIT sys_init_table_suspend_module
INIT sys_init_table_resume_module
*/
void sys_init_table_suspend_module(void);
	/* extra declaration to suppress gcc -Wmissing-decl warning */
void sys_init_table_suspend_module(void) {
	extern ModuleFunc table_suspend_module;
	table_suspend_module();
}
void sys_init_table_resume_module(void);
	/* extra declaration to suppress gcc -Wmissing-decl warning */
void sys_init_table_resume_module(void) {
	extern ModuleFunc table_resume_module;
	table_resume_module();
}

").

:- pragma c_code(table_new_ans_slot(T::in, Slot::out), 
		will_not_call_mercury, "
	Word ListNode;
	Word ans_num;
	AnswerListNode *n = table_allocate(sizeof(AnswerListNode));
	
	++(NON_TABLE(T)->num_ans);
	ans_num = NON_TABLE(T)->num_ans;
	n->ans_num = ans_num;
	n->ans = 0;
	ListNode = MR_table_list_cons(n, *NON_TABLE(T)->answer_list_tail);
	*NON_TABLE(T)->answer_list_tail = ListNode; 
	NON_TABLE(T)->answer_list_tail = &list_tail(ListNode);

	Slot = (Word) &n->ans;
").


:- end_module mercury_builtin.

%-----------------------------------------------------------------------------%
