#!/bin/bash -e

echo -n "Do you want to install Startup sound? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

mkdir -p /usr/local/share/sounds/WoodenBeaver/stereo
if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-added.ogg ]; then
    curl -so /usr/local/share/sounds/WoodenBeaver/stereo/device-added.ogg https://raw.githubusercontent.com/madsrh/WoodenBeaver/master/WoodenBeaver/stereo/device-added.ogg
fi
if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-removed.ogg ]; then
    curl -so /usr/local/share/sounds/WoodenBeaver/stereo/device-removed.ogg https://raw.githubusercontent.com/madsrh/WoodenBeaver/master/WoodenBeaver/stereo/device-removed.ogg
fi

cat <<'EOF' > /etc/systemd/system/startup-sound.service
[Unit]
Description=Startup sound
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/ogg123 -q /usr/local/share/sounds/WoodenBeaver/stereo/device-added.ogg

[Install]
WantedBy=multi-user.target
EOF
systemctl enable startup-sound.service
