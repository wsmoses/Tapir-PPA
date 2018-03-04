./debian/orig-tar.sh || exit 1
DEB_BUILD_OPTIONS=parallel=6 PATH=/usr/lib/ccache:$PATH fakeroot debian/rules binary
#DEB_BUILD_OPTIONS=parallel=6 fakeroot debian/rules binary
