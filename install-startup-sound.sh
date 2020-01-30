#!/bin/bash -e

echo -n "Do you want to install Startup sound? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

# WoodenBeaver sounds
mkdir -p /usr/local/share/sounds/WoodenBeaver/stereo
if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-added.wav ]; then
    cp files/device-added.wav /usr/local/share/sounds/WoodenBeaver/stereo/
fi
if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-removed.wav ]; then
    cp files/device-removed.wav /usr/local/share/sounds/WoodenBeaver/stereo/
fi

cat <<'EOF' > /etc/systemd/system/startup-sound.service
[Unit]
Description=Startup sound
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/aplay -q /usr/local/share/sounds/WoodenBeaver/stereo/device-added.wav

[Install]
WantedBy=multi-user.target
EOF
systemctl enable startup-sound.service
