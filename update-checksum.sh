#!/bin/sh

set -ex

echo "Updating checksum..."
echo
for apkbuild in $@; do
  echo "target: $apkbuild"
  cd /src
  pkgdir=$(dirname ${apkbuild})

  cd ${pkgdir}
  abuild checksum
  rm -vrf src
  echo
done
