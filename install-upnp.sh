#!/bin/sh

echo "Installing UPnP renderer (gmrender-resurrect)"

apt install -y --no-install-recommends gmediarender gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-alsa

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat <<EOF > /etc/default/gmediarender
ENABLED=1
DAEMON_USER="nobody:audio"
UPNP_DEVICE_NAME="${PRETTY_HOSTNAME}"
INITIAL_VOLUME_DB=0.0
ALSA_DEVICE="sysdefault"
EOF

systemctl enable --now gmediarender
