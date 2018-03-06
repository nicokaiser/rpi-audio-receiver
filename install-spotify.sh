#!/bin/sh

apt install --no-install-recommends -y git
wget https://github.com/Spotifyd/spotifyd/releases/download/untagged-5714215a4cf45130004f/spotifyd-2018-03-03-armv6.zip
unzip spotifyd-2018-03-03-armv6.zip
rm spotifyd-2018-03-03-armv6.zip
sudo mkdir -p /opt/spotifyd
mv spotifyd /opt/spotifyd

PRODUCTNAME=$(hostnamectl status --pretty)
PRODUCTNAME=${PRODUCTNAME:-$(hostname)}

cat <<EOF > /etc/spotifyd.conf
[global]
backend = alsa
mixer = Master
volume-control = softvol # or alsa
bitrate = 320
device_name = ${PRODUCTNAME}
EOF

cat <<'EOF' > /etc/systemd/system/spotifyd.service
[Unit]
Description=Spotify Connect
Documentation=https://github.com/Spotifyd/spotifyd
After=network-online.target
Requires=sound.target network-online.target

[Service]
Type=idle
User=pi
ExecStart=/opt/spotifyd/spotifyd -c /etc/spotifyd.conf --no-daemon
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now spotifyd.service
