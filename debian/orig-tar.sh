#!/bin/sh
set -e
set -o xtrace

# TODO rest of the options

# To create an rc1 release:
# sh 4.0/debian/orig-tar.sh RELEASE_40 rc1

MAJOR_VERSION=1.0
CURRENT_VERSION=1.0 # Should be changed to 3.5.1 later
EXACT_VERSION=0
LLVM_VER="release_50"

if test -n "$1"; then
# http://llvm.org/svn/llvm-project/{cfe,llvm,compiler-rt,...}/branches/google/stable/
# For example: sh 4.0/debian/orig-tar.sh release_400
    BRANCH=$1
fi

dir=`pwd`
cd ..

SVN_ARCHIVES=git-archives

checkout_sources() {
    PROJECT=$1
    URL=$2
    TARGET=$3
    BRANCH=$4
    if test -z "$BRANCH"; then
        BRANCH=master
    fi
    echo "$PROJECT / $URL / $BRANCH / $TARGET"

    cd $SVN_ARCHIVES/
    DEST=$PROJECT-$BRANCH
    if test -d $DEST; then
        cd $DEST
        git fetch origin $BRANCH
        git checkout origin/$BRANCH
        cd ..
    else
        git clone $2 $DEST -b $BRANCH
    fi
    rm -rf ../$TARGET
    rsync -r --exclude=.git $DEST/ ../$TARGET
    cd ..
}

VERSION=$MAJOR_VERSION"-"$EXACT_VERSION
FULL_VERSION="tapir-toolchain_"$VERSION
MED_VERSION="tapir-toolchain_"$MAJOR_VERSION

mkdir -p $SVN_ARCHIVES

# LLVM
LLVM_TARGET=$FULL_VERSION
checkout_sources llvm https://github.com/wsmoses/Tapir-LLVM $LLVM_TARGET
tar jcf $FULL_VERSION.orig.tar.bz2 $LLVM_TARGET
ln -s $FULL_VERSION.orig.tar.bz2 $MED_VERSION.orig.tar.bz2
rm -rf $LLVM_TARGET


# Clang
CLANG_TARGET=clang_$VERSION
checkout_sources clang https://github.com/wsmoses/Tapir-Clang $CLANG_TARGET
tar jcf $FULL_VERSION.orig-clang.tar.bz2 $CLANG_TARGET
ln -s $FULL_VERSION.orig-clang.tar.bz2 $MED_VERSION.orig-clang.tar.bz2
rm -rf $CLANG_TARGET

# Clang extra
#CLANG_TARGET=clang-tools-extra_$VERSION
#checkout_sources clang-tools-extra https://github.com/llvm-mirror/clang-tools-extra $CLANG_TARGET $LLVM_VER
#tar jcf $FULL_VERSION.orig-clang-tools-extra.tar.bz2 $CLANG_TARGET
#rm -rf $CLANG_TARGET

# Compiler-rt
COMPILER_RT_TARGET=compiler-rt_$VERSION
checkout_sources compiler-rt https://github.com/wsmoses/Tapir-Compiler-RT $COMPILER_RT_TARGET
tar jcf $FULL_VERSION.orig-compiler-rt.tar.bz2 $COMPILER_RT_TARGET
ln -s $FULL_VERSION.orig-compiler-rt.tar.bz2 $MED_VERSION.orig-compiler-rt.tar.bz2
rm -rf $COMPILER_RT_TARGET

# Polly
POLLY_TARGET=polly_$VERSION
checkout_sources polly https://github.com/wsmoses/Tapir-Polly $POLLY_TARGET
tar jcf $FULL_VERSION.orig-polly.tar.bz2 $POLLY_TARGET
ln -s $FULL_VERSION.orig-polly.tar.bz2 $MED_VERSION.orig-polly.tar.bz2
rm -rf $POLLY_TARGET

# LLD
#LLD_TARGET=lld_$VERSION
#checkout_sources lld https://github.com/llvm-mirror/lld $LLD_TARGET $LLVM_VER
#tar jcf $FULL_VERSION.orig-lld.tar.bz2 $LLD_TARGET
#rm -rf $LLD_TARGET

# LLDB
#LLDB_TARGET=lldb_$VERSION
#checkout_sources lldb https://github.com/llvm-mirror/lldb $LLDB_TARGET $LLVM_VER
#tar jcf $FULL_VERSION.orig-lldb.tar.bz2 $LLDB_TARGET
#rm -rf $LLDB_TARGET

PATH_DEBIAN="$(pwd)/$(dirname $0)/../"
echo "going into $PATH_DEBIAN"
export DEBFULLNAME="William S. Moses"
export DEBEMAIL="deb@wsmoses.com"
cd $PATH_DEBIAN

cd $dir
dch --distribution xenial #$EXTRA_DCH_FLAGS --distribution $DISTRIBUTION --newversion 1:$VERSION-1~exp1 "New snapshot release"

tar jxf ../tapir-toolchain_$VERSION.orig.tar.bz2 --strip-components=1
for f in clang compiler-rt polly; do
	if test -e ../tapir-toolchain_$VERSION.orig-$f.tar.bz2; then
		echo "unpack of $f"
		mkdir -p $f && tar jxf ../tapir-toolchain_$VERSION.orig-$f.tar.bz2 --strip-components=1 -C $f
	fi
 done
