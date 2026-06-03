# Network Watchdog v3

Self-healing network watchdog for Raspberry Pi / Linux. Runs every 60 seconds and automatically reconnects the WiFi interface if connectivity is lost — critical for remotely managed servers.

## Quick Start

```bash
git clone https://github.com/Glory-2-Ukraine/Network-Watchdog.git
cd Network-Watchdog
sudo bash install.sh
```

## How It Works

Three checks run in order each minute:

| Check | What it does |
|-------|-------------|
| 1 — Interface state | Confirms the interface is UP |
| 2 — Gateway ping | Pings the router through the interface |
| 3 — External TCP | Connects to 8.8.8.8:53 — skipped under high CPU load |

If any check fails, NetworkManager reconnects the interface and a cooldown prevents thrashing.

## Configuration

Edit `/etc/systemd/system/net-watchdog2.service`:

```
Environment=IFACE=wlan0       # interface to monitor
Environment=COOLDOWN_S=180    # seconds between recovery attempts
```

Then: `sudo systemctl daemon-reload && sudo systemctl restart net-watchdog2.timer`

## Useful Commands

| Action | Command |
|--------|---------|
| Check timer | `sudo systemctl status net-watchdog2.timer` |
| Live logs | `sudo journalctl -t net-watchdog2 -f` |
| Test run now | `sudo systemctl start net-watchdog2.service` |
| Clear cooldown | `sudo rm -f /tmp/net-watchdog2.cooldown` |

---
*Part of the [Glory-2-Ukraine](https://github.com/Glory-2-Ukraine) infrastructure toolkit.*
