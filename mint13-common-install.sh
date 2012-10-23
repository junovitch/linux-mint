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
exec > >(tee $LOGFILE)
exec 2>&1

VERSION="1.0"
LOGFILE="~/Mint13-Install-Log.txt"
TEMPLOG="/tmp/Mint13-Temp-Log.txt"
PPAs=""

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

# Grub Customizer
# sudo add-apt-repository ppa:danielrichter2007/grub-customizer
# sudo apt-get update && sudo apt-get install grub-customizer
add-apt-repository -y ppa:danielrichter2007/grub-customizer
PPAs=$PPAs" grub-customizer"

# Handbrake (PPA release not avail yet)
#sudo apt-add-repository ppa:stebbins/handbrake-releases
#sudo apt-add-repository ppa:stebbins/handbrake-snapshots
#sudo apt-get update && sudo apt-get install handbrake-gtk
add-apt-repository -y stebbins/handbrake-snapshots
PPAs=$PPAs" handbrake-gtk"

# Jupiter
add-apt-repository ppa:webupd8team/jupiter
PPAs=$PPAs" jupiter"

# Update Package List
apt-get -y update

# Update all base system packages
#apt-get -y dist-upgrade
apt-get -y upgrade

# Install packages
SECURITY="clamav clamtk ecryptfs-utils encfs gufw fail2ban chkrootkit rkhunter openssh-server ssh-import-id openssh-blacklist openssh-blacklist-extra openvpn kismet wireshark tshark nmap putty"
PKGS=$SECURITY && install && log

GAMES="playonlinux openttd openttd-opensfx wesnoth"
PKGS=$GAMES && install && log

PHOTOGRAPHY="shotwell gimp gimp-data gimp-data-extras pinta mypainti hugin"
PKGS=$PHOTOGRAPHY && install && log

CLIAPPS="tmux tcsh zsh zsh-doc htop"
PKGS=$CLIAPPS && install && log

SYSTEMAPPS="gparted blueman synaptic preload etherwake wakeonlan"
PKGS=$SYSTEMAPPS && install && log

DEVELOPMENT="build-essential check checkinstall cdbs devscripts dh-make fakeroot geany geany-plugins libxml-parser-perl subversion git git-core sharutils uudeview vim vim-gnome vim-doc vim-scripts vim-latexsuite"
PKGS=$DEVELOPMENT && install && log

JAVA="openjdk-7-jre icedtea-7-plugin"
PKGS=$JAVA && install && log

DRIVERS="hplip-gui"
PKGS=$DRIVERS && install && log

SMARTCARD="libpcsclite1 pcscd pcsc-tools"
PKGS=$SMARTCARD && install && log

MEDIA="vlc banshee banshee-extension-ampache"
PKGS=$MEDIA && install && log

AUDIO_TOOLS="audacity pavucontrol"
PKGS=$AUDIO_TOOLS && install && log

VIDEO_TOOLS="blender avidemux cheese devede"
PKGS=$VIDEO_TOOLS && install && log

WWW="kompozer bluefish chromium-browser mint-flashplugin mpack clamz"
PKGS=$WWW && install && log

COMMS="skype pidgin pidgin-otr pidgin-encryption"
PKGS=$COMMS && install && log

VIRTUALIZATION="virtualbox-qt gns3"
PKGS=$VIRTUALIZATION && install && log

FILE_TOOLS="rar unrar p7zip-rar p7zip zip unzip sharutils uudeview mpack lha cabextract mdbtools mdbtools-doc mdbtools-gmdb pdfshuffler"
PKGS=$FILE_TOOLS && install && log

DESKTOP="conky-all gtk-redshift"
PKGS=$DESKTOP && install && log

GOOGLEEARTH="lsb-core googleearth-package"
PKGS=$GOOGLEEARTH && install && log

CODECS="ffmpeg flac libmad0 totem-mozilla easytag icedax id3tool id3v2 lame libquicktime2 sox tagtool faac libdvdcss2 libdvdnav4 libdvdread4"
PKGS=$CODECS && install && log

PKGS=$PPAs && install && log


# Finally end with a cleanup
apt-get -y autoclean

egrep '^none\t\t/tmp\t\ttmpfs' /etc/fstab
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    echo -e "[ SKIP  ] - /tmp and /var/tmp already configured for tmpfs" >> $TEMPLOG
else
    echo -e "none\t\t/tmp\t\ttmpfs\trw,nosuid,nodev,mode=01777\t0\t0" >> /etc/fstab
    echo -e "none\t\t/var/tmp\ttmpfs\trw,nosuid,nodev,mode=01777\t0\t0" >> /etc/fstab
    echo -e "[  OK   ] - /tmp and /var/tmp configured for tmpfs ramdisk" >> $TEMPLOG
    cat /etc/fstab
fi

# 1. Install prerequisite packages, this is already covered in initial setup script
#sudo apt-get install libpcsclite1 pcscd pcsc-tools

# 2. Install card reader drivers.
# http://support.identive-infrastructure.com/download_scm/download_scm.php?lang=1
SCM_PKG="scmccid_linux_64bit_driver_V5.0.21.tar.gz"
find /usr/local -regex "$SCM_PKG" -print0 | xargs -0 cp -t /tmp 
tar xvzf /tmp/$SCM_PKG -C /tmp
/tmp/scmccid_5.0.21_linux/install.sh
RETVAL=$?
PKGS=$SCM_PKG
log

# 3. DISA software can be found below, both cackey and firefox_extensions are required (CAC Login required to download, get beforehand)
# https://software.forge.mil/sf/frs/do/listReleases/projects.community_cac/frs.cackey
# http://www.forge.mil/Resources-Firefox.html
CACKEY="cackey0.6.5-1_amd64.deb"
mkdir /usr/lib64
find /usr/local -regex "$CACKEY" -print0 | xargs -0 dpkg -i
RETVAL=$?
PKGS=$CACKEY
log

# Firefox
FIREFOX="firefox_extensions-dod_configuration-1.3.6.xpi"
find /usr/local -regex "$FIREFOX" -print0 | xargs -0 firefox
RETVAL=$?
PKGS=$FIREFOX
log

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


#wget -O skype http://download.skype.com/linux/skype-ubuntu_4.0.0.8-1_amd64.deb
#sudo dpkg -i skype-ubuntu_4.0.0.8-1_amd64.deb
