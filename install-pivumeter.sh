#!/bin/sh

dpkg -i pivumeter_1.0-1_armhf.deb
cat <<'EOF' > /etc/asound.conf.pivumeter
pcm.hifiberry {
  type hw
  card 0
  device 0
}

pcm.pivumeter {
  type meter
  slave.pcm "hifiberry"
  scopes.0 pivumeter
}

pcm.softvol_and_pivumeter {
  type softvol
  slave.pcm "pivumeter"
  control {
    name "Master"
    card 0
  }
}

pcm_scope.pivumeter {
  type pivumeter
  decay_ms 500
  peak_ms 400
  brightness 16
  bar_reverse 0
  output_device blinkt
}

pcm_scope_type.pivumeter {
  lib /usr/lib/arm-linux-gnueabihf/libpivumeter.so
}

pcm.!default {
  type plug
  slave.pcm "softvol_and_pivumeter"
}
EOF
