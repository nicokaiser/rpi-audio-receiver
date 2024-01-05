#!/bin/bash -e

echo
echo -n "Do you want to install Spotify Connect (Raspotify)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

PRETTY_HOSTNAME=$(hostnamectl status --pretty | tr ' ' '-')
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

sudo tee /etc/raspotify/conf <<'EOF'
LIBRESPOT_QUIET=
LIBRESPOT_AUTOPLAY=
LIBRESPOT_DISABLE_AUDIO_CACHE=
LIBRESPOT_DISABLE_CREDENTIAL_CACHE=
LIBRESPOT_ENABLE_VOLUME_NORMALISATION=
LIBRESPOT_NAME="${PRETTY_HOSTNAME}"
LIBRESPOT_DEVICE_TYPE="avr"
LIBRESPOT_BITRATE="320"
LIBRESPOT_INITIAL_VOLUME="100"
EOF

sudo systemctl daemon-reload
sudo systemctl enable raspotify
