#!/bin/bash

# General-purpose UFW baseline with optional Syncthing policy
# Resets rules, sets deny-by-default, and allows essential traffic + LAN/VM/Docker.
# Syncthing is BLOCKED by default; you can allow it only on specific networks.

set -euo pipefail # Exit on error, undefined variable, or pipe failure

HOME_LAN="192.168.0.0/16"   # Home network

ufw disable &&
ufw --force reset &&
# deny all in, allow all out, log all in at medium
ufw default deny incoming &&
# ufw default allow outgoing &&
ufw default deny outgoing &&

ufw allow from $HOME_LAN to any port 8188 &&
# allow out dns and web

ufw allow out 22 &&
ufw allow out 53 &&
ufw allow out 853 &&
ufw allow out 5353/udp &&
ufw allow out 80/tcp &&
ufw allow out 443 &&
ufw allow out 631/tcp &&
ufw allow out 161/udp &&
ufw allow out 123/udp &&
ufw allow out 9100/tcp &&
ufw allow out 9101/tcp &&
ufw allow out 9102/tcp &&
ufw allow out 8188 &&

# deny all syncthing explicitly
ufw deny out 21027 &&
ufw deny out 22000 &&
ufw deny out 22067 &&

# allow syncthing on home LAN
ufw allow in from $HOME_LAN to any port 21027 &&
ufw allow in from $HOME_LAN to any port 22000 &&
ufw allow in from $HOME_LAN to any port 22067 &&


# # allow syncthing out on vpn interface
ufw allow out on tun0 to any port 21027 &&
ufw allow out on tun0 to any port 22000 &&
ufw allow out on tun0 to any port 22067 &&

# # deny all ipv6
# ufw deny in from ::/0 &&
# ufw deny out to ::/0 &&

ufw logging low &&
ufw logging on &&
ufw enable
