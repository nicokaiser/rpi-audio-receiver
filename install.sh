#!/bin/bash

set -e

NQPTP_VERSION="1.2.4"
SHAIRPORT_SYNC_VERSION="4.3.6"
TMP_DIR=""

cleanup() {
    if [ -d "${TMP_DIR}" ]; then
        rm -rf "${TMP_DIR}"
    fi
}

log_green() {
  local text="$1"
  GREEN="\033[0;32m"
  NORMAL=$(tput sgr0)
  printf "${GREEN} ${text}${NORMAL}\r\n"
}

log_red() {
  local text="$1"
  RED="\033[0;31m"
  NORMAL=$(tput sgr0)
  echo $text
  printf "${RED} ${text}${NORMAL}\r\n"
}

banner(){
  # Get the terminal width
  width=$(tput cols)
  # Print a line of '=' characters
  printf '=%.0s' $(seq 1 $width)
}

apt_update_netselect(){
    banner
    read -p "Do you want to change apt (netselect-apt)? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    sudo apt-get update
    log_green "installing netselect-apt and executing"
    sudo apt-get install netselect-apt -y
    sudo netselect-apt
}

update_latest(){
    sudo apt-get update 
    sudo apt-get upgrade -y
}

verify_os() {
    MSG="Unsupported OS: Raspberry Pi OS 12 (bookworm) is required."

    if [ ! -f /etc/os-release ]; then
        log_red $MSG
        banner
        exit 1
    fi

    . /etc/os-release

    if [ "$ID" != "debian" ] && [ "$ID" != "raspbian" ] || [ "$VERSION_ID" != "12" ]; then
        log_red $MSG
        banner
        exit 1
    fi
}

set_hostname() {
    if [[ -z $changeHostname ]]; then 
      if ! $changeHostname ; then return; fi

      log_green "Device Name Settings"
      banner

      CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)

      read -p "Hostname [$(hostname)]: " HOSTNAME
      sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}

      read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
      PRETTY_HOSTNAME="${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"
      sudo hostnamectl set-hostname --pretty "$PRETTY_HOSTNAME"
    fi
}

install_snapcast(){
    if [[ -z $snapclientInstall ]]; then 
      read -p "Do you want to install UPnP renderer? [y/N] " REPLY
      #https://github.com/Torgee/rpi-audio-receiver/blob/master/install-snapcast.sh
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $snapclientInstall; then return; fi

    log_green "Installing snapcast client"
    banner

    sudo apt install --no-install-recommends -y snapclient    
}

install_UPnP_renderer(){
    if [[ -z $UPnPRendererInstall ]]; then 
      read -p "Do you want to install UPnP renderer? [y/N] " REPLY
      #https://github.com/Torgee/rpi-audio-receiver/blob/master/install-upnp.sh
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $UPnPRendererInstall ; then return; fi

    log_green "Installing UPnP renderer (gmrender-resurrect)"
    banner

    sudo apt update
    sudo apt install -y --no-install-recommends gmediarender gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-alsa

    LIBRESPOT_NAME="${PRETTY_HOSTNAME// /-}"
    LIBRESPOT_NAME=${LIBRESPOT_NAME:-$(hostname)}
    sudo tee /etc/default/gmediarender >/dev/null <<EOF
ENABLED=1
DAEMON_USER="nobody:audio"
UPNP_DEVICE_NAME="${LIBRESPOT_NAME}"
INITIAL_VOLUME_DB=0.0
ALSA_DEVICE="sysdefault"
EOF

    sudo systemctl enable --now gmediarender
}

install_bluetooth() {
    if [[ -z $bluetoothInstall ]]; then 
      read -p "Do you want to install Bluetooth Audio (ALSA)? [y/N] " REPLY
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $bluetoothInstall ; then return; fi

    log_green "Bluetooth installation"
    banner

    log_green "Bluetooth: Setting Audio ALSA Backend (bluez-alsa-utils)"
    sudo apt update
    sudo apt install -y --no-install-recommends bluez-tools bluez-alsa-utils

    log_green "Bluetooth: creating basic settings"
    sudo tee /etc/bluetooth/main.conf >/dev/null <<'EOF'
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF

    log_green "Bluetooth: configuring Agent"
    sudo tee /etc/systemd/system/bt-agent@.service >/dev/null <<'EOF'
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
    sudo systemctl daemon-reload
    sudo systemctl enable bt-agent@hci0.service

    log_green "Bluetooth: installing udev script"
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

read -p "Do you want to configure Bluetooth A2DP volume? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
# Enable A2DP volume control
    sudo mkdir -p /etc/systemd/system/bluetooth.service.d
    sudo tee /etc/systemd/system/bluetooth.service.d/override.conf >/dev/null  <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/libexec/bluetooth/bluetoothd --plugin=a2dp
EOF


}

