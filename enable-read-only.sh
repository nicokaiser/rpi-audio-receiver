#!/bin/sh

# Enable read-only filesystem mode

wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/read-only-fs.sh
bash read-only-fs.sh

ln -s /tmp /var/lib/dhcpcd5
systemctl disable apt-daily-upgrade.service
systemctl disable apt-daily-upgrade.timer

rm /var/lib/systemd/random-seed
ln -s /tmp/random-seed /var/lib/systemd/random-seed

cat <<'EOF' > /etc/systemd/system/systemd-random-seed.service.d/override.conf
[Service]
ExecStartPre=/bin/echo "" > /tmp/random-seed
EOF
