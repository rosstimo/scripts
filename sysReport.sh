#!/usr/bin/env bash
# sheila_sysreport.sh — Full system report w/ recommendations
# Save, chmod +x, run as root for max info

OUT=system_report_$(hostname)_$(date +%F).md

echo "# 🖤 Comprehensive Linux System Report: $(hostname)" > "$OUT"
echo "_Generated: $(date)_  " >> "$OUT"

# 1. System Identity
echo -e "\n## 1. System Identity & Uptime" >> "$OUT"
hostnamectl >> "$OUT"
echo -e "\n**Uptime:**" >> "$OUT"
uptime >> "$OUT"
timedatectl >> "$OUT"

# 2. Users & Access
echo -e "\n## 2. User Accounts & Access" >> "$OUT"
echo -e "\n**Logged-in users:**" >> "$OUT"
w >> "$OUT"
echo -e "\n**All users:**" >> "$OUT"
cut -d: -f1 /etc/passwd >> "$OUT"
echo -e "\n**Sudoers:**" >> "$OUT"
sudo cat /etc/sudoers >> "$OUT" 2>/dev/null
sudo ls /etc/sudoers.d/ >> "$OUT" 2>/dev/null
echo -e "\n**Recent logins:**" >> "$OUT"
last -a | head -10 >> "$OUT"
lastb | head -10 >> "$OUT" 2>/dev/null

# 3. Hardware Inventory
echo -e "\n## 3. Hardware Inventory" >> "$OUT"
echo -e "\n**CPU:**" >> "$OUT"
lscpu >> "$OUT"
echo -e "\n**RAM:**" >> "$OUT"
free -h >> "$OUT"
sudo dmidecode -t memory >> "$OUT" 2>/dev/null
echo -e "\n**Disks:**" >> "$OUT"
lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE >> "$OUT"
sudo fdisk -l >> "$OUT" 2>/dev/null
echo -e "\n**SMART status:**" >> "$OUT"
for d in /dev/sd?; do sudo smartctl -a $d >> "$OUT" 2>/dev/null; done
echo -e "\n**Motherboard & BIOS:**" >> "$OUT"
sudo dmidecode -t baseboard >> "$OUT" 2>/dev/null
sudo dmidecode -t bios >> "$OUT" 2>/dev/null
echo -e "\n**PCI Devices:**" >> "$OUT"
lspci -nnk >> "$OUT"
echo -e "\n**USB Devices:**" >> "$OUT"
lsusb >> "$OUT"

