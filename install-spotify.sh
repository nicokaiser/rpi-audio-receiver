#!/bin/bash -e

SPOTIFYD_VERSION=0.2.5
SPOTIFYD_BUILD=2019-02-25

echo -n "Do you want to install Spotify Connect (spotifyd v${SPOTIFYD_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

wget https://github.com/Spotifyd/spotifyd/releases/download/v${SPOTIFYD_VERSION}/spotifyd-${SPOTIFYD_BUILD}-armv6.zip
unzip spotifyd-${SPOTIFYD_BUILD}-armv6.zip
rm spotifyd-${SPOTIFYD_BUILD}-armv6.zip
mkdir -p /usr/local/bin
mv spotifyd /usr/local/bin

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > /etc/spotifyd.conf
[global]
backend = alsa
mixer = Master
volume-control = softvol # or alsa
device_name = ${PRETTY_HOSTNAME}
bitrate = 320
EOF

cat <<'EOF' > /etc/systemd/system/spotifyd.service
[Unit]
Description=Spotify Connect
Documentation=https://github.com/Spotifyd/spotifyd
Wants=sound.target
After=sound.target
Wants=network-online.target
After=network-online.target

[Service]
Type=idle
User=pi
ExecStart=/usr/local/bin/spotifyd -c /etc/spotifyd.conf --no-daemon
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now spotifyd.service
