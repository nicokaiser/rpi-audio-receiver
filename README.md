# Raspberry Pi Audio Receiver

A simple, light weight audio receiver with Bluetooth (A2DP), AirPlay, Spotify Connect and UPnP.

## Features

Devices like phones, tablets and computers can play audio via this receiver.

## Requirements

- Raspberry Pi with Bluetooth support (tested wth Raspberry Pi Zero W) or USB dongle
- Raspbian Stretch Lite (tested with version 2017-11-29)
- USB or I2S Audio adapter (tested with [Adafruit USB Audio Adapter](https://www.adafruit.com/product/1475) and [pHAT DAC](https://shop.pimoroni.de/products/phat-dac))

## Installation

### Basic setup

Sets hostname to `airpi`, the visible device name to `AirPi` and updates the Raspbian packages.

```
sudo apt update -y
sudo apt upgrade -y
sudo SKIP_WARNING=1 rpi-update

sudo apt install -y --no-install-recommends git

git clone https://github.com/nicokaiser/rpi-audio-receiver.git
cd rpi-audio-receiver

sudo raspi-config nonint do_hostname airpi
sudo hostnamectl set-hostname --pretty "AirPi"
```

### Bluetooth

Sets up Bluetooth, adds a simple agent that accepts every connection, and enables audio playback through [BlueALSA](https://github.com/Arkq/bluez-alsa). A udev script is installed that disables discoverability while connected.

```
sudo ./install-bluetooth.sh
```

### AirPlay

Installs [Shairport Sync](https://github.com/mikebrady/shairport-sync) AirPlay Audio Receiver.

``` 
sudo ./install-shairport.sh
```

### Spotify Connect

Installs [Spotifyd](https://github.com/Spotifyd/spotifyd), an open source Spotify client).

```
sudo ./install-spotify.sh
```

### UPnP

Installs [gmrender-resurrect](http://github.com/hzeller/gmrender-resurrect) UPnP Renderer.

```
sudo ./install-upnp.sh
```

### Read-only mode

To avoid SD card corruption when powering off, you can boot Raspbian in read-only mode. This is described by Adafruit in [this tutorial](https://learn.adafruit.com/read-only-raspberry-pi/) and cannot be undone.

```
sudo ./enable-read-only.sh
```

## Limitations

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication.
- To permanently save paired devices, the Raspberry has to be switched to read-write mode (`mount -o remount,rw /`) until all devices have been paired once.
- You might want to use a Bluetooth USB dongle or have the script disable Wi-Fi while connected (see `bluetooth-udev.sh`), as the BCM43438 (Raspberry Pi 3, Zero W) has severe problems with both switched on, see [raspberrypi/linux/#1402](https://github.com/raspberrypi/linux/issues/1402).

## References

- [BlueALSA: Bluetooth Audio ALSA Backend](https://github.com/Arkq/bluez-alsa)
- [Shairport Sync: AirPlay Audio Receiver](https://github.com/mikebrady/shairport-sync)
- [Spotifyd: open source Spotify client](https://github.com/Spotifyd/spotifyd)
- [gmrender-resurrect: Headless UPnP Renderer](http://github.com/hzeller/gmrender-resurrect)
- [pivumeter: ALSA plugin for displaying VU meters on various Raspberry Pi add-ons](https://github.com/pimoroni/pivumeter)
- [Adafruit: Read-Only Raspberry Pi](https://github.com/adafruit/Raspberry-Pi-Installer-Scripts/blob/master/read-only-fs.sh)
