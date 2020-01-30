#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install ALSA VU meter plugin (pivumeter) [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

apt install --no-install-recommends -y git build-essential autoconf automake libtool libasound2-dev libfftw3-dev wiringpi
git clone https://github.com/pimoroni/pivumeter.git
cd pivumeter
aclocal && libtoolize
autoconf && automake --add-missing
./configure && make
make install

cat <<'EOF' > /etc/asound.conf
defaults.pcm.card 0
defaults.ctl.card 0

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
    name "Softvol"
    card 0
  }
  min_dB -90.2
  max_dB 0.0
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
  lib /usr/local/lib/libpivumeter.so
}
pcm.!default {
  type plug
  slave.pcm "softvol_and_pivumeter"
}
EOF

amixer sset 'Softvol' 100%
alsactl store
