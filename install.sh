#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

read -p "Hostname [$(hostname)]: " HOSTNAME
raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}

CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)
read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
hostnamectl set-hostname --pretty "${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"

echo "Updating packages"
apt update
apt upgrade -y

echo "Installing PulseAudio"
apt install -y --no-install-recommends pulseaudio
usermod -a -G pulse-access root
usermod -a -G bluetooth pulse
mv /etc/pulse/client.conf /etc/pulse/client.conf.orig
cat <<'EOF' >> /etc/pulse/client.conf
default-server = /run/pulse/native
autospawn = no
EOF
sed -i '/^load-module module-native-protocol-unix$/s/$/ auth-cookie-enabled=0 auth-anonymous=1/' /etc/pulse/system.pa

# PulseAudio system daemon
cat <<'EOF' > /etc/systemd/system/pulseaudio.service
[Unit]
Description=Sound Service
[Install]
WantedBy=multi-user.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/bin/pulseaudio --daemonize=no --system --disallow-exit --disable-shm --exit-idle-time=-1 --log-target=journal --realtime --no-cpu-limit
Restart=on-failure
EOF
systemctl enable --now pulseaudio.service

# Disable user-level PulseAudio service
systemctl --global mask pulseaudio.socket

echo "Installing components"
./install-bluetooth.sh
./install-shairport.sh
./install-spotify.sh
./enable-hifiberry.sh
