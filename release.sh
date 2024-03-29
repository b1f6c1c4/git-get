#!/bin/sh

set -eux

find build/ -mindepth 1 -delete

VERSION="$(git describe --always --dirty | sed 's/-/_/g')"
DATE="$(date -Id)"

mkdir -p build/bin/
sed "s|GIT_GET_VERSION=|GIT_GET_VERSION=$VERSION|" git-get >build/bin/git-get
sed "s|GIT_GET_VERSION=|GIT_GET_VERSION=$VERSION|" git-gets >build/bin/git-gets

mkdir -p build/share/man/man1/
sed "s|GIT_GET_VERSION|$VERSION|; s|GIT_GET_DATE|$DATE|" man/git-get.1 >build/share/man/man1/git-get.1
sed "s|GIT_GET_VERSION|$VERSION|; s|GIT_GET_DATE|$DATE|" man/git-gets.1 >build/share/man/man1/git-gets.1

mkdir -p build/share/licenses/git-get/
cp LICENSE build/share/licenses/git-get/

mkdir -p build/share/zsh/site-functions/
cp zsh/_git-get build/share/zsh/site-functions/_git-get
cp zsh/_git-gets build/share/zsh/site-functions/_git-gets

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

mkdir -p build/arch/
cat - <<EOF >build/arch/PKGBUILD
# Maintainer: b1f6c1c4 <b1f6c1c4@gmail.com>
pkgname=git-get
pkgver=$VERSION
pkgrel=1
pkgdesc="Blazingly fast, incredibly handy git clone alternative"
arch=('any')
url="https://github.com/b1f6c1c4/git-get"
license=('MIT')
depends=('git' 'bash' 'grep' 'sed')
source=("\$pkgname-\$pkgver.tar.xz::\$url/releases/download/\$pkgver/\$pkgname.tar.xz")
sha256sums=('$(sha256sum build/git-get.tar.xz | awk '{ print $1; }')')

package() {
    mkdir -p "\$pkgdir/usr/"
    cp -r "\$srcdir/bin" "\$pkgdir/usr/"
    cp -r "\$srcdir/share" "\$pkgdir/usr/"
}
EOF
