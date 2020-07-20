#!/bin/sh

set -eux

find build/ -mindepth 1 -delete

mkdir -p build/bin/ build/share/man/man1/ build/share/licenses/git-get/
VERSION="$(git describe --always --dirty | sed 's/-/_/g')"
DATE="$(date -Id)"

cp LICENSE build/share/licenses/git-get/
sed "s|GIT_GET_VERSION=|GIT_GET_VERSION=$VERSION|" git-get >build/bin/git-get
sed "s|GIT_GET_VERSION=|GIT_GET_VERSION=$VERSION|" git-gets >build/bin/git-gets
sed "s|GIT_GET_VERSION|$VERSION|; s|GIT_GET_DATE|$DATE|" man/git-get.1 >build/share/man/man1/git-get.1
sed "s|GIT_GET_VERSION|$VERSION|; s|GIT_GET_DATE|$DATE|" man/git-gets.1 >build/share/man/man1/git-gets.1

chmod +x build/bin/git-get build/bin/git-gets

(
cd build/
tar -czvf git-get.tar.gz --owner=root --group=root bin/ share/
tar -cJvf git-get.tar.xz --owner=root --group=root bin/ share/
zip -r git-get.zip bin/ share/
)

echo "git-get(1) $VERSION"

gpg --detach-sign build/git-get.tar.gz
gpg --detach-sign build/git-get.tar.xz
gpg --detach-sign build/git-get.zip

KEY="$(gpg --verify build/git-get.tar.xz.sig 2>&1 | grep -Po '(?<=using RSA key )[0-9A-F]{40}')"

cat - <<EOF >build/PKGBUILD
pkgname=git-get
pkgver=$VERSION
pkgrel=1
pkgdesc="Blazingly fast, incredibly handy git clone alternative"
arch=('any')
url="https://github.com/b1f6c1c4/git-get"
license=('MIT')
depends=('git' 'bash' 'grep' 'sed' 'awk')
# source=(\$url/releases/download/\$pkgver/\$pkgname.tar.xz{,.sig})
source=(file:///home/b1f6c1c4/git-get/build/\$pkgname.tar.xz)
sha256sums=('$(sha256sum build/git-get.tar.xz | awk '{ print $1; }')')

build() {
    true
}

package() {
    cp -r "\$srcdir" "\$pkgdir/usr"
}
EOF
