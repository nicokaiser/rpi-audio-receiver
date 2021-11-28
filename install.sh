#!/bin/bash -e

read -p "Hostname [$(hostname)]: " HOSTNAME
sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}

CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)
read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
sudo hostnamectl set-hostname --pretty "${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"

echo "Updating packages"
sudo apt update
sudo apt upgrade -y

echo "Installing PulseAudio"
apt install -y --no-install-recommends pulseaudio
usermod -a -G pulse-access root
usermod -a -G bluetooth pulse
mv /etc/pulse/client.conf /etc/pulse/client.conf.orig
cat <<'EOF' >> /etc/pulse/client.conf
default-server = /run/pulse/native
autospawn = no
EOF

# PulseAudio system daemon
cat <<'EOF' > /etc/systemd/system/pulseaudio.service
[Unit]
Description=Sound Service
[Install]
WantedBy=multi-user.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/bin/pulseaudio --daemonize=no --system --disallow-exit --disable-shm --exit-idle-time=-1 --log-target=journal
Restart=on-failure
EOF
systemctl enable --now pulseaudio.service

# Disable user-level PulseAudio service
systemctl --global mask pulseaudio.socket

echo "Installing components"
#sudo ./install-bluetooth.sh # Currently not supported, needs to be updated to PulseAudio
sudo ./install-shairport.sh
sudo ./install-spotify.sh
sudo ./enable-hifiberry.sh
sudo ./enable-read-only.sh
