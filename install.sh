#!/bin/bash

set -e

NQPTP_VERSION="1.2.4"
SHAIRPORT_SYNC_VERSION="4.3.5"
TMP_DIR=""

cleanup() {
    if [ -d "${TMP_DIR}" ]; then
        rm -rf "${TMP_DIR}"
    fi
}

verify_os() {
    MSG="Unsupported OS: Raspberry Pi OS 12 (bookworm) or Debian 13 (trixie) is required."

    if [ ! -f /etc/os-release ]; then
        echo $MSG
        exit 1
    fi

    . /etc/os-release

    # Support both Debian 12 (bookworm) and Debian 13 (trixie)
    if [[ ("$ID" != "debian" && "$ID" != "raspbian") || ! ("$VERSION_ID" == "12" || "$VERSION_ID" == "13") ]]; then
        echo $MSG
        exit 1
    fi
    
    echo "Detected: $PRETTY_NAME"
}

set_hostname() {
    CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)

    read -p "Hostname [$(hostname)]: " HOSTNAME
    
    # Check if raspi-config is available (Raspberry Pi OS)
    if command -v raspi-config &> /dev/null; then
        sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}
    else
        # Fallback for Debian without raspi-config
        NEW_HOSTNAME=${HOSTNAME:-$(hostname)}
        echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null
        sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    fi

    read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
    PRETTY_HOSTNAME="${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"
    sudo hostnamectl set-hostname --pretty "$PRETTY_HOSTNAME"
}

install_bluetooth() {
    read -p "Do you want to install Bluetooth Audio (ALSA)? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi

    echo "Installing Bluetooth Audio packages..."
    
    # Bluetooth Audio ALSA Backend (bluez-alsa-utils)
    sudo apt update
    sudo apt install -y --no-install-recommends bluez bluez-tools bluez-alsa-utils

    # Bluetooth settings - Updated for better compatibility
    sudo tee /etc/bluetooth/main.conf >/dev/null <<'EOF'
[General]
Class = 0x200414
DiscoverableTimeout = 0
PairableTimeout = 0
Name = Raspberry Pi

[Policy]
AutoEnable=true
EOF

    # Bluetooth Agent - Updated for Debian 13 compatibility
    sudo tee /etc/systemd/system/bt-agent@.service >/dev/null <<'EOF'
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStartPre=/bin/sleep 2
ExecStartPre=/usr/bin/bluetoothctl power on
ExecStartPre=/usr/bin/bluetoothctl discoverable on
ExecStartPre=/usr/bin/bluetoothctl pairable on
ExecStartPre=/bin/hciconfig %I piscan
ExecStartPre=/bin/hciconfig %I sspmode 1
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable bt-agent@hci0.service

    # Bluetooth udev script
    sudo tee /usr/local/bin/bluetooth-udev >/dev/null <<'EOF'
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
    sudo chmod 755 /usr/local/bin/bluetooth-udev

    sudo tee /etc/udev/rules.d/99-bluetooth-udev.rules >/dev/null <<'EOF'
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluetooth-udev"
EOF

    # Ensure bluetooth is unblocked
    sudo rfkill unblock bluetooth
    
    echo "Bluetooth Audio installed successfully!"
}

