#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Spotify Connect (Raspotify)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

curl -sL https://dtcooper.github.io/raspotify/install.sh | sh
usermod -a -G gpio raspotify

PRETTY_HOSTNAME=$(hostnamectl status --pretty | tr ' ' '-')
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > /etc/default/raspotify
DEVICE_NAME="${PRETTY_HOSTNAME}"
BITRATE="320"
VOLUME_ARGS="--linear-volume --initial-volume=100"
EOF
