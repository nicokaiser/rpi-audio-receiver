# Raspberry Pi Bluetooth & AirPlay Receiver

A simple, light weight Bluetooth Audio (A2DP) receiver based on Raspbian, BlueZ and ALSA.

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
sudo raspi-config nonint do_hostname airpi
sudo hostnamectl set-hostname --pretty "AirPi"

sudo ./update-system.sh
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

### Read-only mode

To avoid SD card corruption when powering off, you can boot Raspbian in read-only mode. This is described by Adafruit in [this tutorial](https://learn.adafruit.com/read-only-raspberry-pi/) and cannot be undone.

```
sudo ./enable-read-only.sh
```

## Limitations

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication
- To permanently save paired devices, the Raspberry has to be switched to read-write mode (`mount -o remount,rw /`) until all devices have been paired once.
