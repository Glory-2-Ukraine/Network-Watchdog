#!/bin/bash
# =============================================================================
# net-watchdog2.sh — Network watchdog v3
# GW neighbor check + external TCP check; congestion-aware
# Configured via environment in net-watchdog2.service:
#   IFACE      — interface to monitor (default: wlan0)
#   COOLDOWN_S — seconds between recovery attempts (default: 180)
# =============================================================================
IFACE="${IFACE:-wlan0}"
COOLDOWN_S="${COOLDOWN_S:-180}"
COOLDOWN_FILE="/tmp/net-watchdog2.cooldown"
LOG_TAG="net-watchdog2"
log() { logger -t "$LOG_TAG" "$*"; }

# Cooldown check
if [[ -f "$COOLDOWN_FILE" ]]; then
    last=$(cat "$COOLDOWN_FILE"); now=$(date +%s); elapsed=$(( now - last ))
    if [[ $elapsed -lt $COOLDOWN_S ]]; then
        log "Cooldown active (${elapsed}s < ${COOLDOWN_S}s), skipping."; exit 0
    fi
fi

# Check 1: Interface state
if ! ip link show "$IFACE" 2>/dev/null | grep -q "state UP"; then
    log "FAIL: $IFACE is not UP. Triggering reconnect."
    date +%s > "$COOLDOWN_FILE"
    nmcli device connect "$IFACE" 2>/dev/null || true; exit 1
fi

# Check 2: Gateway reachability
GW=$(ip route show default dev "$IFACE" 2>/dev/null | awk '{print $3}' | head -1)
if [[ -z "$GW" ]]; then
    log "FAIL: No default gateway on $IFACE. Triggering reconnect."
    date +%s > "$COOLDOWN_FILE"
    nmcli device connect "$IFACE" 2>/dev/null || true; exit 1
fi
if ! ping -c 2 -W 3 -I "$IFACE" "$GW" &>/dev/null; then
    log "FAIL: Gateway $GW unreachable on $IFACE. Triggering reconnect."
    date +%s > "$COOLDOWN_FILE"
    nmcli device connect "$IFACE" 2>/dev/null || true; exit 1
fi

# Check 3: External TCP (congestion-aware)
LOAD=$(awk '{print $1}' /proc/loadavg | cut -d. -f1)
CPU_COUNT=$(nproc)
if [[ $LOAD -ge $CPU_COUNT ]]; then
    log "Load ${LOAD} >= ${CPU_COUNT} CPUs — skipping external check (congestion)."; exit 0
fi
if ! timeout 5 bash -c "echo >/dev/tcp/8.8.8.8/53" 2>/dev/null; then
    log "FAIL: External TCP check failed. Triggering reconnect on $IFACE."
    date +%s > "$COOLDOWN_FILE"
    nmcli device connect "$IFACE" 2>/dev/null || true; exit 1
fi

log "OK: $IFACE gateway=$GW external TCP=pass"
exit 0
