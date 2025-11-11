#!/usr/bin/env bash

###################################################
###################################################
#              Scripting Settings                 #
###################################################
###################################################

#Run apt in non-interactive mode, assume default answers.
export DEBIAN_FRONTEND=noninteractive
#Cause the script to fail if and error code is provided (set -e)
#Cause the script to fail if an error code is provided while pipping commands (set -o pipefail)
#Cause the script to fail when encountering undefined variable (set -u)
#DEBUG MODE for Development only, Cause the script to print out every command executed (set -x)
set -eu -o pipefail
# set -x
###################################################
###################################################
#               Global Variables                  #
###################################################
###################################################

# Setting default options for function execution
changeHostname=false
bluetoothInstall=false
shairportInstall=false
raspotifyInstall=false
UPnPRendererInstall=false
snapclientInstall=false

#Text Color and Formatting Variables
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
# NORMAL='\033[0m' # No Color
NORMAL=$(tput sgr0) # No Color

#Version config
NQPTP_VERSION="1.2.4"
SHAIRPORT_SYNC_VERSION="4.3.6"

#Set hostname
PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}
TMP_DIR=""
###################################################
###################################################
#               Function Definitions              #
###################################################
###################################################


function cleanup() {
    if [ -d "${TMP_DIR}" ]; then
        rm -rf "${TMP_DIR}"
    fi
}

function log_green() {
  local text="$1"
  printf "${GREEN} ${text}${NORMAL}\r\n"
}
function log_blue() {
  local text="$1"
  echo $text
  printf "${RED} ${text}${NORMAL}\r\n"
}
function log_red() {
  local text="$1"
  printf "${RED} ${text}${NORMAL}\r\n"
}
function log_yellow() {
  local text="$1"
  printf "${YELLOW} ${text}${NORMAL}\r\n"
}
function banner(){
  # Get the terminal width
  width=$(tput cols)
  # Print a line of '=' characters
  printf "${GREEN}=%.0s" $(seq 1 $width);printf "${NORMAL}"
}

