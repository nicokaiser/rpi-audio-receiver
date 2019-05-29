# Raspberry Pi Audio Receiver

A simple, light weight audio receiver with Bluetooth (A2DP), AirPlay, Spotify Connect and UPnP.

## Features

Devices like phones, tablets and computers can play audio via this receiver.

## Requirements

- Raspberry Pi with Bluetooth support (tested wth Raspberry Pi 3 and Zero W) or USB dongle
- Raspbian Stretch Lite (tested with November 2018 version)
- USB or I2S Audio adapter (tested with [Adafruit USB Audio Adapter](https://www.adafruit.com/product/1475),  [pHAT DAC](https://shop.pimoroni.de/products/phat-dac), and [HifiBerry DAC+](https://www.hifiberry.com/products/dacplus/))

## Installation

The installation script asks whether to install each component.

    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --no-install-recommends git

    git clone https://github.com/nicokaiser/rpi-audio-receiver.git
    cd rpi-audio-receiver
    ./install.sh

### Basic setup

Sets hostname to e.g. `airpi`, the visible device name ("pretty hostname") to `AirPi`.

### Bluetooth

Sets up Bluetooth, adds a simple agent that accepts every connection, and enables audio playback through [BlueALSA](https://github.com/Arkq/bluez-alsa). A udev script is installed that disables discoverability while connected.

### AirPlay

Installs [Shairport Sync](https://github.com/mikebrady/shairport-sync) AirPlay Audio Receiver.

### Spotify Connect

Installs [Spotifyd](https://github.com/Spotifyd/spotifyd), an open source Spotify client).

### UPnP

Installs [gmrender-resurrect](http://github.com/hzeller/gmrender-resurrect) UPnP Renderer.

### Snapcast

Installs [snapclient](https://github.com/badaix/snapcast), the client component of the Snapcast Synchronous multi-room audio player.

### /dev/zero playback

Some DACs tend to produce popping/clicking noises when switching from or to stand-by (i.e. when no sound is played). An optional `aplay` service can be installed which always streams an empty bytestream to the DAC. This consumes some CPU but avoids clicks.

### Read-only mode

To avoid SD card corruption when powering off, you can boot Raspbian in read-only mode. This is described by Adafruit in [this tutorial](https://learn.adafruit.com/read-only-raspberry-pi/) and cannot be undone.

## Limitations

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication.
- To permanently save paired devices, the Raspberry has to be switched to read-write mode (`mount -o remount,rw /`) until all devices have been paired once.
- You might want to use a Bluetooth USB dongle or have the script disable Wi-Fi while connected (see `bluetooth-udev.sh`), as the BCM43438 (Raspberry Pi 3, Zero W) has severe problems with both switched on, see [raspberrypi/linux/#1402](https://github.com/raspberrypi/linux/issues/1402).

## Disclaimer

These scripts are tested and work on a current (as of the current date) Raspbian setup on Raspberry Pi. Depending on your setup (board, configuration, sound module, Bluetooth adapter) and your preferences, you might need to adjust the scripts. They are held as simple as possible and can be used as a starting point for additional adjustments.

## References

- [BlueALSA: Bluetooth Audio ALSA Backend](https://github.com/Arkq/bluez-alsa)
- [Shairport Sync: AirPlay Audio Receiver](https://github.com/mikebrady/shairport-sync)
- [Spotifyd: open source Spotify client](https://github.com/Spotifyd/spotifyd)
- [gmrender-resurrect: Headless UPnP Renderer](http://github.com/hzeller/gmrender-resurrect)
- [Snapcast: Synchronous audio player](https://github.com/badaix/snapcast)
- [pivumeter: ALSA plugin for displaying VU meters on various Raspberry Pi add-ons](https://github.com/pimoroni/pivumeter)
- [Adafruit: Read-Only Raspberry Pi](https://github.com/adafruit/Raspberry-Pi-Installer-Scripts/blob/master/read-only-fs.sh)
