#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Bluetooth Audio (BlueALSA)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install -y --no-install-recommends alsa-base alsa-utils bluealsa bluez-tools

# WoodenBeaver sounds
mkdir -p /usr/local/share/sounds/__custom
if [ ! -f /usr/local/share/sounds/__custom/device-added.wav ]; then
    cp files/device-added.wav /usr/local/share/sounds/__custom/
fi
if [ ! -f /usr/local/share/sounds/__custom/device-removed.wav ]; then
    cp files/device-removed.wav /usr/local/share/sounds/__custom/
fi

# Bluetooth settings
cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF

# Make Bluetooth discoverable after initialisation
mkdir -p /etc/systemd/system/bthelper@.service.d
cat <<'EOF' > /etc/systemd/system/bthelper@.service.d/override.conf
[Service]
Type=oneshot
ExecStartPost=/usr/bin/bluetoothctl discoverable on
ExecStartPost=/bin/hciconfig %I piscan
ExecStartPost=/bin/hciconfig %I sspmode 1
#ExecStartPost=/bin/hciconfig %I sspmode 0 # Use PIN for pairing
EOF

cat <<'EOF' > /etc/systemd/system/bt-agent.service
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
#ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput --pin /etc/bluetooth/pin.conf
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF
systemctl enable bt-agent.service

# ALSA settings
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf

# BlueALSA
mkdir -p /etc/systemd/system/bluealsa.service.d
cat <<'EOF' > /etc/systemd/system/bluealsa.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/bluealsa -i hci0 -p a2dp-sink
RestartSec=5
Restart=always
EOF

cat <<'EOF' > /etc/systemd/system/bluealsa-aplay.service
[Unit]
Description=BlueALSA aplay
Requires=bluealsa.service
After=bluealsa.service sound.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sleep 2
ExecStart=/usr/bin/bluealsa-aplay --pcm-buffer-time=250000 00:00:00:00:00:00
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable bluealsa-aplay

# Bluetooth udev script
cat <<'EOF' > /usr/local/bin/bluetooth-udev
#!/bin/bash
if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

if [ "$action" = "add" ]; then
    bluetoothctl discoverable off
    if [ -f /usr/local/share/sounds/__custom/device-added.wav ]; then
        aplay -q /usr/local/share/sounds/__custom/device-added.wav
    fi
    # disconnect wifi to prevent dropouts
    #ifconfig wlan0 down &
fi

if [ "$action" = "remove" ]; then
    if [ -f /usr/local/share/sounds/__custom/device-removed.wav ]; then
        aplay -q /usr/local/share/sounds/__custom/device-removed.wav
    fi
    # reenable wifi
    #ifconfig wlan0 up &
    bluetoothctl discoverable on
fi
EOF
chmod 755 /usr/local/bin/bluetooth-udev

cat <<'EOF' > /etc/udev/rules.d/99-bluetooth-udev.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluetooth-udev"
EOF
