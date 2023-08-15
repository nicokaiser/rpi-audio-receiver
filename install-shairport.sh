#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Shairport Sync AirPlay 2 Audio Receiver (Shairport Sync)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install --no-install-recommends autoconf automake build-essential libtool git autoconf automake libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd libpulse-dev

# ALAC
wget -O alac-master.zip https://github.com/mikebrady/alac/archive/refs/heads/master.zip
unzip alac-master.zip
cd alac-master
autoreconf -fi
./configure
make -j $(nproc)
make install
ldconfig
cd ..
rm -rf alac-master

# NQPTP
wget -O nqptp-1.2.1.zip https://github.com/mikebrady/nqptp/archive/refs/tags/1.2.1.zip
unzip nqptp-1.2.1.zip
cd nqptp-1.2.1
autoreconf -fi
./configure --with-systemd-startup
make -j $(nproc)
make install
cd ..
rm -rf nqptp-1.2.1

# Shairport Sync
wget -O shairport-sync-4.2.zip https://github.com/mikebrady/shairport-sync/archive/refs/tags/4.2.zip
unzip shairport-sync-4.2.zip
cd shairport-sync-4.2
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-apple-alac
make -j $(nproc)
make install
cd ..
rm -rf shairport-sync-4.2

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

usermod -a -G gpio shairport-sync
systemctl enable --now nqptp
systemctl enable --now shairport-sync
