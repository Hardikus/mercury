%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

% File: char.nl.
% Main author: fjh.

% This module defines some predicates that manipulate characters.

% At the moment we are using 'character' rather than 'char'
% because 'char' is already used by NU-Prolog to mean something
% different.
%
% NU-Prolog atoms can only include 7-bit ASCII chars, so the current
% implementation does not support 8-bit characters.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- module char.
:- interface.

:- import_module list.

%-----------------------------------------------------------------------------%

:- pred char_to_int(character, int).
:- mode char_to_int(in, out).
:- mode char_to_int(out, in).
	% Convert a character to it's corresponding numerical code.

:- pred to_upper(character, character).
:- mode to_upper(in, out).
	% Convert a character to uppercase.

:- pred to_lower(character, character).
:- mode to_lower(in, out).
	% Convert a character to lowercase.

:- pred is_upper(character).
:- mode is_upper(in).
	% True iff the character is an uppercase letter.

:- pred is_alpha(character).
:- mode is_alpha(in).
	% True iff the character is a letter.

:- pred is_alpha_or_underscore(character).
:- mode is_alpha_or_underscore(in).
	% True iff the character is a letter or an underscore.

:- pred is_alnum_or_underscore(character).
:- mode is_alnum_or_underscore(in).
	% True iff the character is a letter, a digit or an underscore.

:- pred is_digit(character).
:- mode is_digit(in).
	% True iff the character is a decimal digit.

:- pred is_lower(character).
:- mode is_lower(in).
	% True iff the character is a lowercase letter.

:- pred lower_upper(character, character).
:- mode lower_upper(in, out).
:- mode lower_upper(out, in).
	% lower_upper(Lower, Upper) is true iff
	% Lower is a lower-case letter and Upper is the corresponding
	% upper-case letter.

:- pred char__escape(character, list(character)).
:- mode char__escape(in, out).
:- mode char__escape(out, in).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

is_alpha(Char) :-
	( is_lower(Char) ->
		true
	; is_upper(Char) ->
		true
	;
		fail
	).

is_alpha_or_underscore(Char) :-
	( Char = '_' ->
		true
	;	
		is_alpha(Char)
	).

is_alnum_or_underscore(Char) :-
	( is_digit(Char) ->
		true
	;	
		is_alpha_or_underscore(Char)
	).

is_lower(Lower) :-
	lower_upper(Lower, _).

is_upper(Upper) :-
	(
		lower_upper(_, Upper)
	->
		true
	;
		fail
	).

to_lower(Char, Lower) :-
	(
		lower_upper(LowerChar, Char)
	->
		Lower = LowerChar
	;
		Lower = Char
	).

to_upper(Char, Upper) :-
	(
		lower_upper(Char, UpperChar)
	->
		Upper = UpperChar
	;
		Upper = Char
	).

%-----------------------------------------------------------------------------%

% Lots of big tables.
%
% It's conceivable that there are more efficient implementations,
% but these versions are very portable.

%-----------------------------------------------------------------------------%

is_digit('0').
is_digit('1').
is_digit('2').
is_digit('3').
is_digit('4').
is_digit('5').
is_digit('6').
is_digit('7').
is_digit('8').
is_digit('9').

