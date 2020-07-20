#!/bin/sh

set -eux

mkdir -p build/bin/ build/man/
VERSION="$(git describe --always --dirty)"
DATE="$(date -Id)"

sed "s|GIT_GET_VERSION=|GIT_GET_VERSION=$VERSION|" git-get >build/bin/git-get
sed "s|GIT_GET_VERSION=|GIT_GET_VERSION=$VERSION|" git-gets >build/bin/git-gets
sed "s|GIT_GET_VERSION|$VERSION|; s|GIT_GET_DATE|$DATE|" man/git-get.1 >build/man/git-get.1
sed "s|GIT_GET_VERSION|$VERSION|; s|GIT_GET_DATE|$DATE|" man/git-gets.1 >build/man/git-gets.1

chmod +x build/bin/git-get build/bin/git-gets

(
cd build/
tar -czvf git-get.tar.gz --owner=root --group=root bin/ man/
tar -cJvf git-get.tar.xz --owner=root --group=root bin/ man/
zip -r git-get.zip bin/ man/
)

echo "git-get(1) $VERSION"

gpg --detach-sign build/git-get.tar.gz
gpg --detach-sign build/git-get.tar.xz
gpg --detach-sign build/git-get.zip
