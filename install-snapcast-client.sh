#!/bin/bash -e

SNAPCLIENT_VERSION=0.15.0

echo -n "Do you want to install Snapcast client (snapclient v${SNAPCLIENT_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 1; fi

wget https://github.com/badaix/snapcast/releases/download/v${SNAPCLIENT_VERSION}/snapclient_${SNAPCLIENT_VERSION}_armhf.deb
dpkg -i snapclient_${SNAPCLIENT_VERSION}_armhf.deb
rm snapclient_${SNAPCLIENT_VERSION}_armhf.deb
apt -f install --no-install-recommends -y
