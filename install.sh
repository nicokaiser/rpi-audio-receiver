#!/bin/bash -e

if [ "$1" != "-q" ];
then
	read -p "Hostname [$(hostname)]: " HOSTNAME
	sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}
	
	CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)
	read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
	sudo hostnamectl set-hostname --pretty "${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"
else
        source ./setup.conf
fi

echo "Updating packages"
sudo apt update
sudo apt upgrade -y

echo "Installing components"
if [[ $FEATURES = *bluetooth* ]]; then sudo ./install-bluetooth.sh $@; fi
if [[ $FEATURES = *shairport* ]]; then sudo ./install-shairport.sh $@; fi
if [[ $FEATURES = *spotify* ]]; then sudo ./install-spotify.sh $@; fi
if [[ $FEATURES = *upnp* ]]; then sudo ./install-upnp.sh $@; fi
if [[ $FEATURES = *snapcast* ]]; then sudo ./install-snapcast-client.sh $@; fi
if [[ $FEATURES = *pivumeter* ]]; then sudo ./install-pivumeter.sh $@; fi
if [[ $FEATURES = *hifiberry* ]]; then sudo ./enable-hifiberry.sh $@; fi
if [[ $FEATURES = *read-only* ]]; then sudo ./enable-read-only.sh $@; fi
