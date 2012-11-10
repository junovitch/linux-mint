#!/bin/bash

################################################################################
##  Apt-get Install Script  ####################################################
################################################################################
# Written in 2012 by Jason Unovitch                                            #
#   oneshotuno@yahoo.com                                                       #
#   https://github.com/junovitch                                               #
#                                                                              #
# To the extent possible under law, the author(s) have dedicated all copyright #
# and related and neighboring rights to this software to the public domain     #
# worldwide. This software is distributed without any warranty.                #
#                                                                              #
# You should have received a copy of the CC0 Public Domain Dedication along    #
# with this software.                                                          #
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>              #
################################################################################

################################################################################
##  LOGFILES  ##################################################################
################################################################################

FAILBRIEF="/tmp/install-log.txt"
TEMPLOG="/tmp/temp-log.txt"
FAILDETAILS="/tmp/failures.txt"
SUCCESSLOG="/tmp/success.txt"

echo -n '' > $FAILBRIEF
echo -n '' > $TEMPLOG
echo -n '' > $FAILDETAILS
echo -n '' > $SUCCESSLOG

################################################################################
##  COMMANDS  ##################################################################
################################################################################

DISTRO=`lsb_release -d | cut -d ":" -f "2" | sed -e 's/^[ \t]*//'`
HOSTNAME=`hostname`
PKG_ADD="apt-get -y -f install"

################################################################################
##  BLANK PACKAGE LISTS  #######################################################
################################################################################

PKGS=()
PPAs=""

################################################################################
##  SUBROUTINES  ###############################################################
################################################################################

pkg_push() {
    PKGS=("${PKGS[@]}" "$1")
}

install_main() {
    for PKG in ${PKGS[@]}
        do
            $PKG_ADD $PKG | tee "$TEMPLOG"
            RETVAL=$?
            log
        done
}

log() {
    if [ $RETVAL -eq 0 ]; then
        echo -ne "$PKG " >> "$SUCCESSLOG"
    else
        echo "[FAILURE] - Return $RETVAL for $PKG" >> "$FAILBRIEF"
        cat "$TEMPLOG" >> "$FAILDETAILS"
    fi
}

config_tmpfs() {
    egrep '/tmp' /etc/fstab > /dev/null
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        echo "[ SKIP  ] - /tmp and /var/tmp already configured for tmpfs" >> $FAILBRIEF
    else
        echo -e "none\t\t/tmp\t\ttmpfs\trw,nosuid,nodev,mode=01777\t0\t0" >> /etc/fstab
        echo -e "none\t\t/var/tmp\ttmpfs\trw,nosuid,nodev,mode=01777\t0\t0" >> /etc/fstab
        echo "[  OK   ] - /tmp and /var/tmp configured for tmpfs ramdisk" >> $FAILBRIEF
    fi
    cat /etc/fstab
}

################################################################################
##  USER DEFINED PACKAGES  #####################################################
################################################################################

if [ $HOSTNAME == "Silverstone" ]; then
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
fi

# Grub Customizer
# sudo add-apt-repository ppa:danielrichter2007/grub-customizer
# sudo apt-get update && sudo apt-get install grub-customizer
add-apt-repository -y ppa:danielrichter2007/grub-customizer
PPAs=$PPAs" grub-customizer"

# Handbrake
#sudo apt-add-repository ppa:stebbins/handbrake-releases
#sudo apt-add-repository ppa:stebbins/handbrake-snapshots
#sudo apt-get update && sudo apt-get install handbrake-gtk
add-apt-repository -y ppa:stebbins/handbrake-snapshots
PPAs=$PPAs" handbrake-gtk"

# Jupiter
add-apt-repository ppa:webupd8team/jupiter
PPAs=$PPAs" jupiter"

# Security
pkg_push "clamav clamtk ecryptfs-utils encfs gufw fail2ban chkrootkit rkhunter openssh-server ssh-import-id openssh-blacklist openssh-blacklist-extra openvpn kismet wireshark tshark nmap putty"

# Games
pkg_push "playonlinux openttd openttd-opensfx"

# Photography
pkg_push "shotwell gimp gimp-data gimp-data-extras pinta mypaint hugin"

# CLI Applications
pkg_push "tmux tcsh terminator zsh zsh-doc htop"

# System Applications
pkg_push "gparted blueman synaptic preload etherwake wakeonlan"

# Development tools and applications
pkg_push "build-essential check checkinstall cdbs devscripts dh-make fakeroot geany geany-plugins libxml-parser-perl subversion git git-core sharutils uudeview vim vim-gnome vim-doc vim-scripts vim-latexsuite"

