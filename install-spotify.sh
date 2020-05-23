#!/bin/bash -e

ARCH=armhf # Change to armv6 for Raspberry Pi 1/Zero
BUILD=full # Change to full for build with all optional features enabled

# Create URL with ARCH and BUILD vars for easier use in curl 
URL=browser_download_url.*${ARCH}-${BUILD}.tar.gz

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Spotify Connect (spotifyd)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

# Always get the latest version
curl -s https://api.github.com/repos/Spotifyd/spotifyd/releases/latest \
| grep $URL \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs -n 1 wget -P ./files/
tar -xvzf files/spotifyd-linux-${ARCH}-${BUILD}.tar.gz

mkdir -p /usr/local/bin
mv spotifyd /usr/local/bin

PRETTY_HOSTNAME=$(hostnamectl status --pretty | tr ' ' '-')
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > /etc/spotifyd.conf
[global]
backend = alsa
mixer = Softvol
volume-control = softvol # alsa
device_name = ${PRETTY_HOSTNAME}
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
ExecStart=/usr/local/bin/spotifyd --no-daemon
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now spotifyd.service
