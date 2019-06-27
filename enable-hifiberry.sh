#!/bin/sh

cat <<'EOF' > /etc/asound.conf.dmixer
pcm.hifiberry {
  type hw
  card 0
  device 0
}

pcm.dmixer {
  type dmix
  ipc_key 1024
  ipc_perm 0666
  slave.pcm "hifiberry"
  slave {
    period_time 0
    period_size 1024
    buffer_size 8192
    rate 44100
  }
  bindings {
    0 0
    1 1
  }
}

ctl.dmixer {
  type hw
  card 0
}

pcm.softvol {
  type softvol
  slave.pcm "dmixer"
  control {
    name "Master"
    card 0
  }
}

pcm.!default {
  type plug
  slave.pcm "softvol"
}

pcm.front pcm.default
EOF

amixer sset 'Master' 96%
alsactl store

cat /boot/config.txt | grep -vi "dtparam=audio" | grep -vi hifiberry >/tmp/config.txt
echo dtoverlay=hifiberry-dac >>/tmp/config.txt
mv /tmp/config.txt /boot/config.txt
