#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Shairport Sync AirPlay Audio Receiver (shairport-sync v${SHAIRPORT_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

#apt install --no-install-recommends -y autoconf automake avahi-daemon build-essential git libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libssl-dev libtool xmltoman pkg-config
apt install --no-install-recommends -y avahi-daemon build-essential git xmltoman autoconf automake libtool libdaemon-dev libpopt-dev libconfig-dev libasound2-dev libpulse-dev  libavahi-client-dev libssl-dev libsoxr-dev


git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync 
last_stable_tag=$(git tag | grep -oP "^[0-9.]+$" | tail -1)
git checkout $last_stable_tag
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-systemd --with-metadata
make
make install
cd ..

usermod -a -G gpio shairport-sync

# raspi-config nonint do_boot_wait 0

# For aditional configurations check /etc/shairport-sync.conf.sample

mkdir -p /etc/systemd/system/shairport-sync.service.d
cat <<'EOF' > /etc/systemd/system/shairport-sync.service.d/override.conf
[Service]
# Avahi daemon needs some time until fully ready
ExecStartPre=/bin/sleep 3
EOF

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > /etc/shairport-sync.conf
general = {
  name = "${PRETTY_HOSTNAME}";
}
alsa = {
//  mixer_control_name = "Master";
//  output_device = "default";
  output_device = "hw:Headphones,0";
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
# systemctl start shairport-sync
