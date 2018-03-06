#!/bin/sh

mkdir -p /home/pi/Music
wget -O /home/pi/Music/beocreate-sounds.zip "http://downloads.hifiberry.com/beocreate/common/beocreate-sounds.zip"
cd /home/pi/Music
unzip beocreate-sounds.zip
rm beocreate-sounds.zip

cat <<'EOF' > /etc/systemd/system/startup-sound.service
[Unit]
Description=Startup sound
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/aplay -q /home/pi/Music/startup.wav

[Install]
WantedBy=multi-user.target
EOF
systemctl enable startup-sound.service
