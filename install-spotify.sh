#!/bin/bash -e

ARCH=armhf # Change to armv6 for Raspberry Pi 1/Zero

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Spotify Connect (spotifyd)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

# https://github.com/Spotifyd/spotifyd/releases/download/v0.2.24/spotifyd-linux-${ARCH}-slim.tar.gz
tar -xvzf files/spotifyd-linux-${ARCH}-slim.tar.gz
mkdir -p /usr/local/bin
mv spotifyd /usr/local/bin


cat <<'EOF' > /etc/spotifyd.conf
[global]
backend = alsa
mixer = Softvol
volume-control = softvol # alsa
bitrate = 320
#zeroconf_port = 4444
EOF

cat <<'EOF' > /etc/systemd/system/spotifyd.service
[Unit]
Description=A spotify playing daemon
Documentation=https://github.com/Spotifyd/spotifyd
Wants=network-online.target
After=network.target sound.target

[Service]
Type=simple
ExecStartPre=/bin/sh -c "/bin/systemctl set-environment DEVICE_NAME=$(hostname)"
ExecStart=/usr/local/bin/spotifyd --no-daemon --device-name $DEVICE_NAME
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now spotifyd.service
