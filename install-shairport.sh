#!/bin/bash -e

# these are defaults, but can be overridden by setting them before running
: "${SHAIRPORT_VERSION:=3.3.5}"
: "${SHAIRPORT_SYSCONFDIR:=/etc}"
: "${SHAIRPORT_CONFIGURE:=--with-alsa --with-avahi --with-ssl=openssl --with-soxr}"

echo -n "Do you want to install Shairport Sync AirPlay Audio Receiver (shairport-sync v${SHAIRPORT_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install --no-install-recommends -y autoconf automake avahi-daemon build-essential libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libssl-dev libtool xmltoman pkg-config libsoxr0 libsoxr-dev

wget -O shairport_sync-v${SHAIRPORT_VERSION}.tar.gz https://github.com/mikebrady/shairport-sync/archive/${SHAIRPORT_VERSION}.tar.gz
tar xzf shairport_sync-v${SHAIRPORT_VERSION}.tar.gz
rm shairport_sync-v${SHAIRPORT_VERSION}.tar.gz
cd shairport-sync-${SHAIRPORT_VERSION}
autoreconf -fi
# left two options included as the script below determines them
./configure --sysconfdir="${SHAIRPORT_SYSCONFDIR}" --with-systemd ${SHAIRPORT_CONFIGURE}
make
make install
cd ..
rm -rf shairport-sync-${SHAIRPORT_VERSION}

usermod -a -G gpio shairport-sync

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > "${SHAIRPORT_SYSCONFDIR}/shairport-sync.conf"
general = {
  name = "${PRETTY_HOSTNAME}";
}

alsa = {
//  mixer_control_name = "Softvol";
}

sessioncontrol = {
  allow_session_interruption = "yes";
  session_timeout = 20;
};
EOF

systemctl enable --now shairport-sync
