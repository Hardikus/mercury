%-----------------------------------------------------------------------------%
% Copyright (C) 1997, 2003-2005 The University of Melbourne.
% This file may only be copied under the terms of the GNU Library General
% Public License - see the file COPYING.LIB in the Mercury distribution.
%-----------------------------------------------------------------------------%
%
% file: mglu.m
% main authors: conway, ohutch, juliensf.
%
% This file provides bindings to the GLU library.
%
% TODO:
% 	- NURBS
% 	- Tessellators
% 	- object-window coordinate mapping (gluProject() and friends).
% 	- Mipmaps

%-----------------------------------------------------------------------------%

:- module mglu.

:- interface.

:- import_module bool.
:- import_module float.
:- import_module int.
:- import_module io.

%-----------------------------------------------------------------------------%
%
% Viewing transformations
%

:- pred look_at(float::in, float::in, float::in, float::in, float::in,
	float::in, float::in, float::in, float::in, io::di, io::uo) is det.

:- pred perspective(float::in, float::in, float::in, float::in, io::di,
	io::uo) is det.

:- pred ortho_2d(float::in, float::in, float::in, float::in, io::di, io::uo)
	is det.

%-----------------------------------------------------------------------------%
%
% Quadrics
%

:- type quadric.

:- type quadric_normals
	--->	smooth 
	;	flat 
	;	none.

:- type quadric_draw_style
	--->	point
	;	line
	;	fill
	;	silhouette.

:- type quadric_orientation
	--->	outside
	;	inside.

:- pred new_quadric(quadric::out, io::di, io::uo) is det.

:- pred delete_quadric(quadric::in, io::di, io::uo) is det.

:- pred quadric_draw_style(quadric::in, quadric_draw_style::in, io::di,
	io::uo) is det.

:- pred quadric_orientation(quadric::in, quadric_orientation::in,
	io::di, io::uo) is det.

:- pred quadric_normals(quadric::in, quadric_normals::in, io::di, io::uo)
	is det.

:- pred quadric_texture(quadric::in, bool::in, io::di, io::uo) is det.

:- pred cylinder(quadric::in, float::in, float::in, float::in, int::in,
	int::in, io::di, io::uo) is det.

:- pred sphere(quadric::in, float::in, int::in, int::in, io::di,
	io::uo) is det.

:- pred disk(quadric::in, float::in, float::in, int::in, int::in,
	io::di, io::uo) is det.

:- pred partial_disk(quadric::in, float::in, float::in, int::in, int::in,
	float::in, float::in, io::di, io::uo) is det.

%------------------------------------------------------------------------------%
%------------------------------------------------------------------------------%

:- implementation.

