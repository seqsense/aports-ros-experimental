#!/bin/sh

set -e

APORTSDIR_BASE=${APORTSDIR}
REPODIR_BASE=${REPODIR}

repo=${1:-backports}

if [ ! -d ${SRCDIR}/${repo} ]; then
  echo "${repo} is not present. Skipping."
  exit 0;
fi

basedir=.
if [ ${repo} != $(basename ${repo}) ]; then
  export APORTSDIR=${APORTSDIR}/$(dirname ${repo})
  export REPODIR=${REPODIR}/$(dirname ${repo})
  basedir=$(dirname ${repo})
  repo=$(basename ${repo})
fi
echo "APORTSDIR: ${APORTSDIR}"
echo "REPODIR: ${REPODIR}"
echo "target repository: ${repo}"
echo "base directory: ${basedir}"
echo

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

find ${REPODIR_BASE} -name APKINDEX.tar.gz | while read path; do
  arch_path=$(dirname ${path})
  repo_path=$(dirname ${arch_path})
  echo "${repo_path}" | sudo tee -a /etc/apk/repositories
done

cp -r ${SRCDIR}/* ${APORTSDIR_BASE}
mkdir -p ${APORTSDIR}/${repo}
mkdir -p ${REPODIR}

sudo apk update

(cd ${basedir} && buildrepo -k ${repo} -d ${REPODIR} -a ${APORTSDIR})

index=$(find ${REPODIR}/${repo} -name APKINDEX.tar.gz || true)
if [ ! -f "${index}" ]; then
  exit 1
fi
rm -f ${index}
apk index -o ${index} `find $(dirname ${index}) -name '*.apk'`
abuild-sign -k /home/builder/.abuild/*.rsa ${index}