install_shairport() {
    if [[ -z $shairportInstall ]]; then 
      read -p "Do you want to install Shairport Sync (AirPlay 2 audio player)? [y/N] " REPLY
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $shairportInstall; then return; fi
    
    log_green "Installing Shairport Sync"
    banner

    sudo apt update
    sudo apt install -y --no-install-recommends wget unzip autoconf automake build-essential libtool git autoconf automake libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt20-dev xxd

    if [[ -z "$TMP_DIR" ]]; then
        TMP_DIR=$(mktemp -d)
    fi

    cd $TMP_DIR

    log_green "Shairport: Install ALAC"
    wget -O alac-master.zip https://github.com/mikebrady/alac/archive/refs/heads/master.zip
    unzip alac-master.zip
    cd alac-master
    autoreconf -fi
    ./configure
    make -j $(nproc)
    sudo make install
    sudo ldconfig
    cd ..
    rm -rf alac-master

    log_green "Shairport: Install NQPTP"
    wget -O nqptp-${NQPTP_VERSION}.zip https://github.com/mikebrady/nqptp/archive/refs/tags/${NQPTP_VERSION}.zip
    unzip nqptp-${NQPTP_VERSION}.zip
    cd nqptp-${NQPTP_VERSION}
    autoreconf -fi
    ./configure --with-systemd-startup
    make -j $(nproc)
    sudo make install
    cd ..
    rm -rf nqptp-${NQPTP_VERSION}

    log_green "Shairport: Install Shairport Sync"
    wget -O shairport-sync-${SHAIRPORT_SYNC_VERSION}.zip https://github.com/mikebrady/shairport-sync/archive/refs/tags/${SHAIRPORT_SYNC_VERSION}.zip
    unzip shairport-sync-${SHAIRPORT_SYNC_VERSION}.zip
    cd shairport-sync-${SHAIRPORT_SYNC_VERSION}
    autoreconf -fi
    ./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-apple-alac
    make -j $(nproc)
    sudo make install
    cd ..
    rm -rf shairport-sync-${SHAIRPORT_SYNC_VERSION}

    log_green "Shairport: Configure Shairport Sync"
    sudo tee /etc/shairport-sync.conf >/dev/null <<EOF
general = {
  name = "${PRETTY_HOSTNAME:-$(hostname)}";
  output_backend = "alsa";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

    sudo usermod -a -G gpio shairport-sync
    sudo systemctl enable --now nqptp
    sudo systemctl enable --now shairport-sync
}

install_raspotify() {
    if [[ -z $raspotifyInstall ]]; then 
      read -p "Do you want to install Raspotify (Spotify Connect)? [y/N] " REPLY
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $raspotifyInstall; then return; fi

    log_green "Installing Install Raspotify"
    banner

    # Install Raspotify
    curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

    log_green "Raspotify: Configure Raspotify"
    LIBRESPOT_NAME="${PRETTY_HOSTNAME// /-}"
    LIBRESPOT_NAME=${LIBRESPOT_NAME:-$(hostname)}

    sudo tee /etc/raspotify/conf >/dev/null <<EOF
LIBRESPOT_QUIET=on
LIBRESPOT_AUTOPLAY=off
LIBRESPOT_DISABLE_AUDIO_CACHE=off
LIBRESPOT_DISABLE_CREDENTIAL_CACHE=on
LIBRESPOT_ENABLE_VOLUME_NORMALISATION=on
LIBRESPOT_NAME="${LIBRESPOT_NAME}"
LIBRESPOT_DEVICE_TYPE="avr"
LIBRESPOT_BITRATE="320"
LIBRESPOT_INITIAL_VOLUME="50"
EOF

    log_green "Raspotify: daemon reload and enable"
    sudo systemctl daemon-reload
    sudo systemctl enable --now raspotify
}

trap cleanup EXIT

log_green "Raspberry Pi Audio Receiver"
banner

changeHostname=false
bluetoothInstall=false
shairportInstall=false
raspotifyInstall=false
UPnPRendererInstall=false 
snapclientInstall=false 
while getopts "nbsruc" opt; do
  case "$opt" in
    n) changeHostname=true ;;
    b) bluetoothInstall=true;;
    s) shairportInstall=true;;
    r) raspotifyInstall=true;;
    u) UPnPRendererInstall=true;;
    c) snapclientInstall=true;;
    ?) echo "script usage: $(basename $0) [-n][-b][-s][-r][-u][-c]
      -n Change Host Name
      -b Install bluetooth features
      -s Install Shairplay (Airplay support)
      -r Raspotify (Spotify support)
      -u UPnP Render Install
      -c Snapcast Client Install" 
      exit 1
      ;;
  esac
done

if (( $OPTIND == 1 )); then
  echo "Default option"
  changeHostname=""
  bluetoothInstall=""
  shairportInstall=""
  raspotifyInstall=""
  UPnPRendererInstall=""
  snapclientInstall=""
  verify_os
  apt_update_netselect
fi

set_hostname $changeHostname
install_bluetooth $bluetoothInstall
install_shairport $shairportInstall
install_raspotify $raspotifyInstall
install_snapcast $snapclientInstall
install_UPnP_renderer $UPnPRendererInstall

