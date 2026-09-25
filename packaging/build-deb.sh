#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="$(tr -d '[:space:]' < "$ROOT/VERSION")"
PKG="/tmp/acs-deb-build/acs_${VER}_all"
rm -rf /tmp/acs-deb-build
mkdir -p "$PKG/DEBIAN" "$PKG/usr/bin" "$PKG/usr/lib/acs" \
  "$PKG/usr/share/applications" "$PKG/usr/share/pixmaps" \
  "$PKG/usr/share/doc/acs" "$PKG/var/lib/acs"
install -m 0755 "$ROOT/ACS.sh" "$PKG/usr/lib/acs/ACS.sh"
install -m 0644 "$ROOT/acs.svg" "$PKG/usr/share/pixmaps/acs.svg"
ln -sf acs.svg "$PKG/usr/share/pixmaps/ACS.svg"
printf '%s\n' '#!/usr/bin/env bash' 'exec /usr/lib/acs/ACS.sh "$@"' > "$PKG/usr/bin/ACS"
chmod 0755 "$PKG/usr/bin/ACS"
ln -sf ACS "$PKG/usr/bin/acs"
cat > "$PKG/usr/share/applications/acs.desktop" << 'EOF'
[Desktop Entry]
Name=ACS
GenericName=Air Crack Station
Comment=ACS — Kali pentest menu. Made by Pakun & iinze0.
Exec=x-terminal-emulator -e sudo ACS
Icon=acs
Terminal=false
Type=Application
Categories=System;Security;Network;
Keywords=acs;kali;aircrack;pentest;pakun;iinze0;
EOF
cat > "$PKG/usr/share/doc/acs/copyright" << EOF
ACS — Air Crack Station
Made by Pakun & iinze0
https://github.com/iinze0/ACS
EOF
sed "s/^Version:.*/Version: ${VER}/" "$ROOT/packaging/DEBIAN/control" > "$PKG/DEBIAN/control"
install -m 0755 "$ROOT/packaging/DEBIAN/postinst" "$PKG/DEBIAN/postinst"
install -m 0755 "$ROOT/packaging/DEBIAN/prerm" "$PKG/DEBIAN/prerm"
install -m 0755 "$ROOT/packaging/DEBIAN/postrm" "$PKG/DEBIAN/postrm"
SIZE="$(du -sk "$PKG" | awk '{print $1}')"
sed -i "s/^Installed-Size:.*/Installed-Size: ${SIZE}/" "$PKG/DEBIAN/control"
mkdir -p "$ROOT/apt"
dpkg-deb --root-owner-group --build "$PKG" "$ROOT/apt/acs_${VER}_all.deb"
cp -f "$ROOT/apt/acs_${VER}_all.deb" "$ROOT/acs_${VER}_all.deb"
(
  cd "$ROOT/apt"
  dpkg-scanpackages -m . /dev/null > Packages
  gzip -9c Packages > Packages.gz
  cat > Release << EOF
Origin: ACS
Label: ACS
Suite: stable
Codename: stable
Architectures: all
Components: main
Description: ACS — Air Crack Station
EOF
)
echo "built $ROOT/apt/acs_${VER}_all.deb"
