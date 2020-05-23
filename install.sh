#!/bin/bash -e

read -p "Hostname [$(hostname)]: " HOSTNAME
sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}

echo "Updating packages"
sudo apt update
sudo apt upgrade -y

echo "Installing components"
sudo ./install-bluetooth.sh
sudo ./install-shairport.sh
sudo ./install-spotify.sh
sudo ./install-upnp.sh
sudo ./install-snapcast-client.sh
sudo ./install-startup-sound.sh
sudo ./install-pivumeter.sh
sudo ./enable-hifiberry.sh
sudo ./enable-read-only.sh
