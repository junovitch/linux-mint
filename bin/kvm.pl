#!/usr/bin/perl

################################################################################
##  IPMI KVM Over IP Wrapper Script  ###########################################
################################################################################
#
# This is a wrapper for the `/usr/bin/javaws` program to deal with buggy JNLP
# files produced by Supermicro's IPMI.  It prevents the "no ikvm64 found" error
# that comes up when starting a KVM over IP session.  It's applies what is 
# discussed in the blog below.
#
# http://www.p14nd4.com/blog/2011/09/30/solved-no-ikvm64-in-java-library-path-on-supermicro-ip-kvm/
#
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

use strict;
use warnings;

if (! defined $ARGV[0]) {
    print "################################################################################\n";
    print " Supermicro KVM wrapper script \n";
    print " Usage: $0 session_file \n";
    print "################################################################################\n";
} else {
    my $JNLP = $ARGV[0];
    $^I = "";
    while (<>) {
        if (/nativelib href/) {
            $_ .= "    <property name=\"jnlp.packEnabled\" value=\"true\"/>\n    <property name=\"jnlp.versionEnabled\" value=\"true\"/>\n";
        }
        print;
    }
    system `/usr/bin/javaws $JNLP`
        or die "Couldn't run javaws: $?";
    unlink $JNLP;
}
