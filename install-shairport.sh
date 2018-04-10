#!/bin/sh

echo "Installing Shairport Sync AirPlay Audio Receiver"

apt install --no-install-recommends -y autoconf automake avahi-daemon build-essential git libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libssl-dev libtool xmltoman pkg-config

git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync && git checkout 3.2RC1
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-systemd --with-metadata
make
make install
cd ..
rm -rf shairport-sync

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
