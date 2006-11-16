#!/bin/sh
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="gnome-doc-utils"

(test -f $srcdir/configure.in \
  && test -f $srcdir/README \
  && test -d $srcdir/xslt) || {
    echo -n "**Error**: Directory "\`$srcdir\'" does not look like the"
    echo " top-level $PKG_NAME directory"
    exit 1
}

which gnome-autogen.sh || {
    echo "You need to install gnome-common from the GNOME CVS"
    exit 1
}

# Bootstrap off the local gnome-doc-utils.m4
ACLOCAL_FLAGS="-I . $ACLOCAL_FLAGS"
export ACLOCAL_FLAGS

cp $srcdir/tools/gnome-doc-utils.m4 m4/gnome-doc-utils.m4
cp $srcdir/tools/gnome-doc-utils.make gnome-doc-utils.make
REQUIRED_AUTOMAKE_VERSION=1.6 USE_GNOME2_MACROS=1 . gnome-autogen.sh
