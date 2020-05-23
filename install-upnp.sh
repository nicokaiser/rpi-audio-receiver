#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install UPnP renderer (gmrender-resurrect)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install -y --no-install-recommends gmediarender gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-alsa


cat <<'EOF' > /etc/default/gmediarender
ENABLED=1
DAEMON_USER="nobody:audio"
INITIAL_VOLUME_DB=0.0
ALSA_DEVICE="sysdefault"
EOF

# Replace static name "Raspberry" with the dynamic hostname variable
sed -i -e 's/Raspberry/$(hostname)/g' /etc/init.d/gmediarender

systemctl enable --now gmediarender
