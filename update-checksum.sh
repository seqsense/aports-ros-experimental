#!/bin/sh

set -e

echo "Updating checksum..."
find ${SRCDIR} -name APKBUILD | while read apkbuild; do
  pkgdir=$(dirname ${apkbuild})

  cd ${pkgdir}
  abuild checksum
  rm -rf ${pkgdir}/src
done