%%% char_to_int('\000', 0).	% not supported by NU-Prolog
char_to_int('\001', 1).
char_to_int('\002', 2).
char_to_int('\003', 3).
char_to_int('\004', 4).
char_to_int('\005', 5).
char_to_int('\006', 6).
char_to_int('\007', 7).
char_to_int('\010', 8).
char_to_int('\011', 9).
char_to_int('\012', 10).
char_to_int('\013', 11).
char_to_int('\014', 12).
char_to_int('\015', 13).
char_to_int('\016', 14).
char_to_int('\017', 15).
char_to_int('\020', 16).
char_to_int('\021', 17).
char_to_int('\022', 18).
char_to_int('\023', 19).
char_to_int('\024', 20).
char_to_int('\025', 21).
char_to_int('\026', 22).
char_to_int('\027', 23).
char_to_int('\030', 24).
char_to_int('\031', 25).
char_to_int('\032', 26).
char_to_int('\033', 27).
char_to_int('\034', 28).
char_to_int('\035', 29).
char_to_int('\036', 30).
char_to_int('\037', 31).
char_to_int('\040', 32).
char_to_int('\041', 33).
char_to_int('\042', 34).
char_to_int('\043', 35).
char_to_int('\044', 36).
char_to_int('\045', 37).
char_to_int('\046', 38).
char_to_int('\047', 39).
char_to_int('\050', 40).
char_to_int('\051', 41).
char_to_int('\052', 42).
char_to_int('\053', 43).
char_to_int('\054', 44).
char_to_int('\055', 45).
char_to_int('\056', 46).
char_to_int('\057', 47).
char_to_int('\060', 48).
char_to_int('\061', 49).
char_to_int('\062', 50).
char_to_int('\063', 51).
char_to_int('\064', 52).
char_to_int('\065', 53).
char_to_int('\066', 54).
char_to_int('\067', 55).
char_to_int('\070', 56).
char_to_int('\071', 57).
char_to_int('\072', 58).
char_to_int('\073', 59).
char_to_int('\074', 60).
char_to_int('\075', 61).
char_to_int('\076', 62).
char_to_int('\077', 63).
char_to_int('\100', 64).
char_to_int('\101', 65).
char_to_int('\102', 66).
char_to_int('\103', 67).
char_to_int('\104', 68).
char_to_int('\105', 69).
char_to_int('\106', 70).
char_to_int('\107', 71).
char_to_int('\110', 72).
char_to_int('\111', 73).
char_to_int('\112', 74).
char_to_int('\113', 75).
char_to_int('\114', 76).
char_to_int('\115', 77).
char_to_int('\116', 78).
char_to_int('\117', 79).
char_to_int('\120', 80).
char_to_int('\121', 81).
char_to_int('\122', 82).
char_to_int('\123', 83).
char_to_int('\124', 84).
char_to_int('\125', 85).
char_to_int('\126', 86).
char_to_int('\127', 87).
char_to_int('\130', 88).
char_to_int('\131', 89).
char_to_int('\132', 90).
char_to_int('\133', 91).
char_to_int('\134', 92).
char_to_int('\135', 93).
char_to_int('\136', 94).
char_to_int('\137', 95).
char_to_int('\140', 96).
char_to_int('\141', 97).
char_to_int('\142', 98).
char_to_int('\143', 99).
char_to_int('\144', 100).
char_to_int('\145', 101).
char_to_int('\146', 102).
char_to_int('\147', 103).
char_to_int('\150', 104).
char_to_int('\151', 105).
char_to_int('\152', 106).
char_to_int('\153', 107).
char_to_int('\154', 108).
char_to_int('\155', 109).
char_to_int('\156', 110).
char_to_int('\157', 111).
char_to_int('\160', 112).
char_to_int('\161', 113).
char_to_int('\162', 114).
char_to_int('\163', 115).
char_to_int('\164', 116).
char_to_int('\165', 117).
char_to_int('\166', 118).
char_to_int('\167', 119).
char_to_int('\170', 120).
char_to_int('\171', 121).
char_to_int('\172', 122).
char_to_int('\173', 123).
char_to_int('\174', 124).
char_to_int('\175', 125).
char_to_int('\176', 126).
char_to_int('\177', 127).

% XXX
% NU-Prolog atoms can only include 7-bit ASCII chars.

