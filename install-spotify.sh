#!/bin/sh

echo "Installing Spotify Connect (spotifyd)"

#wget https://github.com/Spotifyd/spotifyd/releases/download/v0.2.5/spotifyd-2019-02-25-armv6.zip
#unzip spotifyd-2019-02-25-armv6.zip
#rm spotifyd-2019-02-25-armv6.zip

#wget https://github.com/Spotifyd/spotifyd/releases/download/v0.2.24/spotifyd-linux-armv6-slim.tar.gz
wget https://github.com/Spotifyd/spotifyd/releases/latest/download/spotifyd-linux-armv6-slim.tar.gz
tar -xf spotifyd-linux-armv6-slim.tar.gz
rm spotifyd-linux-armv6-slim.tar.gz

mkdir -p /opt/local/bin
mv spotifyd /opt/local/bin

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

# Check https://github.com/Spotifyd/spotifyd#configuration-file
#   for more conif options
cat <<EOF > /etc/spotifyd.conf
[global]
backend = alsa
volume_controller = softvol
device = hw:Headphones,0
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
ExecStart=/opt/local/bin/spotifyd --config-path /etc/spotifyd.conf --no-daemon
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now spotifyd.service
