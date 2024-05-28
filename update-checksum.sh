#!/bin/sh

set -ex

echo "Updating checksum..."
for apkbuild in $@; do
  echo "target: $apkbuild"
  cd /src
  pkgdir=$(dirname ${apkbuild})
  ls -la ${pkgdir}

  (
    cd ${pkgdir}
    abuild checksum
    rm -vrf src
    echo
  )
done
