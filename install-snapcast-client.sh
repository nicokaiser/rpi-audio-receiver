#!/bin/bash -e

echo -n "Do you want to install Snapcast client (snapclient})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 1; fi

apt install --no-install-recommends -y snapclient
