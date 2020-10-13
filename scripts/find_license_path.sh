#!/bin/bash

set -e

. $1

if [ $(echo "${source}" | wc -w) -ne 1 ]; then
  source=$(echo "${source}" | xargs -n1 echo | head -n1)
fi

url=${source}
if echo ${source} | grep "::" > /dev/null; then
  url=$(echo ${source} | cut -f3 -d":")
fi

echo "url: ${url}"

tmpdir=$(mktemp -d)
wget -q -O ${tmpdir}/archive ${url}
cd ${tmpdir}
tar xf archive

echo "license files:"
find . -iname "*license*"
find . -iname "*gpl*"
find . -iname "*copying*"
find . -iname "*copyright*"
