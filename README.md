# ACS — Air Crack Station

Made by **Pakun & iinze0**.

Kali menu for the full **aircrack-ng** suite: auto monitor mode, capture, inject, and crack. Authorized lab / pentest use only.

## Run

```bash
git clone https://github.com/iinze0/ACS.git
cd ACS
sudo bash acs.sh
```

## First steps

1. **1** — install the crack station (`aircrack-ng`, hashcat, hcxtools, wifite, reaver, bully, john, wordlists)
2. **2** — auto monitor mode (`rfkill` → `airmon-ng check kill` → `airmon-ng start`)
3. **4** — set BSSID / ESSID / channel
4. **26** — handshake chain, or use the individual capture / inject / crack options

## Suite covered

`airmon-ng` `airodump-ng` `aireplay-ng` `aircrack-ng` `airbase-ng` `airdecap-ng` `airdecloak-ng` `airdrop-ng` `airgraph-ng` `airolib-ng` `airserv-ng` `airtun-ng` `airventriloquist-ng` `besside-ng` `easside-ng` `tkiptun-ng` `wesside-ng` `wpaclean` `ivstools` `makeivs-ng` `packetforge-ng` `buddy-ng`

Plus station extras: hashcat, hcxdumptool, hcxtools, wifite, reaver, bully, pixiewps, john, crunch, cowpatty, mdk4.

## Notes

- Use a wireless card that supports monitor mode and injection.
- Do not run this against networks you do not own or have written permission to test.
