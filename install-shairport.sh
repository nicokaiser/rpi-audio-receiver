#!/bin/bash -e

SHAIRPORT_VERSION=3.3.1

echo -n "Do you want to install Shairport Sync AirPlay Audio Receiver (shairport-sync v${SHAIRPORT_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install --no-install-recommends -y autoconf automake avahi-daemon build-essential libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libssl-dev libtool xmltoman pkg-config

wget -O shairport_sync-v${SHAIRPORT_VERSION}.tar.gz https://github.com/mikebrady/shairport-sync/archive/${SHAIRPORT_VERSION}.tar.gz
tar xzf shairport_sync-v${SHAIRPORT_VERSION}.tar.gz
rm shairport_sync-v${SHAIRPORT_VERSION}.tar.gz
cd shairport-sync-${SHAIRPORT_VERSION}
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-systemd --with-metadata
make
make install
cd ..
rm -rf shairport-sync-${SHAIRPORT_VERSION}

usermod -a -G gpio shairport-sync

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > /etc/shairport-sync.conf
general = {
  name = "${PRETTY_HOSTNAME}";
}

alsa = {
//  mixer_control_name = "Master";
}

metadata =
{
  enabled = "yes";
  include_cover_art = "yes";
  pipe_name = "/tmp/shairport-sync-metadata";
  pipe_timeout = 5000;
};

sessioncontrol = {
  wait_for_completion = "no";
  allow_session_interruption = "yes";
  session_timeout = 20;
};
EOF

systemctl enable --now shairport-sync
