
/*
** Copyright (C) 1997 The University of Melbourne.
** This file may only be copied under the terms of the GNU Library General
** Public License - see the file COPYING.LIB in the Mercury distribution.
**
** $Id: mb_stack.c,v 1.1 2001-01-24 07:42:28 lpcam Exp $
**
** High-water marked stack of 'MB_Word's
**
*/

/* Imports */

#include <assert.h>

#include "mb_bytecode.h"
#include "mb_mem.h"
#include "mb_stack.h"

/* Exported definitions */

MB_Stack	MB_stack_new(MB_Word init_size);
MB_Word		MB_stack_size(MB_Stack* s);
void		MB_stack_push(MB_Stack* s, MB_Word x);
MB_Word		MB_stack_pop(MB_Stack* s);
MB_Word		MB_stack_alloc(MB_Stack* s, MB_Word num_words);
void		MB_stack_free(MB_Stack* s, MB_Word num_words);
MB_Word		MB_stack_peek(MB_Stack* s, MB_Word index);
MB_Word		MB_stack_peek_rel(MB_Stack* s, MB_Word rel_index);
MB_Word*	MB_stack_peek_p(MB_Stack* s, MB_Word index);
MB_Word*	MB_stack_peek_rel_p(MB_Stack* s, MB_Word rel_index);
void		MB_stack_poke(MB_Stack* s, MB_Word index, MB_Word x);
void		MB_stack_poke_rel(MB_Stack* s, MB_Word rel_idx, MB_Word value);
void		MB_stack_delete(MB_Stack* s);


/* Local declarations */

static char
rcs_id[]	= "$Id: mb_stack.c,v 1.1 2001-01-24 07:42:28 lpcam Exp $";



/* Implementation */

MB_Stack
MB_stack_new(MB_Word init_size) {
	MB_Stack s;

	s.max_size = init_size;
	s.data = MB_new_array(MB_Word, init_size);
	s.sp = 0;
	if (s.data == NULL) {
		MB_fatal("Unable to allocate memory");
	}
	
	return s;
}


MB_Word
MB_stack_size(MB_Stack* s) {
	return s->sp;
}

void
MB_stack_push(MB_Stack* s, MB_Word x)
{
	if (s->sp == s->max_size) {
		s->max_size *= 2;
		s->data = MB_resize_array(s->data, MB_Word, s->max_size);
		assert(s->data != NULL);
	}
	s->data[s->sp++] = x;
}

MB_Word
MB_stack_pop(MB_Stack* s) {
	assert(s->sp != 0);
	s->sp--;
	return s->data[s->sp];
}

MB_Word
MB_stack_alloc(MB_Stack* s, MB_Word num_words)
{
	MB_Word orig_sp = s->sp;
	while (s->sp + num_words > s->max_size) {
		num_words -= (s->max_size - s->sp);
		s->sp = s->max_size;
		num_words--;
		MB_stack_push(s, 0);
	}
	s->sp += num_words;
	return orig_sp;
}


void
MB_stack_free(MB_Stack* s, MB_Word num_words) {
	s->sp -= num_words;
	assert(s->sp >= 0);
}

MB_Word
MB_stack_peek(MB_Stack* s, MB_Word index) {
	assert(index >= 0);
	assert(index < s->sp);
	return s->data[index];
}

MB_Word
MB_stack_peek_rel(MB_Stack* s, MB_Word rel_index) {
	return MB_stack_peek(s, s->sp - rel_index);
}

MB_Word*
MB_stack_peek_p(MB_Stack* s, MB_Word index) {
	assert(index >= 0);
	assert(index < s->sp);
	return s->data + index;
}

MB_Word*
MB_stack_peek_rel_p(MB_Stack* s, MB_Word rel_index) {
	return MB_stack_peek_p(s, s->sp - rel_index);
}

void
MB_stack_poke(MB_Stack* s, MB_Word index, MB_Word x) {
	assert(index >= 0);
	assert(index < s->sp);
	s->data[index] = x;
}

void
MB_stack_poke_rel(MB_Stack* s, MB_Word rel_idx, MB_Word value) {
	MB_stack_poke(s, s->sp - rel_idx, value);
}

void
MB_stack_delete(MB_Stack* s) {
	MB_free(s->data);
}



