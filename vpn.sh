#!/bin/bash

# === DYNAMIC USERNAME ===
USERNAME="${SUDO_USER:-$USER}"

# === LOG FILE ===
LOGFILE="/var/log/cyberghost.log"

# === SYSTEM OPTIMIZATIONS FOR LOW LATENCY ===
echo "Applying system optimizations for low latency..."
sudo sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1
sudo sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1
sudo sysctl -w net.ipv4.tcp_rmem="4096 65536 16777216" >/dev/null 2>&1
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" >/dev/null 2>&1
sudo sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
sudo sysctl -w net.ipv4.tcp_window_scaling=1 >/dev/null 2>&1

# Set CPU governor to performance if available
if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1
fi

# === STOP EXISTING VPN SERVICES ===
echo "Stopping any existing CyberGhost VPN services..."
sudo cyberghostvpn --stop >/dev/null 2>&1

# === GET BEST SERVER BY LOWEST LOAD ===
echo "Searching for server with lowest load (%)..."

BEST_SERVER=$(cyberghostvpn --traffic --country-code US --city "Chicago" 2>/dev/null \
              | grep -E "^\|[[:space:]]+[0-9]+" \
              | awk -F'|' '
              {
                  gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4);  # limpa servidor
                  gsub(/^[[:space:]]+|[[:space:]]+$/, "", $5);  # limpa load
                  gsub(/%/, "", $5);                           # remove %
                  if($4 != "" && $5 != "" && $5 ~ /^[0-9]+$/) {
                      print $4, $5
                  }
              }' \
              | sort -k2n \
              | head -n1)

if [[ -n "$BEST_SERVER" ]]; then
    SERVER_NAME=$(echo "$BEST_SERVER" | awk '{print $1}')
    SERVER_LOAD=$(echo "$BEST_SERVER" | awk '{print $2}')
    FULL_SERVER="${SERVER_NAME}.cg-dialup.net"
    echo "✅ Best server: $FULL_SERVER (${SERVER_LOAD}% load)"
else
    echo "❌ Error: Could not find server"
    exit 1
fi

# === CONNECT VIA OPENVPN WITH LOW-LATENCY SETTINGS ===
echo "Connecting with optimized low-latency settings..."

sudo openvpn \
  --dev tun \
  --auth-user-pass /home/$USERNAME/.cyberghost/openvpn/auth \
  --client \
  --proto udp\
  --resolv-retry infinite \
  --persist-key \
  --persist-tun \
  --nobind \
  --cipher AES-128-GCM \
  --auth SHA1 \
  --ping 10 \
  --ping-restart 30 \
  --explicit-exit-notify 2 \
  --script-security 2 \
  --remote-cert-tls server \
  --verb 1 \
  --route-delay 5 \
  --mute-replay-warnings \
  --fast-io \
  --sndbuf 0 \
  --rcvbuf 0 \
  --remote $FULL_SERVER 443 \
  --log $LOGFILE \
  --daemon \
  --dhcp-option DOMAIN-ROUTE . \
  --up /usr/local/cyberghost/update-systemd-resolved \
  --up-restart \
  --down /usr/local/cyberghost/update-systemd-resolved \
  --down-pre \
  --ca /usr/local/cyberghost/certs/openvpn/ca.crt \
  --cert /usr/local/cyberghost/certs/openvpn/client.crt \
  --key /usr/local/cyberghost/certs/openvpn/client.key

# === POST-CONNECTION VERIFICATION ===
echo "Waiting for connection to establish..."
sleep 8

echo "=== VPN STATUS ==="
if ip addr show tun0 >/dev/null 2>&1; then
    echo "✅ VPN interface active"
    TUN_IP=$(ip addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    echo "   VPN IP: $TUN_IP"
else
    echo "❌ VPN interface not found"
fi

echo "=== LATENCY TEST ==="
FINAL_LATENCY=$(ping -c 5 -W 2 8.8.8.8 2>/dev/null | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
if [[ -n "$FINAL_LATENCY" ]]; then
    echo "✅ Current latency to Google DNS: ${FINAL_LATENCY}ms"
else
    echo "❌ Could not test latency"
fi

echo "=== PUBLIC IP CHECK ==="
PUBLIC_IP=$(curl -s --max-time 10 https://api.ipify.org)
if [[ -n "$PUBLIC_IP" ]]; then
    echo "✅ Public IP: $PUBLIC_IP"
else
    echo "❌ Could not retrieve public IP"
fi

echo "🎯 Low-latency VPN connection complete!"