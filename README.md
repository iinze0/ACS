# ACS — Air Crack Station

Terminal station for authorized wireless assessment on Kali / Debian.

[![release](https://img.shields.io/github/v/release/iinze0/ACS?style=flat-square)](https://github.com/iinze0/ACS/releases/latest)
[![license](https://img.shields.io/badge/use-authorized%20lab%20only-red?style=flat-square)](#disclaimer)
Made by [Pakun](https://github.com/brazyqueso) & [iinze0](https://github.com/iinze0)

ACS wraps the usual wireless toolkit behind one menu: interface select, monitor mode, scan, capture, and related station tools. It ships as a `.deb`, lives under **Applications → ACS**, and checks GitHub for a newer package on launch.

## Family

| Repo | What you get |
|:-----|:-------------|
| **[ACS](https://github.com/iinze0/ACS)** | This repo — shell station |
| **[ACS-app](https://github.com/iinze0/ACS-app)** | Python desktop app |
| **[ACS-cpp](https://github.com/iinze0/ACS-cpp)** | Native C++ / GTK app |

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
dpkg -s acs | grep Version
```

You should see **v1.4.0** and **Made by Pakun & iinze0**.

Uninstall:

```bash
sudo apt purge acs
```

## Launch

```bash
sudo ACS
```

Also available from **Applications → ACS**.

Option **1** in the menu installs recommended station packages. Option **45** checks GitHub for an update by hand. Auto-update can be skipped with `ACS_NO_UPDATE=1`.

## Requirements

- Kali or Debian-based system
- Root for monitor mode and package install
- A wireless adapter that supports monitor mode
- Recommended: `aircrack-ng`, `iw`, `hashcat`, `hcxdumptool`, `hcxtools`, `proxychains4`

## Disclaimer

Authorized lab and pentest use only. Only run this on networks you own or have written permission to test.

<p align="center">
  <a href="https://github.com/iinze0">iinze0</a> ·
  <a href="https://github.com/brazyqueso">Pakun</a> ·
  <a href="https://github.com/iinze0/ACS">ACS</a>
</p>