:- pragma foreign_decl("C", "
	#include <math.h>

	#if defined(__APPLE__) && (__MACH__)	
		#include <OpenGL/glu.h>
	#else
		#include <GL/glu.h>
	#endif
").

%------------------------------------------------------------------------------%
%
% Viewing transformations
%

:- pragma foreign_proc("C", 
	look_at(Ex::in, Ey::in, Ez::in, Cx::in, Cy::in, Cz::in, Ux::in, Uy::in,
		Uz::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure],
"
	gluLookAt((GLdouble) Ex, (GLdouble) Ey, (GLdouble) Ez,
		(GLdouble) Cx, (GLdouble) Cy, (GLdouble) Cz,
		(GLdouble) Ux, (GLdouble) Uy, (GLdouble) Uz);
	IO = IO0;
").

:- pragma foreign_proc("C", 
	perspective(Fovy::in, Asp::in, N::in, F::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure],
"
	gluPerspective((GLdouble) Fovy, (GLdouble) Asp,
		(GLdouble) N, (GLdouble) F);
	IO = IO0;
").


:- pragma foreign_proc("C",
	ortho_2d(Left::in, Right::in, Bottom::in, Top::in, IO0::di, IO::uo),
	[will_not_call_mercury, promise_pure], 
"
	gluOrtho2D((GLdouble) Left, (GLdouble) Right, (GLdouble) Bottom, 
		(GLdouble) Top);
	IO = IO0;
").

%------------------------------------------------------------------------------%
%
% Quadrics
%

:- pragma foreign_type("C", quadric, "GLUquadric *").

:- func quadric_normals_to_int(quadric_normals) = int.

quadric_normals_to_int(smooth) 	= 0.
quadric_normals_to_int(flat)	= 1.
quadric_normals_to_int(none) 	= 2.

:- pragma foreign_decl("C", "
	extern const GLenum quadric_normals_flags[];
").

:- pragma foreign_code("C", "
	const GLenum quadric_normals_flags[] = {
		GLU_SMOOTH,
		GLU_FLAT,
		GLU_NONE
	};
").

:- func quadric_draw_style_to_int(quadric_draw_style) = int.

quadric_draw_style_to_int(point) 	= 0.
quadric_draw_style_to_int(line)		= 1.
quadric_draw_style_to_int(fill) 	= 2.
quadric_draw_style_to_int(silhouette)	= 3.

:- pragma foreign_decl("C", "
	extern const GLenum quadric_draw_style_flags[];
").

:- pragma foreign_code("C", "
	const GLenum quadric_draw_style_flags[] = {
		GLU_POINT,
		GLU_LINE,
		GLU_FILL,
		GLU_SILHOUETTE
	};
").

:- func quadric_orientation_to_int(quadric_orientation) = int.

quadric_orientation_to_int(outside) = 0.
quadric_orientation_to_int(inside)  = 1.

:- pragma foreign_decl("C", "
	extern const GLenum quadric_orientation_flags[];
").

:- pragma foreign_code("C", "
	const GLenum quadric_orientation_flags[] = {
		GLU_OUTSIDE,
		GLU_INSIDE
	};
").

:- func bool_to_int(bool) = int.

bool_to_int(yes) = 1.
bool_to_int(no) = 0.

:- pragma foreign_proc("C", 
	new_quadric(Q::out, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure],
"
	Q = gluNewQuadric();
	gluQuadricCallback(Q, GLU_ERROR, (void *)MGLU_quadric_error_callback);  
	IO = IO0;
").

:- pragma foreign_decl("C",
	"static void MGLU_quadric_error_callback(GLenum);
").

:- pragma foreign_code("C", "
void MGLU_quadric_error_callback(GLenum error_code)
{
	fprintf(stderr, ""mglu: %s\\n"", gluErrorString(error_code));
	fflush(NULL);
	
	exit(EXIT_FAILURE);
}").

:- pragma foreign_proc("C", 
	delete_quadric(Q::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure], 
"
	gluDeleteQuadric(Q);
	IO = IO0;
").

quadric_draw_style(Q, S, !IO) :-
	quadric_draw_style2(Q, quadric_draw_style_to_int(S), !IO).

:- pred quadric_draw_style2(quadric::in, int::in, io::di, io::uo) is det.
:- pragma foreign_proc("C", 
	quadric_draw_style2(Q::in, S::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure], 
"
	gluQuadricDrawStyle(Q, quadric_draw_style_flags[S]);
	IO = IO0;
").

quadric_orientation(Q, O, !IO) :-
	quadric_orientation2(Q, quadric_orientation_to_int(O), !IO).

:- pred quadric_orientation2(quadric::in, int::in, io::di, io::uo) is det.
:- pragma foreign_proc("C", 
	quadric_orientation2(Q::in, O::in, IO0::di, IO::uo),
	[will_not_call_mercury, promise_pure], 
"
	gluQuadricOrientation(Q, quadric_orientation_flags[O]);
	IO = IO0;
").

quadric_normals(Q, N, !IO) :-
	quadric_normals2(Q, quadric_normals_to_int(N), !IO).
	
:- pred quadric_normals2(quadric::in, int::in, io::di, io::uo) is det.
:- pragma foreign_proc("C", 
	quadric_normals2(Q::in, N::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure], 
"
	gluQuadricNormals(Q, quadric_normals_flags[N]);
	IO = IO0;
").

quadric_texture(Q, B, !IO) :-
	quadric_texture2(Q, bool_to_int(B), !IO).

:- pred quadric_texture2(quadric::in, int::in, io::di, io::uo) is det.
:- pragma foreign_proc("C", 
	quadric_texture2(Q::in, B::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure], 
"
	gluQuadricTexture(Q, B);
	IO = IO0;
").

:- pragma foreign_proc("C", 
	cylinder(Q::in, BR::in, TR::in, H::in, SL::in, ST::in, IO0::di, IO::uo),
	[will_not_call_mercury, promise_pure], 
"
	gluCylinder(Q, BR, TR, H, SL, ST);
	IO = IO0;
").

:- pragma foreign_proc("C", 
	sphere(Q::in, R::in, SL::in, ST::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure], 
"
	gluSphere(Q, R, SL, ST);
	IO = IO0;
").

:- pragma foreign_proc("C", 
	disk(Q::in, IR::in, OR::in, S::in, L::in, IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure],
"
	gluDisk(Q, IR, OR, S, L);
	IO = IO0;
").

:- pragma foreign_proc("C", 
	partial_disk(Q::in, IR::in, OR::in, S::in, L::in, STA::in, SWA::in, 
		IO0::di, IO::uo), 
	[will_not_call_mercury, promise_pure], 
"
	gluPartialDisk(Q, IR, OR, S, L, STA, SWA);
	IO = IO0;
").

%------------------------------------------------------------------------------%
:- end_module mglu.
%------------------------------------------------------------------------------%
