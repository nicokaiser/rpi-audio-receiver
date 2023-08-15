#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Bluetooth Audio (ALSA)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

## Bluetooth Audio ALSA Backend (bluez-alsa-utils)
apt install -y --no-install-recommends autoconf automake build-essential libtool alsa-utils bluez-tools libasound2-dev libbluetooth-dev libdbus-1-dev libglib2.0-dev libsbc-dev libldacbt-enc-dev libldacbt-abr-dev libopenaptx-dev libfdk-aac-dev
wget -O bluez-alsa-4.1.1.zip https://github.com/arkq/bluez-alsa/archive/refs/tags/v4.1.1.zip
unzip bluez-alsa-4.1.1.zip
cd bluez-alsa-4.1.1
autoreconf -fi
./configure --enable-ldac --enable-aptx --with-libopenaptx --enable-ofono --enable-systemd --enable-aac
make -j $(nproc)
make install
cd ..
rm -rf bluez-alsa-4.1.1
systemctl enable bluealsa
systemctl enable bluealsa-aplay

# Bluetooth settings
cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF

# Bluetooth Agent
cat <<'EOF' > /etc/systemd/system/bt-agent@.service
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStartPre=/usr/bin/bluetoothctl discoverable on
ExecStartPre=/bin/hciconfig %I piscan
ExecStartPre=/bin/hciconfig %I sspmode 1
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable bt-agent@hci0.service

# Bluetooth udev script
cat <<'EOF' > /usr/local/bin/bluetooth-udev
#!/bin/bash
if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

if [ "$action" = "add" ]; then
    bluetoothctl discoverable off
    # disconnect wifi to prevent dropouts
    #ifconfig wlan0 down &
fi

if [ "$action" = "remove" ]; then
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