function heading(){
    local text="$1"
    banner
    printf "${YELLOW}#  %s%*s\n" "$1" $((40 - ${#1})) " #${NORMAL}"
    banner
}

function askQuestion() {
  local prompt="$1"
  local response
  read -p "$(echo -e "${YELLOW}${prompt}${NORMAL}")" response
  echo "$response"
}

#### To do, find the raspbian equivalent of netselect-apt
#### netselect-apt doesn't seem to work on rpi os
#     # netselect on rpi doesn't seem to actually change /etc/apt/sources.list
#     # commenting out until i figure out why
# apt_update_netselect(){
#     banner
#     read -p "Do you want to change apt (netselect-apt)? [y/N] " REPLY
#     if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
#     sudo apt-get update
#     log_green "installing netselect-apt and executing"
#     sudo apt-get install netselect-apt -y
#     sudo netselect-apt
# }

function update_latest(){
    sudo apt-get update
    sudo apt-get upgrade -y
}

function verify_os() {
    MSG="Unsupported OS: Minimum Raspberry Pi OS 12 (bookworm) is required."

    if [ ! -f /etc/os-release ]; then
        log_red $MSG
        banner
        exit 1
    fi

    . /etc/os-release

    if { [ "$ID" != "debian" ] && [ "$ID" != "raspbian" ]; } || [ "$VERSION_ID" -lt 12 ]; then
        log_red "$MSG"
        banner
        exit 1
    fi
}

function verify_raspberryZero(){
    MODEL=$(grep Model /proc/cpuinfo | awk -F: '{ gsub(/^ +| +$/, "", $2) ;print $2}')
    if [[ "$MODEL" == *" Zero "* ]]; then
      log_blue "dtCooper's version does not support Raspberry Pi Zero at this stage."
      return 0
    else
      log_blue "Device detected as ${MODEL}"
      return 1
    fi
}

function set_hostname() {
    if [[ -z $changeHostname ]]; then
      REPLY=$(askQuestion "Do you want to Change Hostname [y/N] " )
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
      if ! $changeHostname ; then return; fi

      heading "Device Name Settings"

      CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)

      read -p "Hostname [$(hostname)]: " HOSTNAME
      sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}

      eRCH=$(uname -m)
      read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
      PRETTY_HOSTNAME="${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"
      sudo hostnamectl set-hostname --pretty "$PRETTY_HOSTNAME"
}

function install_snapcast(){
    if [[ -z $snapclientInstall ]]; then
      REPLY=$(askQuestion "Do you want to install a snapcast client? [y/N] " )
      # read -p "Do you want to install a snapcast client? [y/N] " REPLY
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $snapclientInstall; then return; fi

    heading "Installing snapcast client"

    sudo apt install --no-install-recommends -y snapclient
}

function install_UPnP_renderer(){
    if [[ -z $UPnPRendererInstall ]]; then
      REPLY=$(askQuestion "Do you want to install UPnP renderer? [y/N] " )
      # read -p "Do you want to install UPnP renderer? [y/N] " REPLY
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $UPnPRendererInstall ; then return; fi

    log_green "Installing UPnP renderer (gmrender-resurrect)"
    banner

    # sudo apt update
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

function install_bluetooth() {
    if [[ -z $bluetoothInstall ]]; then
      REPLY=$(askQuestion "Do you want to install Bluetooth Audio (ALSA)? [y/N] " )
      # read -p "Do you want to install Bluetooth Audio (ALSA)? [y/N] " REPLY
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $bluetoothInstall ; then return; fi

    heading "Bluetooth installation"

    log_green "Bluetooth: Installing Audio ALSA Backend (bluez-alsa-utils)"
    # sudo apt update
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

sudo systemctl daemon-reload

log_blue "Disabled due to unreliable results for bluetooth.service naming and bluetoothctl agent configuration"
#read -p "Do you want to configure Bluetooth A2DP volume? [y/N] " REPLY
#if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
#  # Enable A2DP volume control
#    log_green "Bluetooth: Installing Audio Pulse Audio"
#    sudo apt-get install alsa-utils bluez bluez-tools pulseaudio-module-bluetooth
#
#    sudo mkdir -p /etc/systemd/system/bluetooth.service.d
#    sudo tee /etc/systemd/system/bluetooth.service.d/override.conf >/dev/null  <<'EOF'
#[Service]
#ExecStart=
#ExecStart=/usr/libexec/bluetooth/bluetoothd --plugin=a2dp
#EOF
#sudo systemctl daemon-reload
#sudo systemctl restart bluetooth.service
#
}

function install_shairport() {
    if [[ -z $shairportInstall ]]; then
      REPLY=$(askQuestion "Do you want to install Shairport Sync (AirPlay 2 audio player)? [y/N] " )
      #read -p "Do you want to install Shairport Sync (AirPlay 2 audio player)? [y/N] " REPLY
      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $shairportInstall; then return; fi
    heading "Installing Shairport Sync"

    # sudo apt update
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

function install_raspotify() {
    if [[ -z $raspotifyInstall ]]; then
      REPLY=$(askQuestion "Do you want to install Raspotify (Spotify Connect)? [y/N] " )
      #read -p "Do you want to install Raspotify (Spotify Connect)? [y/N] " REPLY

      if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi
    fi
    if ! $raspotifyInstall; then return; fi

    heading "Installing Install Raspotify"
    if ! verify_raspberryZero; then
        # If you can, then pull and execute the dtcooper version
        log_blue "Pulling dtcooper raspotify"
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

    else
        # If it's RPI Zero, then install the GO version of Raspotify
        # Verify system archtecture and download the right version
        ARCH=$(uname -m)

        if [ $ARCH = "armv6l" ]; then
		ARCH="armv6_rpi"
        elif [ $ARCH = "armv7l" ] || [ $ARCH = "armv8" ] || [ $ARCH = "armhf" ]; then
		ARCH="armv6"
        elif [ $ARCH = "arm64" ] || [ $ARCH = "aarch64" ]; then
		ARCH="arm64"
        else
		echo "Platform not supported"
		exit 1
        fi

        CONFIG_DIR=$HOME/.config/go-librespot
        [ -d $CONFIG_DIR ] || mkdir -p $CONFIG_DIR
        cat << EOF > $CONFIG_DIR/config.yml
device_name: $PRETTY_HOSTNAME
zeroconf_enabled: true
volume_steps: 10
initial_volume: 100
device_type: speaker
bitrate: 320
EOF

        log_blue "OS Detected as ${ARCH} will download the related GO client"
        sudo apt-get install -y libogg-dev libvorbis-dev libasound2-dev
        if sudo systemctl is-active go-librespot-daemon.service; then
            sudo systemctl stop go-librespot-daemon.service
        fi
        DAEMON_BASE_URL=https://github.com/devgianlu/go-librespot/releases/latest/download
        DAEMON_ARCHIVE=go-librespot_linux_$ARCH.tar.gz
        DAEMON_DOWNLOAD_URL=$DAEMON_BASE_URL/$DAEMON_ARCHIVE
        DAEMON_DOWNLOAD_PATH=$DAEMON_ARCHIVE
        curl -L --progress-bar $DAEMON_DOWNLOAD_URL -o ./$DAEMON_DOWNLOAD_PATH
	log_green "extracting downloaded files"
        sudo tar xzvf $DAEMON_DOWNLOAD_PATH -C /usr/bin/ go-librespot
        rm $DAEMON_DOWNLOAD_PATH
        sudo chmod a+x /usr/bin/go-librespot

	echo "#!/bin/sh

# Traceback Setting
export GOTRACEBACK=crash

echo 'Librespot-go daemon starting...'
/usr/bin/go-librespot --config_dir $CONFIG_DIR" | sudo tee /bin/start-go-librespot.sh

	sudo chmod a+x /bin/start-go-librespot.sh
	
	GROUP=$(id -gn)
	
	echo "[Unit]
Description = go-librespot Daemon

[Service]
After=network-online.target
Wants=network-online.target
ExecStart=/bin/start-go-librespot.sh
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=go-librespot
User=$USER
Group=$GROUP
[Install]
WantedBy=multi-user.target" | sudo tee /lib/systemd/system/go-librespot-daemon.service
	
	sudo systemctl daemon-reload
	sudo systemctl enable go-librespot-daemon
	sudo systemctl start go-librespot-daemon
	log_green "GO librespot daemon installation finished!"

    fi
}

trap cleanup EXIT

###################################################
###################################################
#               GetOpts and Execution             #
###################################################
###################################################


heading "Raspberry Pi Audio Receiver Install script"

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

if [ $OPTIND == 1 ]; then
  echo "Default installation options"
  changeHostname=""
  bluetoothInstall=""
  shairportInstall=""
  raspotifyInstall=""
  UPnPRendererInstall=""
  snapclientInstall=""
  verify_os

  # apt_update_netselect
fi

### Update the apt cache and latest packages.
update_latest
### Set the hostname and the bluetooth name
set_hostname $changeHostname

### Install the bluetooth driver and settings configuration
### Noting that there is no way to 'Simple pair' on current raspbian config
install_bluetooth $bluetoothInstall

### allow for Apple devices to operate
install_shairport $shairportInstall

### Raspotify setup
install_raspotify $raspotifyInstall
### An attempt at UPnP render:
##  should open the door for other random applications to stream audio
# https://github.com/Torgee/rpi-audio-receiver/blob/master/install-upnp.sh
install_UPnP_renderer $UPnPRendererInstall

### the basics of a snapcast client is installed and setup.
## attempted to rip
# https://github.com/Arcadia197/rpi-audio-receiver/blob/rpi-zero-w/install-snapcast-client.sh

install_snapcast $snapclientInstall

### All finished
banner
log_green "Installation script completed!"
banner
