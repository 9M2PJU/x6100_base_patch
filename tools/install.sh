#!/usr/bin/env bash
# X6100 BASE firmware installer (Linux / macOS)
# Copies a .xgf file to the radio via SCP, then prints on-radio steps.
set -euo pipefail

REPO="9M2PJU/x6100_base_patch"
FALLBACK_REPO="gdyuldin/x6100_base_patch"
DEST_DIR="/usr/firmware"
USER="root"
PORT="22"
IP=""
FILE=""
YES=0

progress() { # progress <current> <total> <label>
  local cur=$1 total=$2 label=$3 width=20
  local filled=$(( cur * width / total ))
  local empty=$(( width - filled ))
  printf '\r[%s%s] %s/%s %s' \
    "$(printf '#%.0s' $(seq 1 $filled 2>/dev/null || echo))" \
    "$(printf -- '-%.0s' $(seq 1 $empty 2>/dev/null || echo))" \
    "$cur" "$total" "$label"
  [ "$cur" -eq "$total" ] && printf '\n'
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -i, --ip IP        Radio IP on your WiFi (see radio: WiFi settings)
  -f, --file PATH    Local .xgf firmware file (default: newest in firmwares/)
  -u, --user USER    SSH user (default: root)
  -P, --port PORT    SSH port (default: 22)
  -d, --dest DIR     Remote dir (default: /usr/firmware)
  -y, --yes          Skip confirmation
  -h, --help         Show this help

Examples:
  $(basename "$0") --ip 192.168.1.100
  $(basename "$0") --ip 192.168.1.100 --file firmwares/X6100_BBFW_V1.1.6_230307001_r9.xgf

After upload, on the radio: System settings -> Firmware upgrade -> pick file.
Radio SSH defaults: user 'root', password '123'. Change it if you changed it.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -i|--ip) IP="${2:-}"; shift 2;;
    -f|--file) FILE="${2:-}"; shift 2;;
    -u|--user) USER="${2:-}"; shift 2;;
    -P|--port) PORT="${2:-}"; shift 2;;
    -d|--dest) DEST_DIR="${2:-}"; shift 2;;
    -y|--yes) YES=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

command -v scp >/dev/null || { echo "ERROR: 'scp' (OpenSSH) not found. Install openssh-client."; exit 1; }
command -v ssh >/dev/null || { echo "ERROR: 'ssh' not found. Install openssh-client."; exit 1; }

# [####------] 1/4 locate firmware
progress 1 4 "locating firmware"

if [ -z "$FILE" ]; then
  # newest .xgf next to repo
  SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  latest="$(ls -t "$SCRIPT_DIR"/firmwares/*.xgf 2>/dev/null | head -1 || true)"
  if [ -n "$latest" ]; then
    FILE="$latest"
  else
    echo ""
    echo "No local .xgf found in firmwares/. Downloading latest release..."
    command -v curl >/dev/null || { echo "ERROR: need 'curl' or pass --file PATH"; exit 1; }
    TMP="$(mktemp -d)"
    for r in "$REPO" "$FALLBACK_REPO"; do
      url="$(curl -fsSL "https://api.github.com/repos/$r/releases/latest" | grep -o 'https://[^"]*\.xgf' | head -1 || true)"
      if [ -n "$url" ]; then
        echo "Downloading: $url"
        curl -fL -o "$TMP/$(basename "$url")" "$url" && FILE="$TMP/$(basename "$url")" && break
      fi
    done
    [ -n "$FILE" ] || { echo "ERROR: download failed. Pass --file PATH manually."; exit 1; }
  fi
fi

[ -f "$FILE" ] || { echo "ERROR: file not found: $FILE"; exit 1; }
case "$FILE" in *.xgf) ;; *) echo "WARNING: $FILE does not end in .xgf - continuing anyway.";; esac

if [ -z "$IP" ]; then
  echo ""
  echo "Radio IP (find it on the radio under WiFi settings, e.g. 192.168.1.100):"
  printf "> "
  read -r IP
fi
[ -n "$IP" ] || { echo "ERROR: no IP given."; exit 1; }

FNAME="$(basename "$FILE")"
echo ""
echo "Radio:   $USER@$IP:$PORT"
echo "File:    $FILE"
echo "Dest:    $DEST_DIR/$FNAME"
if [ "$YES" -ne 1 ]; then
  printf "Upload? [Y/n] "
  read -r ans
  case "$ans" in [nN]*) echo "Aborted."; exit 0;; esac
fi

# [####------] 2/4 connectivity check
progress 2 4 "checking SSH"
if ! ssh -p "$PORT" -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "$USER@$IP" "mkdir -p $DEST_DIR && ls -ld $DEST_DIR" ; then
  echo "ERROR: cannot SSH to $USER@$IP. Checks:"
  echo "  - radio and PC on same WiFi, radio booted WITHOUT SD card (OEM fw)"
  echo "  - IP correct (radio WiFi settings screen)"
  echo "  - password is '123' unless you changed it (you will be prompted)"
  exit 1
fi

# [####------] 3/4 upload
progress 3 4 "uploading via SCP"
scp -P "$PORT" "$FILE" "$USER@$IP:$DEST_DIR/$FNAME"

# [####------] 4/4 verify
progress 4 4 "verifying"
ssh -p "$PORT" "$USER@$IP" "ls -lh $DEST_DIR/$FNAME"

cat <<EOF

Done. Now on the radio:
  1. Connect external power supply (do NOT run on battery for flashing).
  2. System settings -> Firmware upgrade -> choose $FNAME -> Update.
  3. Reboot, then check System info: BASE version should end in rX (e.g. r13).
  4. If TX power is off, calibrate: see README "TX calibration" section.

If the radio does not list the file, confirm it landed in $DEST_DIR (not /root).
EOF
