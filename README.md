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
echo 'PRETTY_HOSTNAME="Raspberry Pi"' > /etc/machine-info
```

### Bluetooth settings

```
mv /etc/bluetooth/main.conf /etc/bluetooth/main.conf.orig
cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
DiscoverableTimeout = 0
PairableTimeout = 0

[Policy]
AutoEnable=true
EOF

service bluetooth start
hciconfig hci0 piscan
hciconfig hci0 sspmode 1
```

### Bluetooth agent

Install a simple agent that accepts every connection:

```
cat <<'EOF' > /usr/local/bin/simple-agent.autotrust
#!/usr/bin/python

#Automatically authenticating bluez agent. Script modifications by Merlin Schumacher <mls@ct.de> for c't Magazin (www.ct.de)

from __future__ import absolute_import, print_function, unicode_literals

from optparse import OptionParser
import sys
import dbus
import dbus.service
import dbus.mainloop.glib
try:
  from gi.repository import GObject
except ImportError:
  import gobject as GObject

SERVICE_NAME = "org.bluez"
ADAPTER_INTERFACE = SERVICE_NAME + ".Adapter1"
DEVICE_INTERFACE = SERVICE_NAME + ".Device1"

def get_managed_objects():
    bus = dbus.SystemBus()
    manager = dbus.Interface(bus.get_object("org.bluez", "/"),
                "org.freedesktop.DBus.ObjectManager")
    return manager.GetManagedObjects()

def find_adapter(pattern=None):
    return find_adapter_in_objects(get_managed_objects(), pattern)

def find_adapter_in_objects(objects, pattern=None):
    bus = dbus.SystemBus()
    for path, ifaces in objects.iteritems():
        adapter = ifaces.get(ADAPTER_INTERFACE)
        if adapter is None:
            continue
        if not pattern or pattern == adapter["Address"] or \
                            path.endswith(pattern):
            obj = bus.get_object(SERVICE_NAME, path)
            return dbus.Interface(obj, ADAPTER_INTERFACE)
    raise Exception("Bluetooth adapter not found")

def find_device(device_address, adapter_pattern=None):
    return find_device_in_objects(get_managed_objects(), device_address,
                                adapter_pattern)

def find_device_in_objects(objects, device_address, adapter_pattern=None):
    bus = dbus.SystemBus()
    path_prefix = ""
    if adapter_pattern:
        adapter = find_adapter_in_objects(objects, adapter_pattern)
        path_prefix = adapter.object_path
    for path, ifaces in objects.iteritems():
        device = ifaces.get(DEVICE_INTERFACE)
        if device is None:
            continue
        if (device["Address"] == device_address and
                        path.startswith(path_prefix)):
            obj = bus.get_object(SERVICE_NAME, path)
            return dbus.Interface(obj, DEVICE_INTERFACE)

    raise Exception("Bluetooth device not found")



BUS_NAME = 'org.bluez'
AGENT_INTERFACE = 'org.bluez.Agent1'
AGENT_PATH = "/test/agent"

bus = None
device_obj = None
dev_path = None

def ask(prompt):
    try:
        return raw_input(prompt)
    except:
        return input(prompt)

def set_trusted(path):
    props = dbus.Interface(bus.get_object("org.bluez", path),
                    "org.freedesktop.DBus.Properties")
    props.Set("org.bluez.Device1", "Trusted", True)

def dev_connect(path):
    dev = dbus.Interface(bus.get_object("org.bluez", path),
                            "org.bluez.Device1")
    dev.Connect()

class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"

class Agent(dbus.service.Object):
    exit_on_release = True

    def set_exit_on_release(self, exit_on_release):
        self.exit_on_release = exit_on_release

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="", out_signature="")
    def Release(self):
        print("Release")
        if self.exit_on_release:
            mainloop.quit()

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        print("AuthorizeService (%s, %s)" % (device, uuid))
        set_trusted(device)
        return

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        print("RequestPinCode (%s)" % (device))
        set_trusted(device)
        return "1234"

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        print("RequestPasskey (%s)" % (device))
        set_trusted(device)
        passkey = ask("Enter passkey: ")
        return dbus.UInt32(passkey)

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        print("DisplayPasskey (%s, %06u entered %u)" %
                        (device, passkey, entered))

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        print("DisplayPinCode (%s, %s)" % (device, pincode))

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        print("RequestConfirmation (%s, %06d)" % (device, passkey))
        set_trusted(device)
        return

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        print("RequestAuthorization (%s)" % (device))
        set_trusted(device)
        return

    @dbus.service.method(AGENT_INTERFACE,
                    in_signature="", out_signature="")
    def Cancel(self):
        print("Cancel")

def pair_reply():
    print("Device paired")
    set_trusted(dev_path)
    dev_connect(dev_path)
    mainloop.quit()

def pair_error(error):
    err_name = error.get_dbus_name()
    if err_name == "org.freedesktop.DBus.Error.NoReply" and device_obj:
        print("Timed out. Cancelling pairing")
        device_obj.CancelPairing()
    else:
        print("Creating device failed: %s" % (error))


    mainloop.quit()

