#!/usr/bin/env bash
# ACS — Made by Pakun & iinze0
# Adds a local apt source, then:  sudo apt install acs
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run:  sudo bash install.sh"
  echo "Then: sudo apt install acs"
  echo "Then: sudo ACS"
  exit 1
fi

src_dir=""
if [[ -n ${BASH_SOURCE[0]:-} && ${BASH_SOURCE[0]} != bash && ${BASH_SOURCE[0]} != - ]]; then
  src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
fi
[[ -n ${src_dir:-} ]] || { echo "Could not find installer directory"; exit 1; }

VER="$(tr -d '[:space:]' < "$src_dir/VERSION")"
APTDIR="$src_dir/apt"
DEB="$APTDIR/acs_${VER}_all.deb"
[[ -f $DEB ]] || { echo "Missing $DEB — clone the full repo"; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq || true
apt-get install -y curl ca-certificates dpkg-dev 2>/dev/null || apt-get install -y curl ca-certificates || true

mkdir -p /usr/local/share/acs-apt
cp -a "$APTDIR/." /usr/local/share/acs-apt/
(
  cd /usr/local/share/acs-apt
  if command -v dpkg-scanpackages >/dev/null; then
    dpkg-scanpackages -m . /dev/null > Packages 2>/dev/null || true
    gzip -9c Packages > Packages.gz 2>/dev/null || true
  fi
)

cat >/etc/apt/sources.list.d/acs.list << 'LIST'
deb [trusted=yes] file:/usr/local/share/acs-apt ./
LIST

apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/acs.list -o Dir::Etc::sourceparts=- -o APT::Get::List-Cleanup=0
apt-get install -y acs

echo
echo "ACS installed via apt. Made by Pakun & iinze0"
echo "  sudo ACS"
echo "  sudo apt remove acs"
echo "  sudo apt purge acs"
