#!/bin/bash
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root: sudo bash install.sh"; exit 1; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[1/4] Installing net-watchdog2.sh"
cp "$SCRIPT_DIR/net-watchdog2.sh" /usr/local/bin/net-watchdog2.sh
chmod +x /usr/local/bin/net-watchdog2.sh
echo "[2/4] Installing systemd units"
cp "$SCRIPT_DIR/net-watchdog2.service" /etc/systemd/system/
cp "$SCRIPT_DIR/net-watchdog2.timer" /etc/systemd/system/
echo "[3/4] Reloading systemd"
systemctl daemon-reload
systemctl reset-failed net-watchdog2.service 2>/dev/null || true
echo "[4/4] Enabling and starting timer"
systemctl enable net-watchdog2.timer
systemctl start net-watchdog2.timer
echo ""
echo "Installation complete."
echo "Status:    sudo systemctl status net-watchdog2.timer"
echo "Live logs: sudo journalctl -t net-watchdog2 -f"
echo "Test run:  sudo systemctl start net-watchdog2.service"