if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()

    capability = "NoInputNoOutput"

    parser = OptionParser()
    parser.add_option("-i", "--adapter", action="store",
                    type="string",
                    dest="adapter_pattern",
                    default=None)
    parser.add_option("-c", "--capability", action="store",
                    type="string", dest="capability")
    parser.add_option("-t", "--timeout", action="store",
                    type="int", dest="timeout",
                    default=60000)
    (options, args) = parser.parse_args()
    if options.capability:
        capability  = options.capability

    path = "/test/agent"
    agent = Agent(bus, path)

    mainloop = GObject.MainLoop()

    obj = bus.get_object(BUS_NAME, "/org/bluez");
    manager = dbus.Interface(obj, "org.bluez.AgentManager1")
    manager.RegisterAgent(path, capability)

    print("Agent registered")

    if len(args) > 0 and args[0].startswith("hci"):
        options.adapter_pattern = args[0]
        del args[:1]

    if len(args) > 0:
        device = find_device(args[0],
                        options.adapter_pattern)
        dev_path = device.object_path
        agent.set_exit_on_release(False)
        device.Pair(reply_handler=pair_reply, error_handler=pair_error,
                                timeout=60000)
        device_obj = device
    else:
        manager.RequestDefaultAgent(path)

    mainloop.run()
EOF

chmod 755 /usr/local/bin/simple-agent.autotrust

cat <<'EOF' > /etc/systemd/system/bluetooth-agent.service
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.target bluetooth.service

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/simple-agent.autotrust
EOF

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
cat <<'EOF' > /etc/systemd/system/bluealsa.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/bluealsa --disable-hfp --disable-hsp
EOF

cat <<'EOF' > /etc/systemd/system/bluealsa-aplay.service
[Unit]
Description=BlueALSA player
Wants=bluealsa.service
After=bluealsa.service

[Service]
Type=simple
User=root
ExecStartPre=/bin/sleep 2
ExecStart=/usr/bin/bluealsa-aplay --pcm-buffer-time=250000 00:00:00:00:00:00
Restart=on-failure

[Install]
WantedBy=graphical.target
EOF
systemctl enable bluealsa-aplay
```

#### Bluetooth udev script

Install a udev script that disables discoverability while connected:

```
cat <<'EOF' > /usr/local/bin/bluez-udev
#!/bin/bash
name=$(sed 's/\"//g' <<< $NAME)
if [[ ! $name =~ ^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$ ]]; then exit 0;  fi

bt_name=`grep Name /var/lib/bluetooth/*/$name/info | awk -F'=' '{print $2}'`

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")
logger "Action: $action"

if [ "$action" = "add" ]; then
    logger "[$(basename $0)] Bluetooth device is being added [$name] - $bt_name"
    bluetoothctl << EOT
discoverable off
EOT
    #espeak "Device, $bt_name Connected"
    #ogg123 -q -d pulse /usr/share/sounds/freedesktop/stereo/device-added.oga
    #ifconfig wlan0 down
fi

if [ "$action" = "remove" ]; then
    logger "[$(basename $0)] Bluetooth device is being removed [$name] - $bt_name"
    #ifconfig wlan0 up
    #espeak "Device, $bt_name Disconnected"
    #ogg123 -q -d pulse /usr/share/sounds/freedesktop/stereo/device-removed.oga
    bluetoothctl << EOT
discoverable on
EOT
fi
EOF

chmod 755 /usr/local/bin/bluez-udev

cat <<'EOF' > /etc/udev/rules.d/99-input.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluez-udev"
EOF
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
mv /etc/shairport-sync.conf /etc/shairport-sync.conf.orig

cat <<'EOF' > /etc/shairport-sync.conf
general = {
    name = "AirPi";
    output_backend = "alsa";
    volume_range_db = 30;
}
EOF

usermod -a -G gpio shairport-sync
```

## pivumeter

When using a HAT device like [Blinkt!](https://shop.pimoroni.com/products/blinkt):

```
dpkg -i files/pivumeter_1.0-1_armhf.deb

cat <<'EOF' > /etc/asound.conf
pcm.!default {
        type plug
        slave.pcm "softvol_and_pivumeter"
        #slave.pcm "dmixer"
}

pcm.dsp0 {
        type plug
        slave.pcm "softvol_and_pivumeter"
        #slave.pcm "dmixer"
}

ctl.!default {
        type hw
        card 0
}

pcm.dmixer {
        type dmix
        ipc_key 1024
        ipc_key_add_uid false
        ipc_perm 0666
        slave {
                pcm "hw:0,0"
                period_time 0
                period_size 1024
                buffer_size 8192
                rate 44100
        }
        bindings {
                0 0
                1 1
        }
}

pcm.pivumeter {
        type meter
        slave.pcm "hw:0,0"
        scopes.0 pivumeter
}

pcm.softvol_and_pivumeter {
        type softvol
        slave.pcm "pivumeter"
        control {
                name "PCM"
                card 0
        }
}

pcm_scope.pivumeter {
        type pivumeter
        decay_ms 500
        peak_ms 400
        brightness 16
        bar_reverse 0
        output_device blinkt
}

pcm_scope_type.pivumeter {
        lib /usr/lib/arm-linux-gnueabihf/libpivumeter.so
}
EOF
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
