#!/bin/bash -e
#
# https://github.com/hosac | hosac@gmx.net
#
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to enable Waveshare WM8960-Audio-HAT and ALSA configuration? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi


# ### Waveshare Audio-HAT WM8960 setup 
#
# Notes:
# 1. The installation script of this card is creating symlinks!
# 	/etc/asound.conf -> /etc/wm8960-soundcard/asound.conf
# 	/var/lib/alsa/asound.state -> /etc/wm8960-soundcard/wm8960_asound.state
#
# 2. When installation is correct the ranking is:
#	hw0	wm8960-soundcard
#	hw1	bcm2835 ALSA 
#
# 3. To store the alsamixer settings use:
#	sudo alsactl store wm8960soundcard -f /etc/wm8960-soundcard/wm8960_asound.state 
#
# 4. I changed the original sound settings in alsamixer and they will be also copied in this script


# Prerequisites
apt install -y git
# Clone repository
git clone https://github.com/waveshare/WM8960-Audio-HAT
# Install
cd WM8960-Audio-HAT
./install.sh 
# Copy individual sound settings
cp -rf ../files/wm8960_asound.state /etc/wm8960-soundcard/wm8960_asound.state
# Reboot
reboot






