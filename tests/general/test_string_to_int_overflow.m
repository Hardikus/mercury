%-----------------------------------------------------------------------------%
% test_string_to_int_overflow.m
% Ralph Becket <rafe@csse.unimelb.edu.au>
% Mon Feb  2 13:29:05 EST 2009
% vim: ft=mercury ts=4 sw=4 et wm=0 tw=0
%
%-----------------------------------------------------------------------------%

:- module test_string_to_int_overflow.

:- interface.

:- import_module io.



:- pred main(io::di, io::uo) is det.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- import_module bool.
:- import_module list.
:- import_module string.

%-----------------------------------------------------------------------------%

main(!IO) :-
    Xs = [
        ( if string.to_int("999", _) then yes else no ),
        ( if string.to_int("99999999999999999999", _) then yes else no ),
        ( if string.base_string_to_int(16, "ffffffffff", _) then yes else no ),
        ( if string.base_string_to_int(10, "999", _) then yes else no )
    ],
    io.print(Xs, !IO),
    io.nl(!IO).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%
