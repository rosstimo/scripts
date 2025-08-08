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
HOME_LAN_CIDR="192.168.0.0/16"
VM_NET_CIDR="192.168.122.0/24"   # libvirt default
DOCKER_NET_CIDR="172.17.0.0/16"  # docker0 default

ENABLE_SSH_IN=true                # allow inbound SSH (rate-limited)
ENABLE_SSH_OUT=true               # allow outbound SSH
ENABLE_OPENVPN_OUT=false          # allow outbound OpenVPN UDP 1194

# Syncthing policy
SYNCTHING_ENABLE=false            # false blocks it everywhere; true allows only on CIDRs below
SYNCTHING_ALLOW_RELAYS=false      # relays use 22067/tcp; usually keep this false at work
SYNCTHING_ALLOWED_CIDRS=( 
  "${HOME_LAN_CIDR}" 
  "${VM_NET_CIDR}" 
  "${DOCKER_NET_CIDR}" 
)
# Interfaces where we want extra belt-and-suspenders blocks (eg. campus Wi-Fi, USB NIC at work)
WORK_IFACES=("wlp170s0" "enp0s13f0u2u4u4")
# --------------------------------

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

syncthing_block_all() {
  echo "[syncthing] Blocking ports in/out (21027/udp discovery, 22000/tcp sync, 22067/tcp relay)"
  ufw deny in 21027/udp || true
  ufw deny in 22000/tcp || true
  ufw deny in 22067/tcp || true
  ufw deny out 21027/udp || true
  ufw deny out 22000/tcp || true
  ufw deny out 22067/tcp || true
  # Extra interface-level blocks to avoid accidental leaks on work nets
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
    # Sync traffic
    ufw allow from "$CIDR" to any port 22000 proto tcp
    ufw allow out to "$CIDR" port 22000 proto tcp
    # Local discovery
    ufw allow from "$CIDR" to any port 21027 proto udp
    ufw allow out to "$CIDR" port 21027 proto udp
  done
  if [[ "$SYNCTHING_ALLOW_RELAYS" == "true" ]]; then
    echo "[syncthing] Allowing relays (22067/tcp) OUT only"
    ufw allow out 22067/tcp
  else
    ufw deny in 22067/tcp || true
    ufw deny out 22067/tcp || true
  fi
  # Still add interface-level denies on work nets to be explicit
  for IFACE in "${WORK_IFACES[@]}"; do
    ufw deny in on "$IFACE" to any port 21027 proto udp || true
    ufw deny out on "$IFACE" to any port 21027 proto udp || true
    ufw deny in on "$IFACE" to any port 22000 proto tcp || true
    ufw deny out on "$IFACE" to any port 22000 proto tcp || true
  done
}

echo "[1/8] Resetting UFW and setting defaults"
ufw --force reset
ufw default deny incoming
ufw default deny outgoing
# Enable now so interface rules apply correctly
yes | ufw enable

echo "[2/8] Allow essential outbound: DNS, HTTP/S, NTP"
ufw allow out 53
ufw allow out 80/tcp
ufw allow out 443/tcp
ufw allow out 123/udp

if [[ "${ENABLE_OPENVPN_OUT}" == "true" ]]; then
  echo "[opt] Allow outbound OpenVPN"
  ufw allow out 1194/udp
fi

echo "[3/8] Allow trusted LANs (in and out)"
ufw allow from "${HOME_LAN_CIDR}"
ufw allow from "${VM_NET_CIDR}"
ufw allow from "${DOCKER_NET_CIDR}"
ufw allow out to "${HOME_LAN_CIDR}"
ufw allow out to "${VM_NET_CIDR}"
ufw allow out to "${DOCKER_NET_CIDR}"

echo "[4/8] Printing on LAN (CUPS 631 TCP/UDP)"
ufw allow from "${HOME_LAN_CIDR}" to any port 631 proto tcp
ufw allow from "${HOME_LAN_CIDR}" to any port 631 proto udp

echo "[5/8] VM bridge traffic (virbr0)"
# If virbr0 does not exist, these will be harmless
ufw allow in on virbr0 || true
ufw allow out on virbr0 || true

echo "[6/8] SSH rules"
if [[ "${ENABLE_SSH_IN}" == "true" ]]; then
  ufw limit in 22/tcp
fi
if [[ "${ENABLE_SSH_OUT}" == "true" ]]; then
  ufw allow out 22/tcp
fi

echo "[7/8] Syncthing policy"
if [[ "${SYNCTHING_ENABLE}" == "true" ]]; then
  syncthing_allow_on_cidrs
else
  syncthing_block_all
fi

echo "[8/8] Final status"
ufw status verbose
echo "Done."

