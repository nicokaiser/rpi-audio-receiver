#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

: "${SHAIRPORT_VERSION:=3.3.8}"

echo
echo -n "Do you want to install Shairport Sync AirPlay 1 Audio Receiver (shairport-sync v${SHAIRPORT_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install --no-install-recommends -y autoconf automake avahi-daemon build-essential libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libssl-dev libtool xmltoman pkg-config libsoxr0 libsoxr-dev libsndfile1 libsndfile1-dev libglib2.0-dev libmosquitto-dev libmosquitto1

# Install ALAC from GitHub
wget -O alac.tar.gz https://github.com/TimothyGu/alac/archive/refs/heads/master.tar.gz
tar xzf alac.tar.gz
rm alac.tar.gz
cd alac-master
autoreconf -fi
./configure
make -j $(nproc)
make install
cd ..
rm -rf alac-master
ldconfig

# Install shairport-sync from GitHub
wget -O shairport_sync-v${SHAIRPORT_VERSION}.tar.gz https://github.com/mikebrady/shairport-sync/archive/${SHAIRPORT_VERSION}.tar.gz
tar xzf shairport_sync-v${SHAIRPORT_VERSION}.tar.gz
rm shairport_sync-v${SHAIRPORT_VERSION}.tar.gz
cd shairport-sync-${SHAIRPORT_VERSION}
autoreconf -fi
./configure \
    --with-alsa \
    --with-dummy \
    --with-avahi \
    --with-ssl=openssl \
    --with-soxr \
    --with-systemd \
    --sysconfdir=/etc \
    --with-dbus-interface \
    --with-mpris-interface \
    --with-mqtt-client \
    --with-apple-alac \
    --with-convolution
make -j $(nproc)
make install
cd ..
rm -rf shairport-sync-${SHAIRPORT_VERSION}

usermod -a -G gpio shairport-sync

mkdir -p /etc/systemd/system/shairport-sync.service.d
cat <<'EOF' > /etc/systemd/system/shairport-sync.service.d/override.conf
[Service]
# Avahi daemon needs some time until fully ready
ExecStartPre=/bin/sleep 3
EOF

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > "/etc/shairport-sync.conf"
general = {
  name = "${PRETTY_HOSTNAME}";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

systemctl enable --now shairport-sync
