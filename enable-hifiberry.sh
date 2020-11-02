#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
read -e -i "y" -p "Do you want to enable configure ALSA and sound devices like HiFiBerry or onboard sound? [y/N] " -r REPLY 
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

echo 
echo "Listing sound cards actually know to ALSA:"
aplay -l | grep -E '(^Karte|^card)'
if [ -e /etc/asound.conf ]; then
  active=$(grep defaults.pcm.card /etc/asound.conf | cut -d " " -f2)
  echo
  echo "/etc/asound.conf exits - be careful! Default card is $active"
fi
echo

echo "Do want to enable a HiFiBerry-board or one of the cards listed above? "
read -p "Enter board name or card number [dac/dacplus/dacplusadc/dacplusadcpro/dacplusdsp/digi/digipro/amp/0/1/2/..] " -r CARD 
if [[ ! "$CARD" =~ ^(dac|dacplus|digi|amp|[0-9])$ ]]; then 
  echo "$CARD is not a valid input!"
  exit 1
fi

if [[ ! "$CARD" =~ ^[0-9]$ ]]; then 

cat <<'EOF' > /etc/asound.conf
defaults.pcm.card 0
defaults.ctl.card 0

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
    format S32_LE
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
    name "Softvol"
    card 0
  }
  min_dB -90.2
  max_dB 0.0
}
pcm.!default {
  type plug
  slave.pcm "softvol"
}
EOF

#amixer sset 'Softvol' 100%
#alsactl store

cat /boot/config.txt | grep -vi "dtparam=audio" | grep -vi hifiberry >/tmp/config.txt
echo dtoverlay=hifiberry-${CARD} >>/tmp/config.txt
mv /tmp/config.txt /boot/config.txt

else

cat <<EOF > /etc/asound.conf
defaults.pcm.card ${CARD}
defaults.ctl.card ${CARD}
EOF

fi