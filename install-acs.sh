#!/usr/bin/env bash
# ACS installer — Made by Pakun & iinze0
set -euo pipefail
VER="${ACS_VER:-1.4.0}"
URL="https://github.com/iinze0/ACS/releases/download/v${VER}/acs_${VER}_all.deb"
DEB="/tmp/acs_${VER}_all.deb"

echo "[*] ACS v${VER} installer — Made by Pakun & iinze0"
echo "[*] $URL"

if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 3 -o "$DEB" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$DEB" "$URL"
else
  echo "[!] need curl or wget"; exit 1
fi

if ! dpkg-deb -I "$DEB" >/dev/null 2>&1; then
  echo "[!] download is not a Debian package (GitHub HTML?)"
  head -c 180 "$DEB"; echo
  exit 1
fi

echo "[*] installing with dpkg (avoids apt /tmp sandbox errors)"
if [[ ${EUID} -ne 0 ]]; then
  sudo dpkg -i "$DEB"
else
  dpkg -i "$DEB"
fi

echo
echo "[+] $(dpkg-query -W -f='${Package} ${Version}' acs 2>/dev/null || echo acs missing)"
echo "    run:  sudo ACS"
