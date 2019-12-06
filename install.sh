#!/bin/bash -e

read -p "Hostname [$(hostname)]: " HOSTNAME
sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}

CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)
read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
sudo hostnamectl set-hostname --pretty "${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"



echo "Updating packages"
sudo apt update
sudo apt upgrade -y

echo "Installing components"
sudo ./install-bluetooth.sh
sudo ./install-shairport.sh
sudo ./install-spotify.sh
sudo ./install-upnp.sh
sudo ./install-snapcast-client.sh

echo -n "Do you want to install a Custom startup sound? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; 
then sudo ./install-custom-startup-sound.sh; fi


sudo ./install-startup-sound.sh
#sudo ./install-pivumeter.sh
#sudo ./enable-hifiberry.sh
sudo ./install-aplay-zero.sh
sudo ./enable-read-only.sh
