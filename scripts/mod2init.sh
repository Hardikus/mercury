#!/bin/sh

# MOD2INIT - Convert *.mod to *_init.c
#
# This script outputs an appropriate init.c, given the .mod files.
#
# Usage: mod2init [-w<entry_point>] modules...
#
# Environment variables: MERCURY_MOD_LIB_DIR, MERCURY_MOD_LIB_MODS.

MERCURY_MOD_LIB_DIR=${MERCURY_MOD_LIB_DIR:-@LIBDIR@/modules}
MERCURY_MOD_LIB_MODS=${MERCURY_MOD_LIB_MODS:-@LIBDIR@/modules/*.mod}

defentry=mercury__run_0_0
while getopts w: c
do
	case $c in
	w)	defentry="$OPTARG";;
	\?)	echo "Usage: mod2init -[wentry] modules ..."
		exit 1;;
	esac
	shift `expr $OPTIND - 1`
done

files="$* $MERCURY_MOD_LIB_MODS"
modules="`sed -n '/^BEGIN_MODULE(\(.*\)).*$/s//\1/p' $files`"
echo "/*";
echo "** This code was automatically generated by mod2init.";
echo "** Do not edit.";
echo "**"
echo "** Input files:"
for file in $files; do 
	echo "** $file"
done
echo "*/";
echo "";
echo '#include <stddef.h>';
echo '#include "init.h"';
echo "";
echo "Declare_entry($defentry);";
echo "Code *default_entry = ENTRY($defentry);";
echo "";
for mod in $modules; do
	echo "extern void $mod(void);";
done
echo "";
echo "void init_modules(void)";
echo "{";
for mod in $modules; do
	echo "	$mod();";
done
echo "";
echo "	default_entry = ENTRY($defentry);";
echo "}";
