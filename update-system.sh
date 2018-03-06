#!/bin/sh

echo "Updating packages"

apt update
apt upgrade -y
SKIP_WARNING=1 rpi-update
