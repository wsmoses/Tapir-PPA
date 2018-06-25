#!/bin/sh
set -e
set -o xtrace

# TODO rest of the options

# To create an rc1 release:
# sh 4.0/debian/orig-tar.sh RELEASE_40 rc1

PACKAGE_NAME="tapir-toolchain-5.0"
MAJOR_VERSION=5.0
LLVM_VER="release_50"

if test -n "$1"; then
# http://llvm.org/svn/llvm-project/{cfe,llvm,compiler-rt,...}/branches/google/stable/
# For example: sh 4.0/debian/orig-tar.sh release_400
    BRANCH=$1
fi

dir=`pwd`
cd ..

SVN_ARCHIVES=git-archives

update_source() {
    PROJECT=$1
    URL=$2
    BRANCH=$3
    if test -z "$BRANCH"; then
        BRANCH=master
    fi
    echo "$PROJECT / $URL / $BRANCH"

    cd $SVN_ARCHIVES/
    if test -d $PROJECT; then
        cd $PROJECT
        git fetch origin $BRANCH
        git checkout origin/$BRANCH
        cd ..
    else
        git clone $2 $PROJECT -b $BRANCH
    fi
    cd ..
}

mkdir -p $SVN_ARCHIVES
update_source llvm https://github.com/wsmoses/Tapir-LLVM
update_source clang https://github.com/wsmoses/Tapir-Clang
update_source clang-tools-extra https://github.com/llvm-mirror/clang-tools-extra $LLVM_VER
update_source compiler-rt https://github.com/wsmoses/Tapir-Compiler-RT
update_source polly https://github.com/wsmoses/Tapir-Polly
update_source lld https://github.com/llvm-mirror/lld $LLVM_VER

EXACT_VERSION=~`cd $SVN_ARCHIVES/llvm && git rev-parse HEAD`
VERSION=$MAJOR_VERSION$EXACT_VERSION
FULL_VERSION="$PACKAGE_NAME-"$VERSION
MED_VERSION="$PACKAGE_NAME-"$MAJOR_VERSION

compress_source() {
    PROJECT=$1
    if [ "$PROJECT" = "llvm" ]; then
      TARGET="$FULL_VERSION"
      ORIG="orig"
    else
      TARGET="$PROJECT"_"$VERSION"
      ORIG="orig-$PROJECT"
    fi

    cd $SVN_ARCHIVES/
    rm -rf ../$TARGET
    rsync -r --exclude=.git $PROJECT/ ../$TARGET
    cd ..

    tar jcf $FULL_VERSION.$ORIG.tar.bz2 $TARGET
    rm -f $MED_VERSION.$ORIG.tar.bz2
    ln -s $FULL_VERSION.$ORIG.tar.bz2 $MED_VERSION.$ORIG.tar.bz2
    rm -rf $TARGET
}

compress_source llvm
compress_source clang
compress_source clang-tools-extra
compress_source compiler-rt
compress_source polly
compress_source lld
#compress_source lldb

PATH_DEBIAN="$(pwd)/$(dirname $0)/../"
echo "going into $PATH_DEBIAN"
export DEBFULLNAME="William S. Moses"
export DEBEMAIL="deb@wsmoses.com"
cd $PATH_DEBIAN

cd $dir
dch --distribution xenial #$EXTRA_DCH_FLAGS --distribution $DISTRIBUTION --newversion 1:$VERSION-1~exp1 "New snapshot release"

tar jxf ../$FULL_VERSION.orig.tar.bz2 --strip-components=1
for f in clang compiler-rt polly clang-tools-extra lld; do
	if test -e ../$FULL_VERSION.orig-$f.tar.bz2; then
		echo "unpack of $f"
		mkdir -p $f && tar jxf ../$FULL_VERSION.orig-$f.tar.bz2 --strip-components=1 -C $f
	fi
 done

#rm -rf `pwd`/tools/clang
#ln -s `pwd`/clang `pwd`/tools/clang

#rm -rf `pwd`/projects/compiler-rt
#ln -s `pwd`/compiler-rt `pwd`/projects/compiler-rt

#rm -rf `pwd`/tools/polly
#ln -s `pwd`/polly `pwd`/tools/polly

#rm -rf `pwd`/tools/clang/tools/extra
#ln -s `pwd`/clang-tools-extra `pwd`/tools/clang/tools/extra

#rm -rf `pwd`/projects/compiler-rt
#ln -s `pwd`/compiler-rt `pwd`/projects/compiler-rt

#rm -rf `pwd`/tools/polly
#ln -s `pwd`/polly `pwd`/tools/polly

#rm -rf `pwd`/tools/lld
#ln -s `pwd`/lld `pwd`/tools/lld

#rm -rf `pwd`/tools/lldb
#ln -s `pwd`/lldb `pwd`/tools/lldb