# Java
pkg_push "openjdk-7-jre icedtea-7-plugin"

# HP Printer Tools
pkg_push "hplip-gui"

# Basic Smartcard Support
pkg_push "libpcsclite1 pcscd pcsc-tools"

# Media
pkg_push "vlc banshee banshee-extension-ampache"

# Audio Tools
pkg_push "audacity pavucontrol"

# Video Tools
pkg_push "blender avidemux cheese devede"

# Web Applications
pkg_push "kompozer bluefish mpack clamz"

# Communication
pkg_push "pidgin pidgin-otr pidgin-encryption" #skype

# Virtualization
pkg_push "virtualbox-qt virtualbox-guest-additions-iso gns3"

# File Tools
pkg_push "rar unrar p7zip-rar p7zip zip unzip sharutils uudeview mpack lha cabextract mdbtools mdbtools-doc mdbtools-gmdb pdfshuffler"

# Desktop Appls
pkg_push "conky-all gtk-redshift"

# Google Earth
pkg_push "lsb-core googleearth"

# Codecs
pkg_push "ffmpeg flac libmad0 totem-mozilla icedax id3tool id3v2 lame libquicktime2 sox tagtool faac libdvdcss2 libdvdnav4 libdvdread4"

# PPAs installed last
pkg_push "$PPAs"

# 1. Install prerequisite packages, this is already covered in initial setup script
#sudo apt-get install libpcsclite1 pcscd pcsc-tools

# 2. Install card reader drivers.
# http://support.identive-infrastructure.com/download_scm/download_scm.php?lang=1
SCM_PKG="scmccid_linux_64bit_driver_V5.0.21.tar.gz"
find /usr/local -name "$SCM_PKG" -print0 | xargs -0 cp -t /tmp 
tar xvzf /tmp/$SCM_PKG -C /tmp
cd /tmp/scmccid_5.0.21_linux/ && ./install.sh | tee "$TEMPLOG"
RETVAL=$?
PKG=$SCM_PKG
log

# 3. DISA software can be found below, both cackey and firefox_extensions are required (CAC Login required to download, get beforehand)
# https://software.forge.mil/sf/frs/do/listReleases/projects.community_cac/frs.cackey
## http://www.forge.mil/Resources-Firefox.html
CACKEY="cackey0.6.5-1_amd64.deb"
mkdir /usr/lib64
find /usr/local -name "$CACKEY" -print0 | xargs -0 dpkg -i | tee "$TEMPLOG"
RETVAL=$?
PKG=$CACKEY
log

# Firefox Configs
FIREFOX="firefox_extensions-dod_configuration-1.3.6.xpi"
find /usr/local -name "$FIREFOX" -print0 | xargs -0 firefox
RETVAL=$?
PKG=$FIREFOX
log

# Put blu-ray support files in place (must be in /usr/local already)
mkdir /etc/skel/.config/aacs/
mkdir ~/.config/aacs/
find /usr/local -name "KEYDB.cfg" -print0 | xargs -0 -I '{}' cp '{}' /etc/skel/.config/aacs/
find /usr/local -name "KEYDB.cfg" -print0 | xargs -0 -I '{}' cp '{}' ~/.config/aacs/
find /usr/local -name "libaacs.so.0" -print0 | xargs -0 -I '{}' cp '{}' /usr/lib64/

################################################################################
##  MAIN PROGRAM  ##############################################################
################################################################################

echo "################################################################################"
echo "Starting system updates on $DISTRO host $HOSTNAME" 
echo "################################################################################"

#Check for root
if [ $EUID -ne 0 ]; then
    echo "Need root privileges: Run using # sudo $0" 1>&2
    exit 1
fi

# Update Package List
apt-get -y update

# Update all base system packages
apt-get -y upgrade

echo "################################################################################"
echo "Done, install user programs" 
echo "################################################################################"

# Run Main subroutine
install_main

wget -O /tmp/skype.deb  http://download.skype.com/linux/skype-ubuntu_4.0.0.8-1_amd64.deb
dpkg -i /tmp/skype.deb; apt-get -f install | tee "$TEMPLOG"; RETVAL=$?; log; rm /tmp/skype.deb

# Cleanup
apt-get -y autoclean

# Configure tmpfs in ramdisk
config_tmpfs

# End of script
echo "################################################################################"
echo "Installation Completed"
echo
echo "Successfully installed:"
cat $SUCCESSLOG
echo
echo "Failures"
cat $FAILBRIEF
echo 
echo "Please restart your session to complete."
echo "################################################################################"
