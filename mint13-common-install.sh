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
        echo "[ SKIP  ] - /tmp and /var/tmp already configured for tmpfs"
    else
        echo -e "none\t\t/tmp\t\ttmpfs\trw,nosuid,nodev,mode=01777\t0\t0" >> /etc/fstab
        echo -e "none\t\t/var/tmp\ttmpfs\trw,nosuid,nodev,mode=01777\t0\t0" >> /etc/fstab
        echo "[  OK   ] - /tmp and /var/tmp configured for tmpfs ramdisk"
    fi
    cat /etc/fstab
}

install_ftp() {
    ping -c 5 ftp
    LOCAL_FTP=$?
    if [ $LOCAL_FTP -eq 0 ]; then
        SCM_PKG="scmccid_linux_64bit_driver_V5.0.21.tar.gz"
        cd /tmp && wget ftp://ftp/pub/$SCM_PKG
        tar xvzf /tmp/$SCM_PKG -C /tmp
        cd /tmp/scmccid_5.0.21_linux/ && ./install.sh | tee "$TEMPLOG"
        RETVAL=$?
        PKG=$SCM_PKG
        log

        CACKEY="cackey_0.6.5-1_amd64.deb"
        mkdir /usr/lib64
        cd /tmp && wget ftp://ftp/pub/$CACKEY
        dpkg -i "$CACKEY" | tee "$TEMPLOG"
        RETVAL=$?
        PKG=$CACKEY
        log

        FIREFOX="firefox_extensions-dod_configuration-1.3.6.xpi"
        firefox ftp://ftp/pub/$FIREFOX &
        RETVAL=$?
        PKG=$FIREFOX
        log

        KEYDB="KEYDB.cfg"
        cd /tmp && wget ftp://ftp/pub/$KEYDB
        mkdir /etc/skel/.config/aacs/ && mkdir ~/.config/aacs/
        cp $KEYDB /etc/skel/.config/aacs/ && cp $KEYDB ~/.config/aacs/
        RETVAL=$?
        PKG=Bluray_$KEYDB
        log

        LIBAACS="libaacs.so.0"
        cd /tmp && wget ftp://ftp/pub/$LIBAACS
        mkdir /usr/lib64/
        cp $LIBAACS /usr/lib64/
        RETVAL=$?
        PKG=Bluray_$LIBAACS
        log
    fi
}

install_skype() {
    wget -O /tmp/skype.deb http://www.skype.com/go/getskype-linux-beta-ubuntu-64
    dpkg -i /tmp/skype.deb; apt-get -f install | tee "$TEMPLOG"; RETVAL=$?; log; rm /tmp/skype.deb
}

install_chrome() {
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
    sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    apt-get update && apt-get install google-chrome-stable
}

################################################################################
##  USER DEFINED PACKAGES  #####################################################
################################################################################

if [ $HOSTNAME == "Silverstone" ]; then
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

    # BOINC
    pkg_push "boinc boinc-nvidia-cuda"
fi

if [ $HOSTNAME == "Coolermaster" ]; then
    # NVIDIA
    # sudo apt-add-repository ppa:ubuntu-x-swat/x-updates
    # sudo apt-get update && sudo apt-get install nvidia-current nvidia-settings
    add-apt-repository ppa:ubuntu-x-swat/x-updates
    PPAs=$PPAs" nvidia-current nvidia-settings"
fi

# ZFS Support
# sudo add-apt-repository ppa:zfs-native/stable
# sudo apt-get update && sudo apt-get install ubuntu-zfs
# If there is a ZFS build issue, use manual dkms install procedures here
# https://github.com/zfsonlinux/zfs/issues/1155
add-apt-repository -y ppa:zfs-native/stable
PPAs=$PPAs" ubuntu-zfs"

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

# KDE 4.10 backport
add-apt-repository ppa:kubuntu-ppa/backports
PPAs=$PPAs" kubuntu-desktop"

# Security
pkg_push "clamav clamtk ecryptfs-utils gufw fail2ban chkrootkit openssh-server ssh-import-id openssh-blacklist openssh-blacklist-extra openvpn kismet wireshark tshark nmap putty"

# Encfs Home directory support for FreeBSD/Linux cross compatibility
# http://wiki.debian.org/TransparentEncryptionForHomeFolder
pkg_push "encfs libpam-encfs libpam-mount"

# Games
pkg_push "playonlinux openttd openttd-opensfx"

