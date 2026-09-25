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

## Contributors

- [iinze0](https://github.com/iinze0)
- [brazyqueso](https://github.com/brazyqueso)

## Proxy chain (v1.2.0)

Options **42–44** pull live proxy IPs from GitHub (TheSpeedX, monosans, hookzof), write `~/.acs/proxychains.conf`, test the chain, or run one command through it.

```text
42  pull proxies (socks5 / socks4 / http, hop count, dynamic|strict|random)
43  test direct IP vs chain
44  run a command through proxychains4 -f
```

## Updates

On launch, ACS checks GitHub and replaces itself when a newer `ACS_VER` is published. Option **45** checks by hand. Skip with `ACS_NO_UPDATE=1`.
