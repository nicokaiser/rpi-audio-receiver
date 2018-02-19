#!/bin/sh

apt install -y --no-install-recommends shairport-sync
usermod -a -G gpio shairport-sync

cat <<'EOF' > /etc/shairport-sync.conf
general = {
  name = "AirPi";
  interpolation = "soxr";
}

sessioncontrol = {
  allow_session_interruption = "yes";
  session_timeout = 10;
}

alsa = {
//  mixer_control_name = "Master";
}
EOF

systemctl enable --now shairport-sync
