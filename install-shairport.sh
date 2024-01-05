#!/bin/bash -e

NQPTP_VERSION=1.2.4
SHAIRPORT_SYNC_VERSION=4.3.2

echo
echo -n "Do you want to install Shairport Sync AirPlay 2 Audio Receiver (Shairport Sync)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

sudo apt install --no-install-recommends autoconf automake build-essential libtool git autoconf automake libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd

# ALAC
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

# NQPTP
wget -O nqptp-${NQPTP_VERSION}.zip https://github.com/mikebrady/nqptp/archive/refs/tags/${NQPTP_VERSION}.zip
unzip nqptp-${NQPTP_VERSION}.zip
cd nqptp-${NQPTP_VERSION}
autoreconf -fi
./configure --with-systemd-startup
make -j $(nproc)
sudo make install
cd ..
rm -rf nqptp-${NQPTP_VERSION}

# Shairport Sync
wget -O shairport-sync-${SHAIRPORT_SYNC_VERSION}.zip https://github.com/mikebrady/shairport-sync/archive/refs/tags/${SHAIRPORT_SYNC_VERSION}.zip
unzip shairport-sync-${SHAIRPORT_SYNC_VERSION}.zip
cd shairport-sync-${SHAIRPORT_SYNC_VERSION}
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-apple-alac
make -j $(nproc)
sudo make install
cd ..
rm -rf shairport-sync-${SHAIRPORT_SYNC_VERSION}

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}
tee /etc/shairport-sync.conf <<'EOF'
general = {
  name = "${PRETTY_HOSTNAME}";
  output_backend = "alsa";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

sudo usermod -a -G gpio shairport-sync
sudo systemctl enable --now nqptp
sudo systemctl enable --now shairport-sync
