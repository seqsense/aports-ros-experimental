#!/bin/sh

set -e

echo "Updating checksum..."
cd /src
echo $@ | while read apkbuild; do
  echo $apkbuild
  pkgdir=$(dirname ${apkbuild})

  cd ${pkgdir}
  abuild checksum
  rm -rf src
done
