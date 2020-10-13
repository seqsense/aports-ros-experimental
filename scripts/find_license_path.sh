#!/bin/bash

set -e

. $1

cwd=$(pwd)

if [ $(echo "${source}" | wc -w) -ne 1 ]; then
  source=$(echo "${source}" | xargs -n1 echo | head -n1)
fi

url=${source}
if echo ${source} | grep "::" > /dev/null; then
  url=$(echo ${source} | cut -f3- -d":")
fi

echo "url: ${url}"

tmpdir=$(mktemp -d)
wget -q -O ${tmpdir}/archive ${url}
cd ${tmpdir}
tar xf archive
rm archive

if [ $(ls -1 | wc -l) -eq 1 ]; then
  cd *
fi

echo "license files:"
license="$(find * -iname "*license*")"
license+=" $(find * -iname "gpl*")"
license+=" $(find * -iname "lgpl*")"
license+=" $(find * -iname "*copying*")"
license+=" $(find * -iname "*copyright*")"
license=$(echo ${license})
echo ${license} | xargs -n1 echo "-"

if [ $(echo ${license} | wc -w) -eq 0 ]; then
  echo "license not found"
  exit 1
fi

tmpfile=$(mktemp)

echo
echo "install script:"
echo
echo
echo "	# Install license files" | tee -a ${tmpfile}
if [ $(echo ${license} | wc -w) -eq 1 ]; then
  echo "	install -Dm644 \"\$builddir\"/${license} \"\$pkgdir\"/usr/share/licenses/\$pkgname/${license}" | tee -a ${tmpfile}
else
  echo "	install -d -m 0755 \"\$pkgdir\"/usr/share/licenses/\$pkgname" | tee -a ${tmpfile}
  for l in ${license}; do
    echo "	install -m644 \"\$builddir\"/$l \"\$pkgdir\"/usr/share/licenses/\$pkgname/$l" | tee -a ${tmpfile}
  done
fi
echo
echo

sed "/^package()/,/^}$/s|^}$|\n$(cat ${tmpfile} | sed ':l; N; $!b l; s/\n/\\n/g')\n}|" \
  -i ${cwd}/$1

if echo ${subpackages:-} | grep "pkgname-doc"; then
  sed "/^pkgrel=/c pkgrel=$(expr ${pkgrel} + 1)" \
    -i ${cwd}/$1
elif [ -z "${subpackages:-}" ]; then
  sed "/^$/{i subpackages=\"\$pkgname-doc\"
      :l; n; $!b l}" \
    -i ${cwd}/$1
else
  sed "s/subpackages=\"/\0\$pkgname-doc /" \
    -i ${cwd}/$1
fi


rm -rf ${tmpdir} ${tmpfile}

echo $1