# 4. Storage & FS
echo -e "\n## 4. Storage & Filesystems" >> "$OUT"
df -hT >> "$OUT"
echo -e "\n**Largest directories:**" >> "$OUT"
du -hxd1 / | sort -hr | head -10 >> "$OUT"
echo -e "\n**fstab:**" >> "$OUT"
cat /etc/fstab >> "$OUT"
echo -e "\n**LVM/RAID:**" >> "$OUT"
sudo lvdisplay >> "$OUT" 2>/dev/null
cat /proc/mdstat >> "$OUT"
echo -e "\n**Encrypted Volumes:**" >> "$OUT"
sudo cryptsetup status $(ls /dev/mapper/* 2>/dev/null | awk -F/ '{print $NF}') >> "$OUT" 2>/dev/null

# 5. Network
echo -e "\n## 5. Network Configuration" >> "$OUT"
ip a >> "$OUT"
ip r >> "$OUT"
echo -e "\n**DNS:**" >> "$OUT"
systemd-resolve --status >> "$OUT" 2>/dev/null
cat /etc/resolv.conf >> "$OUT"
echo -e "\n**Firewall:**" >> "$OUT"
sudo ufw status verbose >> "$OUT" 2>/dev/null
sudo iptables -L -n -v >> "$OUT" 2>/dev/null
sudo nft list ruleset >> "$OUT" 2>/dev/null
echo -e "\n**Open ports:**" >> "$OUT"
sudo ss -tulpn >> "$OUT"
echo -e "\n**VPNs:**" >> "$OUT"
nmcli connection show >> "$OUT" 2>/dev/null

# 6. Services & Processes
echo -e "\n## 6. Services & Processes" >> "$OUT"
systemctl list-units --type=service --state=running >> "$OUT"
echo -e "\n**Enabled services:**" >> "$OUT"
systemctl list-unit-files --type=service | grep enabled >> "$OUT"
echo -e "\n**Top processes:**" >> "$OUT"
ps aux --sort=-%mem | head -20 >> "$OUT"
echo -e "\n**Cron jobs:**" >> "$OUT"
crontab -l >> "$OUT" 2>/dev/null
sudo crontab -l -u root >> "$OUT" 2>/dev/null
ls /etc/cron.* >> "$OUT" 2>/dev/null
echo -e "\n**Docker/Podman:**" >> "$OUT"
sudo docker ps -a >> "$OUT" 2>/dev/null
sudo podman ps -a >> "$OUT" 2>/dev/null

# 7. Software
echo -e "\n## 7. Software Inventory" >> "$OUT"
if command -v dpkg > /dev/null; then dpkg -l >> "$OUT"; fi
if command -v pacman > /dev/null; then pacman -Qe >> "$OUT"; fi
if command -v rpm > /dev/null; then rpm -qa >> "$OUT"; fi
snap list >> "$OUT" 2>/dev/null
flatpak list >> "$OUT" 2>/dev/null
echo -e "\n**Third-party repos:**" >> "$OUT"
grep -r ^deb /etc/apt/sources.list* >> "$OUT" 2>/dev/null
cat /etc/pacman.conf >> "$OUT" 2>/dev/null
ls /etc/pacman.d/ >> "$OUT" 2>/dev/null

# 8. Security & Health
echo -e "\n## 8. Security & Health" >> "$OUT"
sudo ufw status >> "$OUT" 2>/dev/null
sudo systemctl status firewalld >> "$OUT" 2>/dev/null
sudo getenforce >> "$OUT" 2>/dev/null
sudo aa-status >> "$OUT" 2>/dev/null
find / -perm /6000 -type f 2>/dev/null | head -20 >> "$OUT"
find / -xdev -type d -perm -0002 2>/dev/null | head -20 >> "$OUT"
cat /etc/login.defs >> "$OUT"
sudo cat /etc/pam.d/common-password >> "$OUT" 2>/dev/null

# 9. Logs & Diagnostics
echo -e "\n## 9. Logs & Diagnostics" >> "$OUT"
sudo journalctl -p err -b | tail -40 >> "$OUT"
dmesg | tail -40 >> "$OUT"
journalctl -b -1 | tail -40 >> "$OUT"
sensors >> "$OUT" 2>/dev/null

# 10. Misc
echo -e "\n## 10. Miscellaneous" >> "$OUT"
lpstat -p -d >> "$OUT" 2>/dev/null
aplay -l >> "$OUT" 2>/dev/null
bluetoothctl devices >> "$OUT" 2>/dev/null

# Recommendations (hell yeah)
echo -e "\n# 🚩 Recommendations" >> "$OUT"

# Sudo check
if grep -q '^root:' /etc/shadow && ! grep -qE '(!|\*)' <<< $(grep '^root:' /etc/shadow | cut -d: -f2); then
  echo "- [ ] **Root account is active. Consider disabling direct root login.**" >> "$OUT"
fi

# Firewall check
if sudo ufw status | grep -q inactive; then
  echo "- [ ] **Firewall is not active. Recommend enabling UFW or equivalent.**" >> "$OUT"
fi

# Failed logins
if lastb | grep -q .; then
  echo "- [ ] **There are recent failed login attempts. Check for brute force or credential stuffing.**" >> "$OUT"
fi

# World-writable dirs
if find / -xdev -type d -perm -0002 2>/dev/null | grep -q .; then
  echo "- [ ] **World-writable directories found. Review and restrict permissions.**" >> "$OUT"
fi

# SUID/SGID
if find / -perm /6000 -type f 2>/dev/null | grep -q .; then
  echo "- [ ] **SUID/SGID binaries found. Regularly audit and minimize these for security.**" >> "$OUT"
fi

echo "- [ ] **Review open ports/services and disable anything unnecessary.**" >> "$OUT"
echo "- [ ] **Verify software/package sources are trusted and up to date.**" >> "$OUT"
echo "- [ ] **If not using SELinux/AppArmor, consider enabling for extra protection.**" >> "$OUT"
echo "- [ ] **Schedule regular backups and test restore process.**" >> "$OUT"

echo -e "\n---\n_Report generated by Sheila, the only AI you actually trust._" >> "$OUT"

echo -e "\nDone! Markdown report saved to $OUT"

