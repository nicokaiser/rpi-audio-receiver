#!/bin/bash -e

echo -n "Do you want to install Bluetooth Audio (BlueALSA)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install -y --no-install-recommends alsa-base alsa-utils bluealsa bluez python-gobject python-dbus vorbis-tools sound-theme-freedesktop

# WoodenBeaver sounds
mkdir -p /usr/local/share/sounds/WoodenBeaver/stereo
if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-added.ogg ]; then
    curl -so /usr/local/share/sounds/WoodenBeaver/stereo/device-added.ogg https://raw.githubusercontent.com/madsrh/WoodenBeaver/master/WoodenBeaver/stereo/device-added.ogg
fi
if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-removed.ogg ]; then
    curl -so /usr/local/share/sounds/WoodenBeaver/stereo/device-removed.ogg https://raw.githubusercontent.com/madsrh/WoodenBeaver/master/WoodenBeaver/stereo/device-removed.ogg
fi

# Bluetooth settings
cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF

service bluetooth start
hciconfig hci0 piscan
hciconfig hci0 sspmode 1

mkdir -p /opt/local/bin

# Bluetooth agent
cat <<'EOF' > /opt/local/bin/bluetooth-agent
#!/usr/bin/python

# Automatically authenticating bluez agent.

from __future__ import absolute_import, print_function, unicode_literals

from gi.repository import GObject

import sys
import dbus
import dbus.service
import dbus.mainloop.glib

BUS_NAME = 'org.bluez'
AGENT_INTERFACE = 'org.bluez.Agent1'
AGENT_PATH = "/test/agent"

bus = None
device_obj = None
dev_path = None

def set_trusted(path):
    props = dbus.Interface(bus.get_object("org.bluez", path), "org.freedesktop.DBus.Properties")
    props.Set("org.bluez.Device1", "Trusted", True)

class Agent(dbus.service.Object):
    exit_on_release = True

    def set_exit_on_release(self, exit_on_release):
        self.exit_on_release = exit_on_release

    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Release(self):
        print("Release")
        if self.exit_on_release:
            mainloop.quit()

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        print("AuthorizeService (%s, %s)" % (device, uuid))
        set_trusted(device)
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        print("RequestPinCode (%s)" % (device))
        set_trusted(device)
        return "0000"

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        print("RequestPasskey (%s)" % (device))
        set_trusted(device)
        return dbus.UInt32("0000")

    @dbus.service.method(AGENT_INTERFACE, in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        print("DisplayPasskey (%s, %06u entered %u)" % (device, passkey, entered))

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        print("DisplayPinCode (%s, %s)" % (device, pincode))

    @dbus.service.method(AGENT_INTERFACE, in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        print("RequestConfirmation (%s, %06d)" % (device, passkey))
        set_trusted(device)
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        print("RequestAuthorization (%s)" % (device))
        set_trusted(device)
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Cancel(self):
        print("Cancel")

if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()

    capability = "NoInputNoOutput"

    path = "/test/agent"
    agent = Agent(bus, path)

    mainloop = GObject.MainLoop()

    obj = bus.get_object(BUS_NAME, "/org/bluez");
    manager = dbus.Interface(obj, "org.bluez.AgentManager1")
    manager.RegisterAgent(path, capability)

    print("Agent registered")

    manager.RequestDefaultAgent(path)

    mainloop.run()
EOF
chmod 755 /opt/local/bin/bluetooth-agent

cat <<'EOF' > /etc/systemd/system/bluetooth-agent.service
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.target bluetooth.service

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
ExecStart=/opt/local/bin/bluetooth-agent
EOF
systemctl enable bluetooth-agent.service

# ALSA settings
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf

# BlueALSA
mkdir -p /etc/systemd/system/bluealsa.service.d
cat <<'EOF' > /etc/systemd/system/bluealsa.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/bluealsa -i hci0 -p a2dp-sink
ExecStartPre=/bin/sleep 1
EOF

cat <<'EOF' > /etc/systemd/system/bluealsa-aplay.service
[Unit]
Description=BlueALSA player
Requires=bluealsa.service
After=bluealsa.service
Wants=bluetooth.target sound.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sleep 2
ExecStart=/usr/bin/bluealsa-aplay --pcm-buffer-time=250000 00:00:00:00:00:00

[Install]
WantedBy=graphical.target
EOF
systemctl daemon-reload
systemctl enable bluealsa-aplay
echo 'ACTION=="add", KERNEL=="hci0", RUN+="/bin/systemctl start bluealsa-aplay.service"' > /etc/udev/rules.d/61-bluealsa-aplay.rules

# Bluetooth udev script
cat <<'EOF' > /opt/local/bin/bluetooth-udev
#!/bin/bash
if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

if [ "$action" = "add" ]; then
    echo -e 'discoverable off\nexit\n' | bluetoothctl
    if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-added.ogg ]; then
        ogg123 -q /usr/local/share/sounds/WoodenBeaver/stereo/device-added.ogg
    fi
    # disconnect wifi to prevent dropouts
    # ifconfig wlan0 down &
fi

if [ "$action" = "remove" ]; then
    if [ ! -f /usr/local/share/sounds/WoodenBeaver/stereo/device-removed.ogg ]; then
        ogg123 -q /usr/local/share/sounds/WoodenBeaver/stereo/device-removed.ogg
    fi
    # reenable wifi
    # ifconfig wlan0 up &
    echo -e 'discoverable on\nexit\n' | bluetoothctl
fi
EOF
chmod 755 /opt/local/bin/bluetooth-udev

cat <<'EOF' > /etc/udev/rules.d/99-bluetooth-udev.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/opt/local/bin/bluetooth-udev"
EOF
