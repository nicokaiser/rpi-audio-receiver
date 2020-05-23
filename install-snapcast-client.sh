#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

THENAME="Snapcast Client (snapclient)"

install-apt() {
    echo "Installing "$THENAME" with apt..."
    apt install --no-install-recommends -y snapclient
}

install-package() {
    # Package is from https://github.com/badaix/snapcast/releases/download/v0.19.0/snapclient_0.19.0-1_armhf.deb
    # Install
    sudo dpkg -i files/snapclient_0.19.0-1_armhf.deb
    # The package has a dependency to libavahi. To install the dependencies use:
    sudo apt-get -y -f install
}

# Choose option
echo
echo -n "Do you want to install "$THENAME" by (a)pt or by (p)package?  [a/p/N] "
read REPLY
if [[ "$REPLY" =~ ^(apt|a|A)$ ]]; 
then 
    install-apt
elif [[ "$REPLY" =~ ^(package|p|P)$ ]]; 
then 
    install-package
else
    echo "Installation of "$THENAME" aborted."
    exit 0; 
fi