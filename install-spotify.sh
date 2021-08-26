#!/bin/sh

echo "Installing Spotify Connect (spotifyd)"

#wget https://github.com/Spotifyd/spotifyd/releases/download/v0.2.5/spotifyd-2019-02-25-armv6.zip
#unzip spotifyd-2019-02-25-armv6.zip
#rm spotifyd-2019-02-25-armv6.zip

#wget https://github.com/Spotifyd/spotifyd/releases/download/v0.2.24/spotifyd-linux-armv6-slim.tar.gz
wget https://github.com/Spotifyd/spotifyd/releases/latest/download/spotifyd-linux-armv6-slim.tar.gz
tar -xf spotifyd-linux-armv6-slim.tar.gz
rm spotifyd-linux-armv6-slim.tar.gz

mkdir -p /opt/local/bin
mv spotifyd /opt/local/bin

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}


# Check https://github.com/Spotifyd/spotifyd#configuration-file
#   for more conif options
cat <<EOF > /etc/spotifyd.conf
[global]
# The audio backend used to play the your music. To get
# a list of possible backends, run `spotifyd --help`.
backend = "alsa"

# The alsa audio device to stream audio to. To get a
# list of valid devices, run `aplay -L`,
device = "hw:Headphones,0"  # omit for macOS

# The alsa mixer used by `spotifyd`.
mixer = "PCM"

# The volume controller. Each one behaves different to
# volume increases. For possible values, run
# `spotifyd --help`.
volume_controller = "softvol"  # use softvol for macOS

# The name that gets displayed under the connect tab on
# official clients. Spaces are not allowed!
device_name = "${PRETTY_HOSTNAME}"

# The audio bitrate. 96, 160 or 320 kbit/s
bitrate = 320

# If set to true, audio data does NOT get cached.
no_audio_cache = true

# Volume on startup between 0 and 100
# NOTE: This variable's type will change in v0.4, to a number (instead of string)
initial_volume = "100"

# If set to true, enables volume normalisation between songs.
volume_normalisation = false

# The displayed device type in Spotify clients.
# Can be unknown, computer, tablet, smartphone, speaker, t_v,
# a_v_r (Audio/Video Receiver), s_t_b (Set-Top Box), and audio_dongle.
device_type = "audio_dongle"
EOF

cat <<'EOF' > /etc/systemd/system/spotifyd.service
[Unit]
Description=Spotify Connect
Documentation=https://github.com/Spotifyd/spotifyd
Wants=sound.target
After=sound.target
Wants=network-online.target
After=network-online.target
[Service]
Type=idle
User=pi
ExecStart=/opt/local/bin/spotifyd --config-path /etc/spotifyd.conf --no-daemon
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20
[Install]
WantedBy=multi-user.target

EOF
systemctl daemon-reload
systemctl enable --now spotifyd.service
