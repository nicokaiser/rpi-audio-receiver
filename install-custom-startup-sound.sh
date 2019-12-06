#!/bin/bash -e

echo -n "Do you want to install a custom startup sound? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

echo -n "Please place a "startup.wav" file of your choice under /home/pi/rpi-audio-receiver/sounds/ directory..."

cat <<'EOF' > /etc/systemd/system/startup-sound.service
[Unit]
Description=Startup sound
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/aplay -q /home/pi/rpi-audio-receiver/sounds/startup.wav

[Install]
WantedBy=multi-user.target
EOF
systemctl enable startup-sound.service
