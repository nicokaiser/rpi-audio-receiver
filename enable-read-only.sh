#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to enable read-only mode? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

# Disable swapfile
dphys-swapfile swapoff
dphys-swapfile uninstall
systemctl disable dphys-swapfile.service

# Remove unwanted packages
apt-get remove -y --purge triggerhappy logrotate dphys-swapfile fake-hwclock
apt-get autoremove -y --purge
apt-get install -y busybox-syslogd
dpkg --purge rsyslog

# Disable apt activities
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily.timer
systemctl disable man-db.timer

# Move resolv.conf to /run
mv /etc/resolv.conf /run/resolvconf/resolv.conf
ln -s /run/resolvconf/resolv.conf /etc/resolv.conf

# Adjust kernel command line
sed -i.backup -e 's/rootwait$/rootwait fsck.mode=skip noswap ro/' /boot/cmdline.txt

# Edit the file system table
sed -i.backup -e 's/vfat\s*defaults\s/vfat defaults,ro/; s/ext4\s*defaults,noatime\s/ext4 defaults,noatime,ro/' /etc/fstab

# Make edits to fstab
cat <<'EOF' >> /etc/fstab
tmpfs /tmp tmpfs mode=1777,nosuid,nodev 0 0
tmpfs /var/tmp tmpfs mode=1777,nosuid,nodev 0 0
tmpfs /var/spool tmpfs mode=0755,nosuid,nodev 0 0
tmpfs /var/log tmpfs mode=0755,nosuid,nodev 0 0
tmpfs /var/lib/dhcpcd5 tmpfs mode=0755,nosuid,nodev 0 0
EOF
