#!/bin/bash -e

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

