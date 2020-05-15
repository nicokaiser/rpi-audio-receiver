#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Shairport Sync AirPlay Audio Receiver (shairport-sync v${SHAIRPORT_VERSION})? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install --no-install-recommends -y avahi-daemon libavahi-client3 libconfig9 libdaemon0 libjack-jackd2-0 libmosquitto1 libpopt0 libpulse0 libsndfile1 libsoxr0
dpkg -i files/shairport-sync_3.3.5-1~bpo10+1_armhf.deb
usermod -a -G gpio shairport-sync
raspi-config nonint do_boot_wait 0

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

alsa = {
//  mixer_control_name = "Softvol";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

systemctl enable --now shairport-sync
