#!/bin/bash

set -eu

for apkbuild in $@; do
  pkgrel="$(
    set +eu
    . ${apkbuild}
    echo ${pkgrel}
  )"
  if [ -z ${pkgrel} ]; then
    echo "${apkbuild}: failed to read pkgrel" >&2
    continue
  fi
  pkgrel=$((${pkgrel} + 1))
  sed "s/^pkgrel=.*$/pkgrel=${pkgrel}/" -i ${apkbuild}
done
