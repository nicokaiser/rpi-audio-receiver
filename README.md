<h1>Raspberry Pi Audio Receiver</h1>

A fork of https://github.com/nicokaiser/rpi-audio-receiver.
It contains some modifications and additional packages. 
<br>

<h2>Features</h2>

A simple, light weight audio receiver with Bluetooth (A2DP), AirPlay, Spotify Connect and UPnP. Devices like phones, tablets and computers can play audio via this receiver.
<br>

<h2>Requirements</h2>

- Raspberry Pi with Bluetooth support (tested wth Raspberry Pi 3, 4 and Zero W) or USB dongle
- Raspbian Buster Lite (tested with February 2020 version)
- Internal audio, HDMI, USB or I2S Audio adapter (tested with [Adafruit USB Audio Adapter](https://www.adafruit.com/product/1475),  [pHAT DAC](https://shop.pimoroni.de/products/phat-dac), and [HifiBerry DAC+](https://www.hifiberry.com/products/dacplus/))
<br>

<h2>Prerequisites</h2>

Update the system

	sudo apt-get update
	sudo apt-get upgrade -y
<br>

<h2>Installation</h2>

The installation script asks whether to install each component.

    wget -q https://github.com/hosac/rpi-audio-receiver/archive/master.zip
    unzip master.zip
    rm master.zip

    cd rpi-audio-receiver-master
    ./install.sh

<h3>Bluetooth</h3>

Sets up Bluetooth, adds a simple agent that accepts every connection, and enables audio playback through [BlueALSA](https://github.com/Arkq/bluez-alsa). A udev script is installed that disables discoverability while connected. Sometimes a reboot is necessary after installation to work correctly.

<h3>AirPlay</h3>

AirPlay is used by Apple devices with iOS, iPadOS and MacOS. The script installs [Shairport Sync](https://github.com/mikebrady/shairport-sync) AirPlay Audio Receiver. It comes with a backported version of shairport-sync from Raspbian Bullseye (see [SimpleBackportCreation](https://wiki.debian.org/SimpleBackportCreation) for details). In addition there is an option to build the current version from source.

<h3>Spotify Connect</h3>

Installs [Spotifyd](https://github.com/Spotifyd/spotifyd), an open source Spotify client.

<h3>DLNA/UPnP</h3>

DLNA/UPnP is used by several clients. Windows Media Player supports it out of the box. For Android [Bubble UPnP](https://play.google.com/store/apps/details?id=com.bubblesoft.android.bubbleupnp&hl=com) is a recommended app. The script installs [gmrender-resurrect](http://github.com/hzeller/gmrender-resurrect) UPnP Renderer. It is possible to install it with apt package manager or build it locally from source. Apt version is currently outdated (version: 0.0.7~git20170910+repack-1), has some issues with contol and is not changing the hostname dynamically. <b>It is highly recommended to install from source!</b>

<h3>Snapcast</h3>

Installs [snapclient](https://github.com/badaix/snapcast), the client component of the Snapcast Synchronous multi-room audio player. Install is possible with apt package (currently v.0.15.0) or with .deb file (v.0.19.0)

<h3>Startup-Sound</h3>

A system sound will be installed, which is played at every system startup or when a bluetooth connection is established.

<h3>PiVuMeter</h3>

ALSA plugin for displaying VU meters. Please note that the current settings work only for the HifiBerry cards!

<h3>HifiBerry</h3>
Setup process for audio hardware from the HiFiBerry family. 


<h3>Read-only mode</h3>

To avoid SD card corruption when powering off, you can boot Raspbian in read-only mode. This is described by Adafruit in [this tutorial](https://learn.adafruit.com/read-only-raspberry-pi/) and cannot be undone.
<br>

<h2>Limitations</h2>

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication.
- To permanently save paired devices when using read-only mode, the Raspberry has to be switched to read-write mode (`mount -o remount,rw /`) until all devices have been paired once.
- You might want to use a Bluetooth USB dongle or have the script disable Wi-Fi while connected (see `bluetooth-udev`), as the BCM43438 (Raspberry Pi 3, Zero W) has severe problems with both switched on, see [raspberrypi/linux/#1402](https://github.com/raspberrypi/linux/issues/1402).
- The Pi Zero may not be powerful enough to play 192 kHz audio, you may want to change the values in `/etc/asound.conf` accordingly.
<br>

<h2>Disclaimer</h2>

These scripts are tested and work on a current (as of January 2020) Raspbian setup on Raspberry Pi. Depending on your setup (board, configuration, sound module, Bluetooth adapter) and your preferences, you might need to adjust the scripts. They are held as simple as possible and can be used as a starting point for additional adjustments.
<br>

<h2>References</h2>

- [BlueALSA: Bluetooth Audio ALSA Backend](https://github.com/Arkq/bluez-alsa)
- [Shairport Sync: AirPlay Audio Receiver](https://github.com/mikebrady/shairport-sync)
- [Spotifyd: open source Spotify client](https://github.com/Spotifyd/spotifyd)
- [gmrender-resurrect: Headless UPnP Renderer](http://github.com/hzeller/gmrender-resurrect)
- [Snapcast: Synchronous audio player](https://github.com/badaix/snapcast)
- [pivumeter: ALSA plugin for displaying VU meters on various Raspberry Pi add-ons](https://github.com/pimoroni/pivumeter)
- [Adafruit: Read-Only Raspberry Pi](https://github.com/adafruit/Raspberry-Pi-Installer-Scripts/blob/master/read-only-fs.sh)
