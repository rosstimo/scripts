#!/bin/bash

# General-purpose UFW baseline with optional Syncthing policy
# Resets rules, sets deny-by-default, and allows essential traffic + LAN/VM/Docker.
# Syncthing is BLOCKED by default; you can allow it only on specific networks.

set -euo pipefail # Exit on error, undefined variable, or pipe failure

echo "You may want to do this manually first:"
echo "sudo ufw --force reset"

# continue yes or no
read -p "Do you want to continue? (y/n): " choice
if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo "Exiting Script..."
    exit 0
fi

# ---- Settings you can tweak ----
HOME_LAN_CIDR="192.168.77.0/16"   # Home network
VM_NET_CIDR="192.168.122.0/24"    # libvirt default
DOCKER_NET_CIDR="172.17.0.0/16"   # docker0 default
VPN_NET_CIDR="10.98.0.0/16"       # tun0 VPN network

ENABLE_SSH_IN=false                 # allow inbound SSH (rate-limited)
ENABLE_SSH_OUT=true                # allow outbound SSH
ENABLE_OPENVPN_OUT=false           # allow outbound OpenVPN UDP 1194

# Syncthing policy
SYNCTHING_ENABLE=true             # false blocks it everywhere; true allows only on CIDRs below
SYNCTHING_ALLOW_RELAYS=true       # relays use 22067/tcp; usually keep this false at work
SYNCTHING_ALLOWED_CIDRS=( 
  "${HOME_LAN_CIDR}" 
  "${VM_NET_CIDR}" 
  "${DOCKER_NET_CIDR}" 
  "${VPN_NET_CIDR}" 
)

# Interfaces where we want extra belt-and-suspenders blocks (will also auto-detect new ones)
WORK_IFACES=("wlp170s0" "enp0s13f0u4u4u4")
# --------------------------------

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

# Detect any new network interfaces except lo, virbr*, docker*, tun*
auto_detect_work_ifaces() {
  mapfile -t DETECTED < <(ls /sys/class/net | grep -Ev '^(lo|virbr|docker|tun)' || true)
  for IF in "${DETECTED[@]}"; do
    if [[ ! " ${WORK_IFACES[*]} " =~ " ${IF} " ]]; then
      WORK_IFACES+=("${IF}")
    fi
  done
}

syncthing_block_all() {
  echo "[syncthing] Blocking ports in/out (21027/udp discovery, 22000/tcp sync, 22067/tcp relay)"
  ufw deny in 21027/udp || true
  ufw deny in 22000/tcp || true
  ufw deny in 22067/tcp || true
  ufw deny out 21027/udp || true
  ufw deny out 22000/tcp || true
  ufw deny out 22067/tcp || true
  for IFACE in "${WORK_IFACES[@]}"; do
    ufw deny in on "$IFACE" to any port 21027 proto udp || true
    ufw deny out on "$IFACE" to any port 21027 proto udp || true
    ufw deny in on "$IFACE" to any port 22000 proto tcp || true
    ufw deny out on "$IFACE" to any port 22000 proto tcp || true
    ufw deny in on "$IFACE" to any port 22067 proto tcp || true
    ufw deny out on "$IFACE" to any port 22067 proto tcp || true
  done
}

syncthing_allow_on_cidrs() {
  echo "[syncthing] Allowing only on specified CIDRs, blocked elsewhere"
  for CIDR in "${SYNCTHING_ALLOWED_CIDRS[@]}"; do
    ufw allow from "$CIDR" to any port 22000 proto tcp
    ufw allow out to "$CIDR" port 22000 proto tcp
    ufw allow from "$CIDR" to any port 21027 proto udp
    ufw allow out to "$CIDR" port 21027 proto udp
  done
  if [[ "$SYNCTHING_ALLOW_RELAYS" == "true" ]]; then
    ufw allow out 22067/tcp
  else
    ufw deny in 22067/tcp || true
    ufw deny out 22067/tcp || true
  fi
  for IFACE in "${WORK_IFACES[@]}"; do
    ufw deny in on "$IFACE" to any port 21027 proto udp || true
    ufw deny out on "$IFACE" to any port 21027 proto udp || true
    ufw deny in on "$IFACE" to any port 22000 proto tcp || true
    ufw deny out on "$IFACE" to any port 22000 proto tcp || true
  done
}

echo "[1/9] Resetting UFW and setting defaults"
ufw --force reset
ufw default deny incoming
ufw default deny outgoing
yes | ufw enable

echo "[2/9] Auto-detecting new/unknown interfaces for belt-and-suspenders blocks"
auto_detect_work_ifaces

echo "[3/9] Allow essential outbound: DNS, HTTP/S, NTP"
ufw allow out 53
ufw allow out 80/tcp
ufw allow out 443/tcp
ufw allow out 123/udp

if [[ "${ENABLE_OPENVPN_OUT}" == "true" ]]; then
  ufw allow out 1194/udp
fi

echo "[4/9] Allow trusted LANs (in and out)"
ufw allow from "${HOME_LAN_CIDR}"
ufw allow from "${VM_NET_CIDR}"
ufw allow from "${DOCKER_NET_CIDR}"
ufw allow out to "${HOME_LAN_CIDR}"
ufw allow out to "${VM_NET_CIDR}"
ufw allow out to "${DOCKER_NET_CIDR}"
ufw allow out to "${VPN_NET_CIDR}"

echo "[5/9] Outbound printing to network printers (CUPS 631 TCP/UDP)"
ufw allow out to any port 631 proto tcp
ufw allow out to any port 631 proto udp

echo "[6/9] VM bridge traffic (virbr0)"
ufw allow in on virbr0 || true
ufw allow out on virbr0 || true

# VPN interface tun0: Allow only outbound connections and CUPS inbound if needed
ufw deny in on tun0
ufw allow out on tun0

echo "[7/9] SSH rules"
if [[ "${ENABLE_SSH_IN}" == "true" ]]; then
  ufw limit in 22/tcp
fi
if [[ "${ENABLE_SSH_OUT}" == "true" ]]; then
  ufw allow out 22/tcp
fi

echo "[8/9] Syncthing policy"
if [[ "${SYNCTHING_ENABLE}" == "true" ]]; then
  syncthing_allow_on_cidrs
else
  syncthing_block_all
fi

echo "[9/9] Final status"
ufw status verbose
echo "Done."