/***********
char_to_int('\200', 128).
char_to_int('\201', 129).
char_to_int('\202', 130).
char_to_int('\203', 131).
char_to_int('\204', 132).
char_to_int('\205', 133).
char_to_int('\206', 134).
char_to_int('\207', 135).
char_to_int('\210', 136).
char_to_int('\211', 137).
char_to_int('\212', 138).
char_to_int('\213', 139).
char_to_int('\214', 140).
char_to_int('\215', 141).
char_to_int('\216', 142).
char_to_int('\217', 143).
char_to_int('\220', 144).
char_to_int('\221', 145).
char_to_int('\222', 146).
char_to_int('\223', 147).
char_to_int('\224', 148).
char_to_int('\225', 149).
char_to_int('\226', 150).
char_to_int('\227', 151).
char_to_int('\230', 152).
char_to_int('\231', 153).
char_to_int('\232', 154).
char_to_int('\233', 155).
char_to_int('\234', 156).
char_to_int('\235', 157).
char_to_int('\236', 158).
char_to_int('\237', 159).
char_to_int('\240', 160).
char_to_int('\241', 161).
char_to_int('\242', 162).
char_to_int('\243', 163).
char_to_int('\244', 164).
char_to_int('\245', 165).
char_to_int('\246', 166).
char_to_int('\247', 167).
char_to_int('\250', 168).
char_to_int('\251', 169).
char_to_int('\252', 170).
char_to_int('\253', 171).
char_to_int('\254', 172).
char_to_int('\255', 173).
char_to_int('\256', 174).
char_to_int('\257', 175).
char_to_int('\260', 176).
char_to_int('\261', 177).
char_to_int('\262', 178).
char_to_int('\263', 179).
char_to_int('\264', 180).
char_to_int('\265', 181).
char_to_int('\266', 182).
char_to_int('\267', 183).
char_to_int('\270', 184).
char_to_int('\271', 185).
char_to_int('\272', 186).
char_to_int('\273', 187).
char_to_int('\274', 188).
char_to_int('\275', 189).
char_to_int('\276', 190).
char_to_int('\277', 191).
char_to_int('\300', 192).
char_to_int('\301', 193).
char_to_int('\302', 194).
char_to_int('\303', 195).
char_to_int('\304', 196).
char_to_int('\305', 197).
char_to_int('\306', 198).
char_to_int('\307', 199).
char_to_int('\310', 200).
char_to_int('\311', 201).
char_to_int('\312', 202).
char_to_int('\313', 203).
char_to_int('\314', 204).
char_to_int('\315', 205).
char_to_int('\316', 206).
char_to_int('\317', 207).
char_to_int('\320', 208).
char_to_int('\321', 209).
char_to_int('\322', 210).
char_to_int('\323', 211).
char_to_int('\324', 212).
char_to_int('\325', 213).
char_to_int('\326', 214).
char_to_int('\327', 215).
char_to_int('\330', 216).
char_to_int('\331', 217).
char_to_int('\332', 218).
char_to_int('\333', 219).
char_to_int('\334', 220).
char_to_int('\335', 221).
char_to_int('\336', 222).
char_to_int('\337', 223).
char_to_int('\340', 224).
char_to_int('\341', 225).
char_to_int('\342', 226).
char_to_int('\343', 227).
char_to_int('\344', 228).
char_to_int('\345', 229).
char_to_int('\346', 230).
char_to_int('\347', 231).
char_to_int('\350', 232).
char_to_int('\351', 233).
char_to_int('\352', 234).
char_to_int('\353', 235).
char_to_int('\354', 236).
char_to_int('\355', 237).
char_to_int('\356', 238).
char_to_int('\357', 239).
char_to_int('\360', 240).
char_to_int('\361', 241).
char_to_int('\362', 242).
char_to_int('\363', 243).
char_to_int('\364', 244).
char_to_int('\365', 245).
char_to_int('\366', 246).
char_to_int('\367', 247).
char_to_int('\370', 248).
char_to_int('\371', 249).
char_to_int('\372', 250).
char_to_int('\373', 251).
char_to_int('\374', 252).
char_to_int('\375', 253).
char_to_int('\376', 254).
char_to_int('\377', 255).
*********/

%-----------------------------------------------------------------------------%

