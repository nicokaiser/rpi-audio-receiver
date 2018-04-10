#!/bin/sh

echo "Installing Spotify Connect (spotifyd)"

wget https://github.com/Spotifyd/spotifyd/releases/download/untagged-61816928a53a74993dc0/spotifyd-2018-04-03-armv6.zip
unzip spotifyd-2018-04-03-armv6.zip
rm spotifyd-2018-04-03-armv6.zip
mkdir -p /opt/local/bin
mv spotifyd /opt/local/bin

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
After=network-online.target
After=sound.target

[Service]
Type=idle
User=pi
ExecStart=/opt/local/bin/spotifyd -c /etc/spotifyd.conf --no-daemon
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now spotifyd.service
