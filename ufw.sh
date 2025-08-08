#!/bin/bash

echo "You may want to do this manually first:"
echo "sudo ufw --force reset"

# continue yes or no
read -p "Do you want to continue? (y/n): " choice
if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo "Exiting Script..."
    exit 0
fi

echo "Setting up UFW rules..."
# add rules exit on fail


#!/usr/bin/env bash
# General-purpose UFW baseline
# Resets rules, sets deny-by-default, and allows essential traffic + LAN/VM/Docker.

set -euo pipefail

# ---- Settings you can tweak ----
HOME_LAN_CIDR="192.168.0.0/16"
VM_NET_CIDR="192.168.122.0/24"   # libvirt default
DOCKER_NET_CIDR="172.17.0.0/16"  # docker0 default

ENABLE_SSH_IN=true               # allow inbound SSH (rate-limited)
ENABLE_SSH_OUT=true              # allow outbound SSH
ENABLE_OPENVPN_OUT=false         # allow outbound OpenVPN UDP 1194
# --------------------------------

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

echo "[1/7] Resetting UFW and setting defaults"
ufw --force reset
ufw default deny incoming
ufw default deny outgoing
# Enable now so interface rules apply correctly
yes | ufw enable

echo "[2/7] Allow essential outbound: DNS, HTTP/S, NTP"
ufw allow out 53
ufw allow out 80/tcp
ufw allow out 443/tcp
ufw allow out 123/udp

if [[ "${ENABLE_OPENVPN_OUT}" == "true" ]]; then
  echo "[opt] Allow outbound OpenVPN"
  ufw allow out 1194/udp
fi

echo "[3/7] Allow trusted LANs (in and out)"
ufw allow from "${HOME_LAN_CIDR}"
ufw allow from "${VM_NET_CIDR}"
ufw allow from "${DOCKER_NET_CIDR}"
ufw allow out to "${HOME_LAN_CIDR}"
ufw allow out to "${VM_NET_CIDR}"
ufw allow out to "${DOCKER_NET_CIDR}"

echo "[4/7] Printing on LAN (CUPS 631 TCP/UDP)"
ufw allow from "${HOME_LAN_CIDR}" to any port 631 proto tcp
ufw allow from "${HOME_LAN_CIDR}" to any port 631 proto udp

echo "[5/7] VM bridge traffic (virbr0)"
# If virbr0 does not exist, these will be harmless
ufw allow in on virbr0
ufw allow out on virbr0

echo "[6/7] SSH rules"
if [[ "${ENABLE_SSH_IN}" == "true" ]]; then
  ufw limit in 22/tcp
fi
if [[ "${ENABLE_SSH_OUT}" == "true" ]]; then
  ufw allow out 22/tcp
fi

# ---- Optional: block Syncthing completely (leave commented for general-purpose) ----
# echo "[opt] Blocking Syncthing ports in/out (21027/udp, 22000/tcp, 22067/tcp)"
# ufw deny in 21027/udp
# ufw deny in 22000/tcp
# ufw deny in 22067/tcp
# ufw deny out 21027/udp
# ufw deny out 22000/tcp
# ufw deny out 22067/tcp
# ------------------------------------------------------------------------------------

echo "[7/7] Final status"
ufw status verbose
echo "Done."
