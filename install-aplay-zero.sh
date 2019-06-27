#!/bin/bash -e

echo -n "Do you want to activate '/dev/zero' playback in the background? This will remove all popping/clicking but does use some processor time. [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 1; fi

sh -c 'cat > /etc/systemd/system/aplay.service' << 'EOL'
[Unit]
Description=Invoke aplay from /dev/zero at system start.
Wants=sound.target

[Service]
ExecStart=/usr/bin/aplay -D default -t raw -r 44100 -c 2 -f S16_LE /dev/zero

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable --now aplay
