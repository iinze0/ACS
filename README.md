# ACS — Air Crack Station

**Made by Pakun & iinze0**

Page: [iinze0.github.io/ACS](https://iinze0.github.io/ACS/)

## Install (use dpkg — apt /tmp will fail)

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

You should see **v1.4.0** and **Made by Pakun & iinze0**.

```bash
dpkg -s acs | grep Version
```

Uninstall: `sudo apt purge acs`

## Launch

```bash
sudo ACS
```

Also: **Applications → ACS**

Authorized lab / pentest use only. On launch, ACS checks GitHub and installs a newer package by itself. Option **45** checks by hand.

```
github.com/iinze0
github.com/iinze0/ACS
```
