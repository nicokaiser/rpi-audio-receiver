#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

: "${SHAIRPORT_VERSION:=4.2}"

echo
echo -n "Do you want to install Shairport Sync AirPlay 2 Audio Receiver (shairport-sync v${SHAIRPORT_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install --no-install-recommends build-essential git autoconf automake libtool libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd libpulse-dev

# ALAC
git clone --depth 1 https://github.com/mikebrady/alac.git
cd alac
autoreconf -fi
./configure
make -j $(nproc)
make install
ldconfig
cd ..
rm -rf alac

# NQPTP
git clone https://github.com/mikebrady/nqptp.git
cd nqptp
git checkout 1.2.1
autoreconf -fi
./configure --with-systemd-startup
make -j $(nproc)
make install
cd ..
rm -rf nqptp

# Shairport Sync
git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync
git checkout 4.2
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-pa --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-apple-alac
make -j $(nproc)
make install
cd ..
rm -rf shairport-sync

usermod -a -G gpio shairport-sync

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > "/etc/shairport-sync.conf"
general = {
  name = "${PRETTY_HOSTNAME}";
  output_backend = "pa";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

systemctl enable --now nqptp
systemctl enable --now shairport-sync