:- lower_upper(X, Y) when X or Y.

lower_upper('a', 'A').
lower_upper('b', 'B').
lower_upper('c', 'C').
lower_upper('d', 'D').
lower_upper('e', 'E').
lower_upper('f', 'F').
lower_upper('g', 'G').
lower_upper('h', 'H').
lower_upper('i', 'I').
lower_upper('j', 'J').
lower_upper('k', 'K').
lower_upper('l', 'L').
lower_upper('m', 'M').
lower_upper('n', 'N').
lower_upper('o', 'O').
lower_upper('p', 'P').
lower_upper('q', 'Q').
lower_upper('r', 'R').
lower_upper('s', 'S').
lower_upper('t', 'T').
lower_upper('u', 'U').
lower_upper('v', 'V').
lower_upper('w', 'W').
lower_upper('x', 'X').
lower_upper('y', 'Y').
lower_upper('z', 'Z').

%-----------------------------------------------------------------------------%

char__escape(C, Cs) :-
	char_to_int(C, C1),
	char__escape_2(C1, Cs).

:- pred char__escape_2(int, list(character)).
:- mode char__escape_2(in, out) is det.

char__escape_2(1, ['\\','1']).
char__escape_2(2, ['\\','2']).
char__escape_2(3, ['\\','3']).
char__escape_2(4, ['\\','4']).
char__escape_2(5, ['\\','5']).
char__escape_2(6, ['\\','6']).
char__escape_2(7, ['\\','7']).
char__escape_2(8, ['\\','1','0']).
char__escape_2(9, ['\\','1','1']).
char__escape_2(10, ['\\','1','2']).
char__escape_2(11, ['\\','1','3']).
char__escape_2(12, ['\\','1','4']).
char__escape_2(13, ['\\','1','5']).
char__escape_2(14, ['\\','1','6']).
char__escape_2(15, ['\\','1','7']).
char__escape_2(16, ['\\','2','0']).
char__escape_2(17, ['\\','2','1']).
char__escape_2(18, ['\\','2','2']).
char__escape_2(19, ['\\','2','3']).
char__escape_2(20, ['\\','2','4']).
char__escape_2(21, ['\\','2','5']).
char__escape_2(22, ['\\','2','6']).
char__escape_2(23, ['\\','2','7']).
char__escape_2(24, ['\\','3','0']).
char__escape_2(25, ['\\','3','1']).
char__escape_2(26, ['\\','3','2']).
char__escape_2(27, ['\\','3','3']).
char__escape_2(28, ['\\','3','4']).
char__escape_2(29, ['\\','3','5']).
char__escape_2(30, ['\\','3','6']).
char__escape_2(31, ['\\','3','7']).
char__escape_2(32, ['\\','4','0']).
char__escape_2(33, ['\\','4','1']).
char__escape_2(34, ['\\','4','2']).
char__escape_2(35, ['\\','4','3']).
char__escape_2(36, ['\\','4','4']).
char__escape_2(37, ['\\','4','5']).
char__escape_2(38, ['\\','4','6']).
char__escape_2(39, ['\\','4','7']).
char__escape_2(40, ['\\','5','0']).
char__escape_2(41, ['\\','5','1']).
char__escape_2(42, ['\\','5','2']).
char__escape_2(43, ['\\','5','3']).
char__escape_2(44, ['\\','5','4']).
char__escape_2(45, ['\\','5','5']).
char__escape_2(46, ['\\','5','6']).
char__escape_2(47, ['\\','5','7']).
char__escape_2(48, ['\\','6','0']).
char__escape_2(49, ['\\','6','1']).
char__escape_2(50, ['\\','6','2']).
char__escape_2(51, ['\\','6','3']).
char__escape_2(52, ['\\','6','4']).
char__escape_2(53, ['\\','6','5']).
char__escape_2(54, ['\\','6','6']).
char__escape_2(55, ['\\','6','7']).
char__escape_2(56, ['\\','7','0']).
char__escape_2(57, ['\\','7','1']).
char__escape_2(58, ['\\','7','2']).
char__escape_2(59, ['\\','7','3']).
char__escape_2(60, ['\\','7','4']).
char__escape_2(61, ['\\','7','5']).
char__escape_2(62, ['\\','7','6']).
char__escape_2(63, ['\\','7','7']).
char__escape_2(64, ['\\','1','0','0']).
char__escape_2(65, ['\\','1','0','1']).
char__escape_2(66, ['\\','1','0','2']).
char__escape_2(67, ['\\','1','0','3']).
char__escape_2(68, ['\\','1','0','4']).
char__escape_2(69, ['\\','1','0','5']).
char__escape_2(70, ['\\','1','0','6']).
char__escape_2(71, ['\\','1','0','7']).
char__escape_2(72, ['\\','1','1','0']).
char__escape_2(73, ['\\','1','1','1']).
char__escape_2(74, ['\\','1','1','2']).
char__escape_2(75, ['\\','1','1','3']).
char__escape_2(76, ['\\','1','1','4']).
char__escape_2(77, ['\\','1','1','5']).
char__escape_2(78, ['\\','1','1','6']).
char__escape_2(79, ['\\','1','1','7']).
char__escape_2(80, ['\\','1','2','0']).
char__escape_2(81, ['\\','1','2','1']).
char__escape_2(82, ['\\','1','2','2']).
char__escape_2(83, ['\\','1','2','3']).
char__escape_2(84, ['\\','1','2','4']).
char__escape_2(85, ['\\','1','2','5']).
char__escape_2(86, ['\\','1','2','6']).
char__escape_2(87, ['\\','1','2','7']).
char__escape_2(88, ['\\','1','3','0']).
char__escape_2(89, ['\\','1','3','1']).
char__escape_2(90, ['\\','1','3','2']).
char__escape_2(91, ['\\','1','3','3']).
char__escape_2(92, ['\\','1','3','4']).
char__escape_2(93, ['\\','1','3','5']).
char__escape_2(94, ['\\','1','3','6']).
char__escape_2(95, ['\\','1','3','7']).
char__escape_2(96, ['\\','1','4','0']).
char__escape_2(97, ['\\','1','4','1']).
char__escape_2(98, ['\\','1','4','2']).
char__escape_2(99, ['\\','1','4','3']).
char__escape_2(100, ['\\','1','4','4']).
char__escape_2(101, ['\\','1','4','5']).
char__escape_2(102, ['\\','1','4','6']).
char__escape_2(103, ['\\','1','4','7']).
char__escape_2(104, ['\\','1','5','0']).
char__escape_2(105, ['\\','1','5','1']).
char__escape_2(106, ['\\','1','5','2']).
char__escape_2(107, ['\\','1','5','3']).
char__escape_2(108, ['\\','1','5','4']).
char__escape_2(109, ['\\','1','5','5']).
char__escape_2(110, ['\\','1','5','6']).
char__escape_2(111, ['\\','1','5','7']).
char__escape_2(112, ['\\','1','6','0']).
char__escape_2(113, ['\\','1','6','1']).
char__escape_2(114, ['\\','1','6','2']).
char__escape_2(115, ['\\','1','6','3']).
char__escape_2(116, ['\\','1','6','4']).
char__escape_2(117, ['\\','1','6','5']).
char__escape_2(118, ['\\','1','6','6']).
char__escape_2(119, ['\\','1','6','7']).
char__escape_2(120, ['\\','1','7','0']).
char__escape_2(121, ['\\','1','7','1']).
char__escape_2(122, ['\\','1','7','2']).
char__escape_2(123, ['\\','1','7','3']).
char__escape_2(124, ['\\','1','7','4']).
char__escape_2(125, ['\\','1','7','5']).
char__escape_2(126, ['\\','1','7','6']).
char__escape_2(127, ['\\','1','7','7']).

%-----------------------------------------------------------------------------%
