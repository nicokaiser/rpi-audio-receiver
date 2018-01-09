# Raspberry Pi A2DP Receiver

A simple, light weight Bluetooth Audio (A2DP) receiver based on Raspbian, BlueZ and PulseAudio.

## Features

Devices like phones, tablets and computers can play audio via this receiver.

Once the device has booted, a sound is played and after 60 seconds, Wi-Fi is disabled _unless_ an SSH login occurs during this time.

## Requirements

- Raspberry Pi with Bluetooth support (tested wth Raspberry Pi Zero W)
- Raspbian Stretch Lite (tested with version 2017-11-29)
- USB Audio adapter (tested with [Adafruit USB Audio Adapter](https://www.adafruit.com/product/1475))

## Installation

```
wget https://raw.githubusercontent.com/nicokaiser/rpi-bluetooth-receiver/master/install.sh
sudo install.sh
```

This will:

- Update the APT package index
- Upgrade existing packages
- Update the Raspberry Pi firmware
- Install and configure BlueZ, ALSA and PulseAudio
- Enable auto login and for user "pi"
- Enable simple pairing/trusting agent
- Install a Wi-Fi timeout script (see below)
- Enable read-only mode for the SD card

(Or, just read the `install.sh` file and execute the instructions by hand if you are paranoid)

## Boot Settings

To ensure the USB Audio device is used, the following line in `/boot/config.txt` may be necessary:

```
dtparam=audio=off
```

## Limitations

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication
- Wi-Fi needs to be disabled during playback, this is a limitation of the Raspberry Pi hardware (see raspberrypi/linux#1552)
- To permanently save paired devices, the Raspberry has to be switched to read-write mode (`mount -o remount,rw /`) until all devices have been paired once.

## References

- [c't Magazin: Raspberry in Blue](http://ct.de/yfvp)
- [BaReinhard/Super-Simple-Raspberry-Pi-Audio-Receiver-Install](https://github.com/BaReinhard/Super-Simple-Raspberry-Pi-Audio-Receiver-Install)
- [Adafruit: Read-Only Raspberry Pi](https://learn.adafruit.com/read-only-raspberry-pi/)