install_shairport() {
    read -p "Do you want to install Shairport Sync (AirPlay 2 audio player)? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi

    echo "Installing Shairport Sync dependencies..."
    
    sudo apt update
    sudo apt install -y --no-install-recommends wget unzip autoconf automake build-essential libtool git libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt20-dev xxd

    if [[ -z "$TMP_DIR" ]]; then
        TMP_DIR=$(mktemp -d)
    fi

    cd $TMP_DIR

    echo "Building ALAC..."
    # Install ALAC
    wget -O alac-master.zip https://github.com/mikebrady/alac/archive/refs/heads/master.zip
    unzip -q alac-master.zip
    cd alac-master
    autoreconf -fi
    ./configure
    make -j $(nproc)
    sudo make install
    sudo ldconfig
    cd ..
    rm -rf alac-master

    echo "Building NQPTP..."
    # Install NQPTP
    wget -O nqptp-${NQPTP_VERSION}.zip https://github.com/mikebrady/nqptp/archive/refs/tags/${NQPTP_VERSION}.zip
    unzip -q nqptp-${NQPTP_VERSION}.zip
    cd nqptp-${NQPTP_VERSION}
    autoreconf -fi
    ./configure --with-systemd-startup
    make -j $(nproc)
    sudo make install
    cd ..
    rm -rf nqptp-${NQPTP_VERSION}

    echo "Building Shairport Sync..."
    # Install Shairport Sync
    wget -O shairport-sync-${SHAIRPORT_SYNC_VERSION}.zip https://github.com/mikebrady/shairport-sync/archive/refs/tags/${SHAIRPORT_SYNC_VERSION}.zip
    unzip -q shairport-sync-${SHAIRPORT_SYNC_VERSION}.zip
    cd shairport-sync-${SHAIRPORT_SYNC_VERSION}
    autoreconf -fi
    ./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-apple-alac
    make -j $(nproc)
    sudo make install
    cd ..
    rm -rf shairport-sync-${SHAIRPORT_SYNC_VERSION}

    # Configure Shairport Sync
    sudo tee /etc/shairport-sync.conf >/dev/null <<EOF
general = {
  name = "${PRETTY_HOSTNAME:-$(hostname)}";
  output_backend = "alsa";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

    # Add shairport-sync user to gpio group if it exists
    if getent group gpio > /dev/null 2>&1; then
        sudo usermod -a -G gpio shairport-sync
    fi
    
    sudo systemctl enable --now nqptp
    sudo systemctl enable --now shairport-sync
    
    echo "Shairport Sync installed successfully!"
}

install_raspotify() {
    read -p "Do you want to install Raspotify (Spotify Connect)? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi

    echo "Installing Raspotify..."
    
    # Install Raspotify
    curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

    # Configure Raspotify
    LIBRESPOT_NAME="${PRETTY_HOSTNAME// /-}"
    LIBRESPOT_NAME=${LIBRESPOT_NAME:-$(hostname)}

    sudo tee /etc/raspotify/conf >/dev/null <<EOF
LIBRESPOT_QUIET=on
LIBRESPOT_AUTOPLAY=on
LIBRESPOT_DISABLE_AUDIO_CACHE=on
LIBRESPOT_DISABLE_CREDENTIAL_CACHE=on
LIBRESPOT_ENABLE_VOLUME_NORMALISATION=on
LIBRESPOT_NAME="${LIBRESPOT_NAME}"
LIBRESPOT_DEVICE_TYPE="avr"
LIBRESPOT_BITRATE="320"
LIBRESPOT_INITIAL_VOLUME="100"
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable raspotify
    
    echo "Raspotify installed successfully!"
}

configure_audio_output() {
    echo ""
    echo "Audio Output Configuration"
    echo "1) Auto (let system decide)"
    echo "2) Headphone jack (3.5mm)"
    echo "3) HDMI"
    read -p "Select audio output [1]: " AUDIO_CHOICE
    
    case ${AUDIO_CHOICE:-1} in
        2)
            if command -v raspi-config &> /dev/null; then
                sudo raspi-config nonint do_audio 1
            else
                # Fallback for systems without raspi-config
                amixer cset numid=3 1 2>/dev/null || echo "Note: Could not set audio output automatically"
            fi
            echo "Audio output set to headphone jack"
            ;;
        3)
            if command -v raspi-config &> /dev/null; then
                sudo raspi-config nonint do_audio 2
            else
                amixer cset numid=3 2 2>/dev/null || echo "Note: Could not set audio output automatically"
            fi
            echo "Audio output set to HDMI"
            ;;
        *)
            echo "Audio output set to auto"
            ;;
    esac
}

print_summary() {
    echo ""
    echo "============================================"
    echo "Installation Complete!"
    echo "============================================"
    echo ""
    echo "Your Raspberry Pi is now configured as an audio receiver."
    echo ""
    echo "Please reboot for all changes to take effect:"
    echo "  sudo reboot"
    echo ""
    echo "After reboot, your device will be discoverable as:"
    echo "  '${PRETTY_HOSTNAME:-Raspberry Pi}'"
    echo ""
    echo "============================================"
}

trap cleanup EXIT

echo "============================================"
echo "Raspberry Pi Audio Receiver Setup"
echo "============================================"
echo ""

verify_os
set_hostname
configure_audio_output
install_bluetooth
install_shairport
install_raspotify
print_summary
