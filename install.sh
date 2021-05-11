#!/bin/bash -e

if [ "$1" != "-q" ];
then
	read -p "Hostname [$(hostname)]: " HOSTNAME
	sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}
	
	CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)
	read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
	sudo hostnamectl set-hostname --pretty "${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"
else
  if [ ! -f "./setup.conf" ]; then echo "./setup.conf not found"; exit -1;fi
        source ./setup.conf
fi

echo "Updating packages"
sudo apt update
sudo apt upgrade -y

echo "Installing components"
if [[ $FEATURES = *bluetooth* ]]; then sudo $(dirname $0)/install-bluetooth.sh $@; fi
if [[ $FEATURES = *shairport* ]]; then sudo $(dirname $0)/install-shairport.sh $@; fi
if [[ $FEATURES = *spotify* ]]; then sudo $(dirname $0)/install-spotify.sh $@; fi
if [[ $FEATURES = *upnp* ]]; then sudo $(dirname $0)/install-upnp.sh $@; fi
if [[ $FEATURES = *snapcast* ]]; then sudo $(dirname $0)/install-snapcast-client.sh $@; fi
if [[ $FEATURES = *pivumeter* ]]; then sudo $(dirname $0)/install-pivumeter.sh $@; fi
#if [[ $FEATURES = *hifiberry* ]]; then sudo ./enable-hifiberry.sh $@; fi ##sctipt not alterted
if [[ $FEATURES = *read-only* ]]; then sudo $(dirname $0)/enable-read-only.sh $@; fi
