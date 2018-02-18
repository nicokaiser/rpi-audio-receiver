#!/bin/sh

apt install --no-install-recommends -y git
wget https://github.com/Spotifyd/spotifyd/releases/download/untagged-7542bdb173909d014e1e/spotifyd-2018-02-14-armv7.zip
unzip spotifyd-2018-02-14-armv7.zip
rm spotifyd-2018-02-14-armv7.zip
sudo mkdir -p /opt/spotifyd
mv spotifyd /opt/spotifyd

cat <<'EOF' > /etc/spotifyd.conf
[global]
backend = alsa
mixer = Master
volume-control = softvol # or alsa
bitrate = 320
device_name = AirPi Wohnzimmer
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
ExecStart=/opt/spotifyd/spotifyd -c /etc/spotifyd.conf --no-daemon
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now spotifyd.service
