#!/bin/sh

apt install -y --no-install-recommends gmediarender gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-alsa

PRODUCTNAME=$(hostnamectl status --pretty)
PRODUCTNAME=${PRODUCTNAME:-$(hostname)}

mv /etc/default/gmediarender /etc/default/gmediarender.orig
cat <<EOF > /etc/default/gmediarender
ENABLED=1
DAEMON_USER="nobody:audio"
UPNP_DEVICE_NAME="${PRODUCTNAME}"
INITIAL_VOLUME_DB=0.0
ALSA_DEVICE="sysdefault"
EOF

systemctl enable --now gmediarender
