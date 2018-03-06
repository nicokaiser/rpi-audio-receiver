#!/bin/sh

echo "Installing Shairport Sync AirPlay Audio Receiver"

apt install -y --no-install-recommends shairport-sync
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
