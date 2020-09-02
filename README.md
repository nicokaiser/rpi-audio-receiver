# Raspberry Pi Audio Receiver

A simple, light weight audio receiver with Bluetooth (A2DP), AirPlay, Spotify Connect and UPnP.

## Features

Devices like phones, tablets and computers can play audio via this receiver.

## Requirements

- Raspberry Pi with Bluetooth support (tested wth Raspberry Pi 3, 4 and Zero W) or USB dongle
- Raspbian Buster Lite (tested with February 2020 version)
- Internal audio, HDMI, USB or I2S Audio adapter (tested with [Adafruit USB Audio Adapter](https://www.adafruit.com/product/1475),  [pHAT DAC](https://shop.pimoroni.de/products/phat-dac), and [HifiBerry DAC+](https://www.hifiberry.com/products/dacplus/))

## Installation

The installation script asks whether to install each component.

    wget -q https://github.com/nicokaiser/rpi-audio-receiver/archive/master.zip
    unzip master.zip
    rm master.zip

    cd rpi-audio-receiver-master
    ./install.sh

### Basic setup

Sets hostname to e.g. `airpi`, the visible device name ("pretty hostname") to `AirPi`.

### Bluetooth

Sets up Bluetooth, adds a simple agent that accepts every connection, and enables audio playback through [BlueALSA](https://github.com/Arkq/bluez-alsa). A udev script is installed that disables discoverability while connected.

#### Enable pairing with PIN

To enable pairing with a PIN code instead of Simple Secure Pairing mode, the following steps are required:

1. Change `sspmode 1` to `sspmode 0` in `/etc/systemd/system/bthelper@.service.d/override.conf`
2. Add ` --pin /etc/bluetooth/pin.conf` to the `ExecStart` line in `/etc/systemd/system/bthelper@.service.d/override.conf`
3. Add a file `/etc/bluetooth/pin.conf` which contains PIN code for the devices:

`AA:BB:CC:DD:EE:FF 1234` (replace `AA:BB:CC:DD:EE:FF` with your Bluetooth devices's Mac address or `*` to use PIN `1234` for all devices)

### AirPlay

Installs [Shairport Sync](https://github.com/mikebrady/shairport-sync) AirPlay Audio Receiver.

This script comes with a backported version of shairport-sync from Raspbian Bullseye (see [SimpleBackportCreation](https://wiki.debian.org/SimpleBackportCreation) for details) and can be replaced with the original (but older) one in Raspbian Buster or a sef-compiled one (not part of this project).

### Spotify Connect

Installs [Spotifyd](https://github.com/Spotifyd/spotifyd), an open source Spotify client).

### UPnP

Installs [gmrender-resurrect](http://github.com/hzeller/gmrender-resurrect) UPnP Renderer.

### Snapcast

Installs [snapclient](https://github.com/badaix/snapcast), the client component of the Snapcast Synchronous multi-room audio player.

### Read-only mode

To avoid SD card corruption when powering off, you can boot Raspbian in read-only mode. This is described by Adafruit in [this tutorial](https://learn.adafruit.com/read-only-raspberry-pi/) and cannot be undone.

## Limitations

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication.
- To permanently save paired devices when using read-only mode, the Raspberry has to be switched to read-write mode (`mount -o remount,rw /`) until all devices have been paired once.
- You might want to use a Bluetooth USB dongle or have the script disable Wi-Fi while connected (see `bluetooth-udev`), as the BCM43438 (Raspberry Pi 3, Zero W) has severe problems with both switched on, see [raspberrypi/linux/#1402](https://github.com/raspberrypi/linux/issues/1402).
- The Pi Zero may not be powerful enough to play 192 kHz audio, you may want to change the values in `/etc/asound.conf` accordingly.

## Disclaimer

These scripts are tested and work on a current (as of May 2020) Raspbian setup on Raspberry Pi. Depending on your setup (board, configuration, sound module, Bluetooth adapter) and your preferences, you might need to adjust the scripts. They are held as simple as possible and can be used as a starting point for additional adjustments.

## Contributing

Package and configuration choices are quite opinionated but as close to the Debian defaults as possible. Customizations can be made by modifying the scripts, but the installer should stay as simple as possible, with as few choices as possible. That said, pull requests and suggestions are of course always welcome. However I might decide not to merge changes that add too much complexity.

## References

- [BlueALSA: Bluetooth Audio ALSA Backend](https://github.com/Arkq/bluez-alsa)
- [Shairport Sync: AirPlay Audio Receiver](https://github.com/mikebrady/shairport-sync)
- [Spotifyd: open source Spotify client](https://github.com/Spotifyd/spotifyd)
- [gmrender-resurrect: Headless UPnP Renderer](http://github.com/hzeller/gmrender-resurrect)
- [Snapcast: Synchronous audio player](https://github.com/badaix/snapcast)
- [pivumeter: ALSA plugin for displaying VU meters on various Raspberry Pi add-ons](https://github.com/pimoroni/pivumeter)
- [Adafruit: Read-Only Raspberry Pi](https://github.com/adafruit/Raspberry-Pi-Installer-Scripts/blob/master/read-only-fs.sh)
