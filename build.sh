#!/bin/bash
VERSION=`grep KV_VERSION= kv/usr/bin/kv|cut -d'"' -f2`
git tag ${VERSION}
git push origin --tags
[[ ! -d dists/debian/amd64 ]] && mkdir -p dists/debian/amd64
[[ ! -d dists/rhel/noarch ]] && mkdir -p dists/rhel/noarch
#git pull
dpkg-deb --nocheck --build kv
mv -f kv.deb dists/debian/amd64/kv-${VERSION}_amd64.deb
sudo alien --to-rpm dists/debian/amd64/kv-${VERSION}_amd64.deb
mv -f kv-${VERSION}-?.noarch.rpm dists/rhel/noarch/
git add dists/debian/amd64/kv-${VERSION}_amd64.deb
git add dists/rhel/noarch/kv-${VERSION}-?.noarch.rpm
git commit -m "lee@cowdrey.net: "
git push
