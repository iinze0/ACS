# ACS — Air Crack Station

Terminal station for **authorized** wireless lab work on Kali and Debian.

[![release](https://img.shields.io/github/v/release/iinze0/ACS?style=flat-square)](https://github.com/iinze0/ACS/releases/latest)
[![license](https://img.shields.io/badge/license-MIT-0b7285?style=flat-square)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Kali%20%7C%20Debian-2b8a3e?style=flat-square)](#install)

Made by [Pakun](https://github.com/brazyqueso) and [iinze0](https://github.com/iinze0)

ACS puts the usual wireless toolkit behind one menu: pick an interface, toggle monitor mode, scan, capture, and run the rest of the station from there. It ships as a `.deb`, appears under **Applications → ACS**, and checks GitHub for a newer package on launch.

## Family

| Repo | Role |
|:-----|:-----|
| **[ACS](https://github.com/iinze0/ACS)** | This repo — shell station |
| **[ACS-app](https://github.com/iinze0/ACS-app)** | Python desktop client |
| **[ACS-cpp](https://github.com/iinze0/ACS-cpp)** | Native C++ / GTK client |

## Install

Use `dpkg`. Installing a local `.deb` from `/tmp` with `apt` will fail.

```bash
wget -O /tmp/acs.deb https://github.com/iinze0/ACS/releases/download/v1.4.0/acs_1.4.0_all.deb
sudo dpkg -i /tmp/acs.deb
sudo ACS
```

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/iinze0/ACS/main/install-acs.sh | sudo bash
sudo ACS
```

Confirm the package:

```bash
dpkg -s acs | grep -E 'Version|Maintainer'
```

You should see **1.4.0** and **Pakun & iinze0**.

```bash
sudo apt purge acs    # uninstall
```

## Launch

```bash
sudo ACS
```

Also available from **Applications → ACS**.

- Menu option **1** installs recommended station packages.
- Option **45** checks GitHub for an update.
- Skip the auto-update check with `ACS_NO_UPDATE=1`.

## Requirements

- Kali or another Debian-based system
- Root for monitor mode and package install
- A wireless adapter that supports monitor mode
- Recommended: `aircrack-ng`, `iw`, `hashcat`, `hcxdumptool`, `hcxtools`, `proxychains4`

## Disclaimer

Authorized lab and pentest use only. Run this only on networks you own or have written permission to test.

---

<p align="center">
  <a href="https://github.com/iinze0">iinze0</a> ·
  <a href="https://github.com/brazyqueso">Pakun</a> ·
  <a href="LICENSE">MIT</a>
</p>
