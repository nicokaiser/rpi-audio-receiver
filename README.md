# Raspberry Pi Bluetooth & AirPlay Receiver

A simple, light weight Bluetooth Audio (A2DP) receiver based on Raspbian, BlueZ and ALSA.

## Features

Devices like phones, tablets and computers can play audio via this receiver.

## Requirements

- Raspberry Pi with Bluetooth support (tested wth Raspberry Pi Zero W) or USB dongle
- Raspbian Stretch Lite (tested with version 2017-11-29)
- USB or I2S Audio adapter (tested with [Adafruit USB Audio Adapter](https://www.adafruit.com/product/1475) and [pHAT DAC](https://shop.pimoroni.de/products/phat-dac))

## Installation

All commands must be run as root, so become root first with

```
sudo su -
```

### Update and install packages

```
apt update
apt upgrade -y
apt install -y --no-install-recommends alsa-base alsa-utils bluealsa bluez python-gobject python-dbus vorbis-tools sound-theme-freedesktop
SKIP_BACKUP=1 PRUNE_MODULES=1 rpi-update
```

### Configure hostname

This is how the device is seen by other Bluetooth devices.

```
cp -b etc/machine-info /etc
```

### Bluetooth settings

```
cp -b etc/bluetooth/main.conf /etc/bluetooth
service bluetooth start
hciconfig hci0 piscan
hciconfig hci0 sspmode 1
```

### Bluetooth agent

Install a simple agent that accepts every connection:

```
cp -b usr/local/bin/simple-agent.autotrust /usr/local/bin
chmod 755 /usr/local/bin/simple-agent.autotrust
cp -b etc/systemd/system/bluetooth-agent.service /etc/systemd/system
systemctl enable bluetooth-agent.service
```

### ALSA settings

Make USB audio device the default:

```
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf
```

#### BlueALSA

Override BlueALSA script to disable HFP/HSP and the depend on Bluetooth device:

```
mkdir -p /etc/systemd/system/bluealsa.service.d
cp -b etc/systemd/system/bluealsa.service.d/override.conf /etc/systemd/system/bluealsa.service.d
cp -b etc/systemd/system/bluealsa-aplay.service /etc/systemd/system
systemctl enable bluealsa-aplay
```

#### Bluetooth udev script

Install a udev script that disables discoverability while connected:

```
cp -b usr/local/bin/bluez-udev /usr/local/bin
chmod 755 /usr/local/bin/bluez-udev

cp -b etc/udev/rules.d/99-input.rules /etc/udev/rules.d
```

### Read-only mode

```
wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/read-only-fs.sh
bash read-only-fs.sh

ln -s /tmp /var/lib/dhcpcd5
systemctl disable apt-daily-upgrade.service
systemctl disable apt-daily-upgrade.timer

rm /var/lib/systemd/random-seed
ln -s /tmp/random-seed /var/lib/systemd/random-seed

cat <<'EOF' > /etc/systemd/system/systemd-random-seed.service.d/override.conf
[Service]
ExecStartPre=/bin/echo "" > /tmp/random-seed
EOF
```

## AirPlay settings

Enable AirPlay via Wi-Fi using [Shairport Sync](https://github.com/mikebrady/shairport-sync):

```
apt install -y --no-install-recommends shairport-sync
cp -b etc/shairport-sync.conf /etc
usermod -a -G gpio shairport-sync
```

## pivumeter

When using a HAT device like [Blinkt!](https://shop.pimoroni.com/products/blinkt):

```
dpkg -i files/pivumeter_1.0-1_armhf.deb
cp -b etc/asound.conf.pivumeter /etc
```

## Boot Settings

To ensure the USB Audio device is used, the following line in `/boot/config.txt` may be necessary:

```
dtparam=audio=off
gpu_mem=32
#dtoverlay=pi3-disable-bt
dtoverlay=hifiberry-dac
```

## Limitations

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication
- To permanently save paired devices, the Raspberry has to be switched to read-write mode (`mount -o remount,rw /`) until all devices have been paired once.

## References

- [c't Magazin: Raspberry in Blue](http://ct.de/yfvp)
- [BaReinhard/Super-Simple-Raspberry-Pi-Audio-Receiver-Install](https://github.com/BaReinhard/Super-Simple-Raspberry-Pi-Audio-Receiver-Install)
- [Adafruit: Read-Only Raspberry Pi](https://learn.adafruit.com/read-only-raspberry-pi/)
