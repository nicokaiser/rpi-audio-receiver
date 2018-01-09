#!/bin/bash

if [ $(id -u) -ne 0 ]; then
    echo "Installer must be run as root."
    echo "Try 'sudo bash $0'"
    exit 1
fi

clear

echo "This script installs A2DP packages on a Raspbian Stretch installation."
echo
echo -n "CONTINUE? [y/N] "
read
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then
    echo "Canceled."
    exit 0
fi

if ! ([ -f /etc/os-release ] || cat /etc/os-release | grep "stretch" > /dev/null); then
    echo "Unsupported distribution"
    exit 1
fi

echo "Updating package index files..."
apt update

echo "Upgrading packages..."
apt upgrade -y

echo "Installing packages..."
apt install -y --no-install-recommends alsa-base alsa-utils pulseaudio pulseaudio-module-bluetooth bluez python-gobject python-dbus vorbis-tools sound-theme-freedesktop

echo "Updating Raspberry Pi firmware..."
SKIP_BACKUP=1 PRUNE_MODULES=1 rpi-update

echo "Configuring system..."

# Hostname
echo 'PRETTY_HOSTNAME="Raspberry Pi"' > /etc/machine-info

# Bluetooth settings
mv /etc/bluetooth/main.conf /etc/bluetooth/main.conf.orig
cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200400
DiscoverableTimeout = 0
PairableTimeout = 0

[Policy]
AutoEnable=true
EOF
service bluetooth start
hciconfig hci0 piscan
hciconfig hci0 sspmode 1

# ALSA settings
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf

# PulseAudio settings
mv /etc/pulse/daemon.conf /etc/pulse/daemon.conf.orig
echo "resample-method = ffmpeg" > /etc/pulse/daemon.conf
sed -i.orig 's/^load-module module-udev-detect$/load-module module-udev-detect tsched=0/' /etc/pulse/default.pa 

# /home/pi/disable-wifi.sh
cat <<'EOF' > /home/pi/disable-wifi.sh
#!/bin/sh
sleep 60
if [ -f "/usr/share/sounds/freedesktop/stereo/device-removed.oga" ] ; then
    ogg123 -q -d wav -f - /usr/share/sounds/freedesktop/stereo/device-removed.oga | aplay -q - &
fi
echo Disabling Wi-Fi
sudo -n ifconfig wlan0 down
EOF
chown pi:pi /home/pi/disable-wifi.sh
chmod 755 /home/pi/disable-wifi.sh

# /home/pi/.profile
cp -a /home/pi/.profile /home/pi/.profile.orig
cat <<'EOF' >> /home/pi/.profile
if ! [ -n "$SSH_CLIENT" ] && ! [ -n "$SSH_TTY" ]; then
    pulseaudio --start
    ~/disable-wifi.sh &
    if [ -f "/usr/share/sounds/freedesktop/stereo/service-login.oga" ] ; then
        ogg123 -q -d wav -f - /usr/share/sounds/freedesktop/stereo/service-login.oga | aplay -q - &
    fi
    ~/simple-agent &
else
    killall -q disable-wifi.sh
fi
EOF
chown pi:pi /home/pi/.profile

# /home/pi/simple-agent
cat <<'EOF' > /home/pi/simple-agent
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
chown pi.pi /home/pi/simple-agent
chmod 755 /home/pi/simple-agent

# Auto login
cat <<'EOF' > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I 38400 linux
EOF

# Read-only mode
wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/read-only-fs.sh
bash read-only-fs.sh
mkdir -p /home/pi/.config
echo "tmpfs /home/pi/.config tmpfs nodev,nosuid,mode=1777,uid=pi 0 0" >> /etc/fstab

echo "Done".
echo
echo -n "REBOOT NOW? [y/N] "
read
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then
    echo "Exiting without reboot."
    exit 0
fi
echo "Reboot started..."
reboot
exit 0
