#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Spotify Connect (spotifyd)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

echo
while true; do
    options=("armhf" "armv6")
    echo "Board architecture (armv6 for Raspberry Pi 1/Zero)"
    select opt in "${options[@]}"; do
        case $REPLY in
            1) ARCH=${options[0]}; break 2 ;;
            2) ARCH=${options[1]}; break 2 ;;
            *) echo "Board architecture (armv6 for Raspberry Pi 1/Zero)" >&2
        esac
    done
done

# https://github.com/Spotifyd/spotifyd/releases/download/v0.2.24/spotifyd-linux-${ARCH}-slim.tar.gz
tar -xvzf files/spotifyd-linux-${ARCH}-slim.tar.gz
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
