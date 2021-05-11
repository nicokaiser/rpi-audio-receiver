#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
if [ "$1" != "-q" ];
then

	echo
	echo -n "Do you want to install Snapcast client (snapclient})? [y/N] "
	read REPLY
	if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi
else
        source ./setup.conf
fi

apt install --no-install-recommends -y snapclient
