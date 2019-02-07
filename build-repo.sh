#!/bin/sh

set -e

repo=${1:-backports}

if [ ! -f ${PACKAGER_PRIVKEY} ]; then
  abuild-keygen -a -i -n

  # Re-sign packages if private key is updated
  index=$(find ${REPODIR} -name APKINDEX.tar.gz || true)
  if [ -f "${index}" ]; then
    rm -f ${index}
    apk index -o ${index} `find $(dirname ${index}) -name '*.apk'`
    abuild-sign -k /home/builder/.abuild/*.rsa ${index}
  fi
fi

echo "${REPODIR}/${repo}" | sudo tee -a /etc/apk/repositories

cp -r ${SRCDIR}/* ${APORTSDIR}
mkdir -p ${APORTSDIR}/${repo}
mkdir -p ${REPODIR}

sudo apk update

buildrepo -k ${repo}

index=$(find ${REPODIR} -name APKINDEX.tar.gz || true)
if [ ! -f "${index}" ]; then
  exit 1
fi
rm -f ${index}
apk index -o ${index} `find $(dirname ${index}) -name '*.apk'`
abuild-sign -k /home/builder/.abuild/*.rsa ${index}