# Photography
pkg_push "shotwell gimp gimp-data gimp-data-extras pinta mypaint hugin"

# CLI Applications
pkg_push "tmux tcsh terminator zsh zsh-doc htop"

# System Applications
pkg_push "gconf-editor remmina nfs-common autofs gddrescue gparted blueman synaptic preload etherwake wakeonlan"

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
pkg_push "openshot blender avidemux cheese devede mkvtoolnix mkvtoolnix-gui"

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

# Alt Desktops/WMs for Linux Mint only
lsb_release -d | grep "Mint"
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    pkg_push "unity xmonad mint-meta-cinnamon mint-meta-mate mint-meta-kde"
fi

# PPAs installed last
pkg_push "$PPAs"

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

# Enable backports on Linux Mint Maya 13
perl -pwi -e 's^deb http://packages.linuxmint.com/ maya main upstream import\n^deb http://packages.linuxmint.com/ maya main upstream import backport\n^' /etc/apt/sources.list

# Update Package List
apt-get -y update

# Update all base system packages
apt-get -y upgrade

# Distupgrade to update kernel too
apt-get -y dist-upgrade

echo "################################################################################"
echo "Done, install user programs" 
echo "################################################################################"

# Run Main subroutine
install_main

install_ftp

install_skype

install_chrome

# Cleanup
apt-get -y autoclean

echo "################################################################################"
echo "Installation Completed"
echo
echo "Beginning Local Configuration"

# Get themes
git clone https://github.com/shimmerproject/Greybird /usr/share/themes/Greybird && echo "[  OK   ] - Greybird theme downloaded"

# Configure tmpfs in ramdisk
config_tmpfs

# Config NFSv4
# https://help.ubuntu.com/community/SettingUpNFSHowTo
# https://help.ubuntu.com/community/NFSv4Howto
# https://help.ubuntu.com/community/Autofs
if [ $HOSTNAME == "Coolermaster" ]; then
    echo "NEED_IDMAPD=yes" >> /etc/default/nfs-common
    perl -pwi -e 's^# Domain = localdomain^Domain = mydomain.name^' /etc/idmapd.conf
    echo -e "/zfs/homedirs\t/etc/auto.home" >> /etc/auto.master
    echo -e "*\t-fstype=nfs4\t10.100.102.2:/zfs/homedirs/&" >> /etc/auto.home
    echo "[  OK   ] - AutoFS for NFSv4 Mounts configured"
fi

# Configure Printer(s)
lpadmin -p "Jason-HP-Photosmart-5510-series" -v hp:/net/Photosmart_5510_series?zc=xju-printer -L "Jason's Printer" -m drv:///hpcups.drv/hp-photosmart_5510_series.ppd && cupsenable "Jason-HP-Photosmart-5510-series" && cupsaccept "Jason-HP-Photosmart-5510-series" && echo "[  OK   ] - Jason's HP Photosmart 5510 series configured"

echo "Done"
echo
echo "Successfully installed:"
cat $SUCCESSLOG
echo
echo "Failures"
cat $FAILBRIEF
if [ $LOCAL_FTP -ne 0 ]; then
   echo "################################################################################"
   echo
   echo "The local FTP server wasn't reachable, the following steps may be required."
   echo
   echo "Smart card support:"
   echo
   echo "Prerequisites (already installed by script):"
   echo "sudo apt-get install libpcsclite1 pcscd pcsc-tools"
   echo
   echo "1.  Install smart card reader drivers"
   echo "Visit http://support.identive-infrastructure.com/download_scm/download_scm.php?lang=1"
   echo "Download the appropriate package. (Change package names as needed)"
   echo "tar xvzf $SCM_PKG -C /tmp"
   echo "cd /tmp/scmccid_5.0.21_linux/ && ./install.sh"
   echo
   echo "2.  Install DISA Cackey software (CAC support already required to go to website)"
   echo "Visit https://software.forge.mil/sf/frs/do/listReleases/projects.community_cac/frs.cackey"
   echo "Download and unzip the Cackey software"
   echo "dpkg -i $CACKEY"
   echo
   echo "3.  Install the Firefox CAC extension."
   echo "Visit http://www.forge.mil/Resources-Firefox.html"
   echo "Download and run the extension"
   echo
   echo "Bluray Support: (not finalized)"
   echo "Visit http://vlc-bluray.whoknowsmy.name/"
   echo "Follow instructions on the site"
   echo
fi
echo "Please restart your session to complete."
echo "################################################################################"
