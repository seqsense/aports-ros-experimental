#!/bin/sh

set -e

ALPINE_VERSION=${ALPINE_VERSION:-$(cat /etc/alpine-release | cut -d. -f1-2)}


# Register local repositories

touch /local_pkgs
find /packages -name APKINDEX.tar.gz | while read path; do
  arch_path=$(dirname ${path})
  repo_path=$(dirname ${arch_path})
  echo "${repo_path}" | tee -a /etc/apk/repositories

  tmpdir=$(mktemp -d)
  (cd ${tmpdir} && tar xzfv ${path})
  cat ${tmpdir}/APKINDEX | sed -n "/^P:/s/^P://p" >> /local_pkgs
  rm -rf ${tmpdir}
done

apk update

echo
echo "Installing all local packages"
exec apk add --force-overwrite $(cat /local_pkgs)
