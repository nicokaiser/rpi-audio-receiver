#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Spotify Connect (Raspotify)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

mkdir -p /etc/systemd/system/raspotify.service.d
cat <<'EOF' > /etc/systemd/system/raspotify.service.d/override.conf
[Unit]
Wants=pulseaudio.service

[Service]
SupplementaryGroups=pulse-access
EOF

systemctl restart raspotify
