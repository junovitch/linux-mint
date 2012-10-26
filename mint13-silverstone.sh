#!/bin/bash
# Post Installation for GNU/Linux Mint Maya (Version 13)
#
# Jason Unovitch - October 2012
# GPL
#
# Syntax: sudo ./Mint13-Install.sh
#
# Notes:
#
#

VERSION="1.0"
LOGFILE="~/Mint13-Install-Log.txt"
TEMPLOG="/tmp/Mint13-Temp-Log.txt"
PPAs=""

exec > >(tee $LOGFILE)
exec 2>&1

MINTVERSION=`lsb_release -cs`
echo "################################################################################"
echo "Starting updates for $MINTVERSION"
# Check for root
if [ $EUID -ne 0 ]; then
    echo "Need root privileges: Run using # sudo $0" 1>&2
    exit 1
fi
echo "################################################################################"

install() {
    apt-get -y install $PKGS
    RETVAL=$?
}

log() {
    if [ $RETVAL -eq 0 ]; then
        echo -e "[  OK   ] - RETURN $RETVAL FOR $PKGS" >> $TEMPLOG
    else
        echo -e "[FAILURE] - RETURN $RETVAL FOR $PKGS" >> $TEMPLOG
    fi
}

# ZFS Support
# sudo add-apt-repository ppa:zfs-native/stable
# sudo apt-get update && sudo apt-get install ubuntu-zfs
add-apt-repository -y ppa:zfs-native/stable
PPAs=$PPAs" ubuntu-zfs"

# NVIDIA
# sudo apt-add-repository ppa:ubuntu-x-swat/x-updates
# sudo apt-get update && sudo apt-get install nvidia-current nvidia-settings
add-apt-repository ppa:ubuntu-x-swat/x-updates
PPAs=$PPAs" nvidia-current nvidia-settings"

# PS3 Media server
# https://help.ubuntu.com/community/Ps3MediaServer
# http://www.ps3mediaserver.org/forum/viewtopic.php?f=3&t=13046
# sudo add-apt-repository ppa:happy-neko/ps3mediaserver
# sudo apt-get update && sudo apt-get install ps3mediaserver
add-apt-repository -y ppa:happy-neko/ps3mediaserver
PPAs=$PPAs" ps3mediaserver"


apt-get update
PKGS=$PPAs && install && log


# End of script
echo "################################################################################"
echo "Installation Completed"
echo
echo "Summary"
cat $TEMPLOG && rm $TEMPLOG
echo 
echo "Detailed information can be found within $LOGFILE"
echo
echo "Please restart your session to complete."
echo "################################################################################"