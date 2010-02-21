################################################################################
# This is 'network.pm', a ncm-network's file
################################################################################
#
# VERSION:    1.2.2, 14/07/09 12:24
# AUTHOR:     Stijn De Weirdt 
# MAINTAINER: Stijn De Weirdt 
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################
#######################################################################
#
# network component
#
# NCM::network - NCM component configuring network settings
#
#
# Copyright (c) 2003 German Cancio, CERN and EU DataGrid.
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

package NCM::Component::network;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element;
use NCM::Check;

use File::Compare;
use File::Copy;
use Net::Ping;
use Data::Dumper;

use LC::Process;
use LC::File;

# Ethtool formats query information differently from set parameters so
# we have to convert the queries to see if the value is already set correctly
my %ethtool_option_map=(
    "offload" => { "tso" => "tcp segmentation offload",
                   "tx"  => "tx-checksumming",
                   "rx"  => "rx-checksumming",
                   "ufo" => "udp fragmentation offload",
                   "gso" => "generic segmentation offload",
                   "gro" => "generic-receive-offload",
                   "sg"  => "scatter-gather"},

    "ring"    => { "tx"  => "TX",
                   "rx"  => "RX" },
    "ethtool" => { "wol" => "Wake-on" },
   );
my $ethtoolcmd="/usr/sbin/ethtool";

# Get current ethtool options for the given section
sub ethtoolGetCurrent {
    my ($self,$ethname,$sectionname)=@_;
    my %current;
    my $showoption="--show-$sectionname";

    $showoption="" if ($sectionname eq "ethtool");

    my $out;
    ## Skip empty showoption when calling ethtool (bug reported by D.Dykstra)
    if (LC::Process::execute([$ethtoolcmd, $showoption || (), $ethname],
                                "stdout" => \$out,
                                "stderr" => "stdout"
        ) ) {
        my $skiptillnextcolon;    # For skipping awkward chunks
        foreach (split('\n',$out)) {
            next if (/^Cannot get/);        # Normal error message
            next if (/^.*parameters for/);        # Normal error message
            next if (/^Settings for/);        # Normal error message
            next if (/^Pre-set maximums:/);        # Normal error message
            next if (/^Current hardware settings:/); # Normal error message
            next if (/^\s*$/);    # Normal error message
            next if (defined($skiptillnextcolon) && !/:/);
            undef $skiptillnextcolon;
            if (/Supported link modes:/ || /Advertised link modes:/) {
                $skiptillnextcolon=1;
                next;
            }
            my @fields=split /:/,$_;
            if (@fields!=2) {
                $self->error("Cannot parse line $_");
                next;
            }
            my $k=$fields[0];
            $k=~s/\s*$//g;
            $k=~s/^\s*//g;
            my $v=$fields[1];
            $v=~s/\s*$//g;
            $v=~s/^\s*//g;
            $current{$k}=$v;
        }
    } else {
        $self->error("ethtoolGetCurrent: cmd \"$ethtoolcmd $showoption $ethname\" failed. (output: $out)");
    }
    return %current;
}

sub ethtoolSetOptions {
    my ($self,$ethname,$sectionname,$optionref)=@_;
    my %options=%$optionref;
    my %current;
    my $cmd;

    # get current values into %current
    %current=ethtoolGetCurrent($self,$ethname,$sectionname);

    # Loop over CDB settings and check that they are known but different
    for my $k (keys %options) {
        my $v=$options{$k};
        my $currentv=$current{$k};

        # Is the ethtool description known
        if (!defined($currentv)) {
            my $tryk=$ethtool_option_map{$sectionname}{$k};
            $currentv=$current{$tryk} if defined($tryk);
        }
        if (!defined($currentv)) {
            $self->info("Skipping CDB setting for $ethname/$sectionname/$k to $v as not in ethtool");
            next;
        }

        # Is the value different between CDB and the machine
        if ($currentv eq $v) {
            $self->verbose("Value for $ethname/$sectionname/$k is already set to $v");
            next;
        }
        my $setoption="--$sectionname";
        $setoption="--set-$sectionname" if ($sectionname eq "ring");
        $setoption="--change" if ($sectionname eq "ethtool");
        $cmd="$ethtoolcmd $setoption $ethname $k $v";
        my $out;
        if (LC::Process::execute([$ethtoolcmd, $setoption, $ethname,$k,$v],
                                "stdout" => \$out,
                                "stderr" => "stdout"
            ) ) {
                $self->info("ethtoolSetOptions: Succesfully ran \"$cmd\"");
        } else {
                $self->error("ethtoolSetOptions: Failed to run \"$cmd\": output $out.");
        }
    }
}

sub doEthtool {
    our ($self,$config)=@_;

    my $interfacespath = "/system/network/interfaces";
    if ($config->elementExists($interfacespath)) {
        # go over each interface
        my $ethiterator = $config->getElement($interfacespath);
        while ($ethiterator->hasNextElement()) {
            my $ethelement=$ethiterator->getNextElement();
            my $ethname=$ethelement->getName(); # eth*
            my $attriterator=$config->getElement($interfacespath."/".$ethname);
            while ($attriterator->hasNextElement()) {
               my $sectionelement=$attriterator->getNextElement(); #
               my $sectionname=$sectionelement->getName(); # offload
               my $optionpath=$interfacespath."/".$ethname."/".$sectionname;
               next unless (defined($ethtool_option_map{$sectionname})); # Skip gateway etc
               if ($config->elementExists($optionpath)) {
                   my %options;
                   my $optioniterator=$config->getElement($optionpath);
                   while ($optioniterator->hasNextElement()) {
                      my $optionelement=$optioniterator->getNextElement(); #
                      my $optionname=$optionelement->getName(); # tso
                      my $optionvalue=$optionelement->getValue(); # yes
                      $options{$optionname}=$optionvalue;
                   }
                   ethtoolSetOptions($self,$ethname,$sectionname,\%options);
               }
            }
        }
    }

    return;
}

# Creates a string defining the bonding options.
sub bonding_options {
    my ($self, $el) = @_;
    my $opts = $el->getTree();
    my $st = "BONDING_OPTIONS=";
    my @op;

    while (my ($k, $v) = each(%$opts)) {
        push(@op, "$k=$v");
    }

    return "$st'" . join(' ', @op) . "'\n";
}

##########################################################################
sub Configure {
##########################################################################

    our ($self,$config)=@_;
    my $base_path = '/system/network';
    ## keep a hash of all files.
    our  %exifiles;
    my $fail="-failed";

    my ($path,$file_name,$text);

    ## current setup, will be printed in case of major failure    
    my $init_config=get_current_config();

    ###
    ### Collect ifconfig info
    ###
    my $ifconfig_out;
    if(LC::Process::execute(['/sbin/ifconfig','-a'],
                                "stdout" => \$ifconfig_out,
                                "stderr" => "stdout"
            ) ) {
            ## euhm, yeah....
    } else {
        ## holy backporting batman. they finally kicked it out!
        $self->error("Running \"/sbin/ifconfig -a\" failed: output $ifconfig_out.")
    }

    my @ifconfig_devs = split(/\n\s*\n/,$ifconfig_out);

    my $ifconfig_mac_regexp='^(\S+)\s+.*?HWaddr\s+([\dA-Fa-f]{2}([:-])[\dA-Fa-f]{2}(\3[\dA-Fa-f]{2}){4})\s+';

    my (%dev2mac,%mac2dev);
    foreach my $tmp_dev (@ifconfig_devs) {
        $tmp_dev =~ s/\n/ /g;
        if ($tmp_dev =~ m/$ifconfig_mac_regexp/) {
            $dev2mac{$1}=$2;
            $mac2dev{$2}=$1;
        }
    }

    ## component wide set_hwaddr setting
    $path = $base_path;
    my $set_hwaddr_default = 0;
    if ($config->elementExists($path."/set_hwaddr")) {
        if ($config->getValue($path."/set_hwaddr") eq "true") {
            $set_hwaddr_default = 1;
        }
    }

    ################################
    ## read interface config in hash
    ################################
    $path = $base_path.'/interfaces';
    my ($iface,%net,$element,$elementname,$el,$elnr,$l,$ln, $mtu,
    $bonding_opts);
    my $net = $config->getElement($path);
    while ($net->hasNextElement()) {
        $iface = $net->getNextElement();
        my $ifacename = $iface->getName();
        ## collect /system settings
        while ($iface->hasNextElement()) {
            $element = $iface->getNextElement();
            $elementname = $element->getName();
            if ($elementname =~ m/route|aliases/) {
                while ($element->hasNextElement()) {
                    $el = $element->getNextElement();
                    ## number of route OR name of alias
                    $elnr = $el->getName();
                    my %tmp_el;
                    while ($el->hasNextElement()) {
                        $l = $el->getNextElement();
                        $ln = $l->getName();
                        $tmp_el{$ln}=$l->getValue();
                    }
                    if ($elementname =~ m/aliases/) {
                        ## overwrite the alias name
                        $elnr = $tmp_el{name} if (exists($tmp_el{name}));
                        delete $tmp_el{name};
                    }
                    $net{$ifacename}{$elementname}{$elnr}=\%tmp_el;
                }
            } elsif ($elementname !~ m/bonding_opts/) {
                $net{$ifacename}{$elementname} = $element->getValue();
            } else {
                $net{$ifacename}{$elementname} =
                $self->bonding_options($element);
            }
        }

        ## collect /hardware info
        my $hwaddr_path= "/hardware/cards/nic/".$ifacename."/hwaddr";
        if ($config->elementExists($hwaddr_path)) {
            my $mac=$config->getValue($hwaddr_path);
            ## check MAC address? can we trust type definitions?
            if ($mac =~ m/^[\dA-Fa-f]{2}([:-])[\dA-Fa-f]{2}(\1[\dA-Fa-f]{2}){4}$/) {
                $net{$ifacename}{'hwaddr'} = $mac;
            } else {
                $self->error("The configured hwaddr ".$mac." for interface ".$ifacename." didn't pass the regexp. Setting set_hwaddr to false. (Please contact the developers in case you think it is a valid MAC address).");
                $net{$ifacename}{'set_hwaddr'} = 'false'; 
            }
        } else {
            if ($ifacename =~ m/^bond/) {
                ## this is very very likely a bonding interface
                $self->info("No value found for the hwaddr ",
                            "of interface $ifacename. ",
                            "Setting set_hwaddr to false. ",
                            "As it appears to be a bonding interface, ",
                            "this very very probably not a problem. ",
                            "Please contact the developers in case you ",
                            "think it is.)");
            } elsif ($ifacename =~ m/^vlan/) {
                ## this is very very likely a vlan interface
                $self->info("No value found for the hwaddr ",
                            "of interface $ifacename. ",
                            "Setting set_hwaddr to false. ",
                            "As it appears to be a vlan interface, ",
                            "this very very probably not a problem. ",
                            "Please contact the developers in case you ",
                            "think it is.)");
            } else {
                $self->warn("No value found for the hwaddr of ",
                            "interface $ifacename. Setting set_hwaddr ",
                            "to false.");
            };
            $net{$ifacename}{'set_hwaddr'} = 'false'; 
        }
    }

    ## read current config
    my $dir_pref="/etc/sysconfig/network-scripts";
    opendir(DIR, $dir_pref);
    ## here's the reason why it only verifies eth, bond, bridge, usb and vlan
    ## devices. add regexp at will
    my $dev_regexp='-((eth|bond|br|vlan|usb)\d+(\.\d+)?)';
    ## $1 is the device name
    foreach my $file (grep(/$dev_regexp/,readdir(DIR))) {
        $exifiles{"$dir_pref/$file"} = -1;
        ## backup all involved files
        if ($file=~m/([:A-Za-z0-9.-]*)/) {
            my $untaint_file=$1;
            mk_bu("$dir_pref/$untaint_file");
        }
    }
    closedir(DIR);

    ##
    ## this is the gateway that will be used in case the default_gateway is not set
    ##
    my ($first_gateway,$first_gateway_int);

    ## generate new files
    foreach $iface ( keys %net ) {
        ### /etc/sysconfig/networking-scripts/ifcfg-[dev][i]
        my $file_name = "$dir_pref/ifcfg-$iface";
        $exifiles{$file_name} = 1;
        $text="";
        if ((! $first_gateway) && $net{$iface}{gateway}) {
            $first_gateway = $net{$iface}{gateway};
            $first_gateway_int=$iface;
        }
        if ($net{$iface}{onboot}) {
            $text .= "ONBOOT=".$net{$iface}{onboot}."\n";
        } else {
            ### default: assuming that ONBOOT=yes
            $text .=  "ONBOOT=yes\n";
        }
        ### first check the device
        if ($net{$iface}{'device'}) {
            $text .= "DEVICE=".$net{$iface}{'device'}."\n";
        } else {
            $text .= "DEVICE=".$iface."\n";
        }
        ### set the networktype
        if ( $net{$iface}{'type'} ) {
            $text .= "TYPE=".$net{$iface}{'type'}."\n";
        } else {
            $text .= "TYPE=Ethernet\n";
        }
        if ($net{$iface}{bridge}) {
            $text .= "BRIDGE='$net{$iface}{bridge}'\n";
            unless (-x "/usr/sbin/brctl") {
                $self->error ("Error: bridge specified but ",
                                "brctl not found");
            }
        }
        
        ## set the HWADDR
        ## what about bonding??
        my $set_hwaddr = 0;
        if ( exists($net{$iface}{'set_hwaddr'}) ) {
            if ( $net{$iface}{'set_hwaddr'} eq 'true') {
                $set_hwaddr = 1;
            }
        } else {
            $set_hwaddr = $set_hwaddr_default;
        }

        if ($set_hwaddr) {
            if (exists($net{$iface}{'hwaddr'})) {
                $text .= "HWADDR=".$net{$iface}{'hwaddr'}."\n";
            } else {
                # huh?
                $self->error("set_hwaddr is true and no hwaddr defined for device $iface.",
                             " Bug in component. Please contact the developers.");
            }
        }

        ### set the networktype
        if ( $net{$iface}{'mtu'} ) {
            $text .= "MTU=".$net{$iface}{'mtu'}."\n";
        }

        ### set the bootprotocol
        my $bootproto;
        if ( $net{$iface}{'bootproto'} ) {
            $bootproto=$net{$iface}{'bootproto'};
        } else {
            $bootproto="static";
        }
        $text .= "BOOTPROTO=".$bootproto."\n";

        if ($bootproto eq "static") {
            ### set ipaddr
            if ($net{$iface}{'ip'}) {
                $text .= "IPADDR=".$net{$iface}{'ip'}."\n";
            } else {
                $self->error("Using static bootproto and no ",
                             "ipaddress configured for $iface");
            }
            ### set netmask
            if ($net{$iface}{'netmask'}) {
                $text .= "NETMASK=".$net{$iface}{'netmask'}."\n";
            } else {
                $self->error("Using static bootproto and no netmask ",
                             "configured for $iface");
            }
            ### set broadcast
            if ($net{$iface}{'broadcast'}) {
                $text .= "BROADCAST=".$net{$iface}{'broadcast'}."\n";
            } else {
                $self->warn("Using static bootproto and no broadcast ",
                            "configured for $iface");
            }
        } elsif (($bootproto eq "none") && $net{$iface}{'master'}) {
            ## set bonding master
            $text .= "MASTER=".$net{$iface}{'master'}."\n";
            $text .= "SLAVE=yes\n";
        }

        if (exists($net{$iface}{bonding_opts})) {
            $text .= $net{$iface}{bonding_opts};
        }

        ## VLAN support
        ## you do not need to set this for the VLAN device
        $net{$iface}{vlan} = "true" if ($iface =~ m/^vlan\d+/);
        if( exists($net{$iface}{vlan}) ) {
            if ($net{$iface}{vlan} eq "true") {
                $text .= "VLAN=yes\n";
                ## is this really needed? 
                $text .= "ISALIAS=no\n";
            } else {
                $text .= "VLAN=no\n";
            }
        }
        ## interfaces named vlan need the physdev set and pointing to an existing interface
        if ($iface =~ m/^vlan\d+/) {
            if (exists($net{$iface}{physdev})) {
                $text .= "PHYSDEV=".$net{$iface}{physdev}."\n";
            } else {
                $self->error("vlan device with vlan[0-9]{0-9} naming convention need physdev set.");
            }
        }

        ## write iface ifcfg- file text
        $exifiles{$file_name}=file_dump($file_name,$text,$fail);

        ## route config, interface based.
        ## hey, where are the static routes?
        if (exists($net{$iface}{route})) {
            $file_name = "$dir_pref/route-$iface";
            $exifiles{$file_name} = 1;
            $text="";
            foreach my $rt (sort keys %{$net{$iface}{route}}) {
                if ( $net{$iface}{route}{$rt}{'address'}) {
                    $text .= "ADDRESS$rt=" .
                    $net{$iface}{route}{$rt}{'address'}."\n";
                }
                if ( $net{$iface}{route}{$rt}{'gateway'}) {
                    $text .= "GATEWAY$rt=" .
                    $net{$iface}{route}{$rt}{'gateway'}."\n";
                }
                if ( $net{$iface}{route}{$rt}{'netmask'}) {
                    $text .= "NETMASK$rt="  .
                    $net{$iface}{route}{$rt}{'netmask'}."\n";
                } else {
                    $text .= "NETMASK".$rt."=255.255.255.255\n";
                }
            };
            $exifiles{$file_name}=file_dump($file_name,$text,$fail);
        }
        # set up aliases for interfaces
        ## on file per alias
        if (exists($net{$iface}{aliases})) {
            foreach my $al (keys %{$net{$iface}{aliases}}) {
                $file_name = "$dir_pref/ifcfg-$iface:$al";
                $exifiles{$file_name} = 1;
                $text = "DEVICE=".$iface.':'.$al."\n";
                if ( $net{$iface}{aliases}{$al}{'ip'}) {
                    $text .= "IPADDR=".$net{$iface}{aliases}{$al}{'ip'}."\n";
                }
                if ( $net{$iface}{aliases}{$al}{'broadcast'}) {
                    $text .= "BROADCAST=".$net{$iface}{aliases}{$al}{'broadcast'}."\n";
                }
                if ( $net{$iface}{aliases}{$al}{'netmask'}) {
                    $text .= "NETMASK=".$net{$iface}{aliases}{$al}{'netmask'}."\n";
                }
                $exifiles{$file_name}=file_dump($file_name,$text,$fail);
            }
        }
        
    }   

    ###
    ### /etc/sysconfig/network
    ### assuming that NETWORKING=yes
    ###

    $path=$base_path;
    $file_name = "/etc/sysconfig/network";
    mk_bu($file_name);
    $exifiles{$file_name}=-1;
    $text = "";
    $text .= "NETWORKING=yes\n";
    ## set hostname.
    if ($config->elementExists($path."/realhostname")) {
        $text .= "HOSTNAME=".$config->getValue($path."/hostname")."\n";
    } else {
        $text .= "HOSTNAME=".$config->getValue($path."/hostname").".".$config->getValue($path."/domainname")."\n";
    }
    ## default gateway. why is this optional?
    ##
    ## what happens if no default_gateway is defined?
    ## search for first defined gateway and use it.
    ## here's the flag: default true
    ##
    my $missing_default_gateway_autoguess = 1;
    if ($config->elementExists($path."/guess_default_gateway")) {
        if ($config->getValue($path."/guess_default_gateway") eq "false") {
            $missing_default_gateway_autoguess = 0;
        }
    }

    if ($config->elementExists($path."/default_gateway")) {
        $text .= "GATEWAY=".$config->getValue($path."/default_gateway")."\n";
    } else {
        if ($missing_default_gateway_autoguess) {
            if ($first_gateway eq '') {
                $self->warn("No default gateway defined in ",
                            "/system/network/default_gateway AND no ",
                            "interface found with a gateway configured.");
            } else {
                $self->info("No default gateway defined in ",
                            "/system/network/default_gateway. ",
                            "Going to use the gateway $first_gateway ",
                            "configured for device $first_gateway_int.");
                $text .= "GATEWAY=$first_gateway\n";
            }
        } else {
            $self->warn("No default gateway defined in ",
                        "/system/network/default_gateway");
        }
    }
    ## nisdomain
    if ($config->elementExists($path."/nisdomain")) {
        $text .= "NISDOMAIN=".$config->getValue($path."/nisdomain")."\n";
    }
    ## nozeroconf
    if ($config->elementExists($path."/nozeroconf")) {
        if ($config->getValue($path."/nozeroconf") eq "true") {
            $text .= "NOZEROCONF=yes\n";
        } else {
            $text .= "NOZEROCONF=no\n";
        }
    }
    ## gatewaydev
    if ($config->elementExists($path."/gatewaydev")) {
        $text .= "GATEWAYDEV=".$config->getValue($path."/gatewaydev")."\n";
    }
    
    $exifiles{$file_name}=file_dump($file_name,$text,$fail);


    ## we now have a list with files and values.
    ## for general network: separate?
    ## for devices: create list of affected devices
    
    ## For now, the order of vlans is not chnaged and left completely to the network scripts
    ## I have 0 (zero) intention to support in this component things like vlans on bonding slaves, aliases on bonded vlans
    ## If you need this, buy more network adapters ;)
    my (%ifdown,%ifup);
    foreach my $file (keys %exifiles) {
        if ($file =~ m/$dev_regexp/) {
            my $if=$1;
            ## ifdown: all devices that have files with non-zero status
            if ($exifiles{$file} != 0) {
                $ifdown{$if}=1;
                ## bonding: if you bring down a slave, allways bring
                ## down it's master
                if (exists($net{$if}{'master'})) {
                    $ifdown{$net{$if}{'master'}}=1;
                } elsif ($file =~ m/ifcfg-$if/) {    
                    ## here's the tricky part: see if it used to be a slave. the bond-master must be restarted for this.
                    my $sl = "";
                    my $ma = "";
                    if ( -e $file) {
                        open(FILE,bu($file)) ||
                                $self->error("Can't open the backup ",
                                             bu($file), " of $file.");
                        while (<FILE>) {
                            $sl=$1 if (m/SLAVE=(\w+)/);
                            $ma=$1 if (m/MASTER=(\w+)/);
                        }
                        close(FILE);
                    }
                    $ifdown{$ma}=1 if (($sl eq "yes") && ($ma =~ m/bond/));
                } elsif (exists($net{$if}{'set_hwaddr'})
                        && $net{$if}{'set_hwaddr'} eq 'true') {
                    ## to use HWADDR
                    ## stop the interface with this macaddress (if any)
                    if (exists($mac2dev{$net{$if}{'hwaddr'}})) {
                        $ifdown{$mac2dev{$net{$if}{'hwaddr'}}}=1;
                    }
                }
            }
        } elsif ($file eq "/etc/sysconfig/network") {
            # nothing needed
        } else {
            $self->error("Filename $file found that doesn't match  the ",
                         "regexp. Must be an error in ncm-network. ",
                         "Exiting.");
            ## We can safely exit here, since no files have been
            ## modified yet.
            return 1;
        }
    }
    foreach my $if (keys %ifdown) {
        ## ifup: all devices that are in ifdown and have a 0 or 1
        ## status for ifcfg-[dev]
        $ifup{$if}=1 if ($exifiles{"$dir_pref/ifcfg-$if"} != -1);
        ## bonding devices: don't bring the slaves up, only the master
        delete $ifup{$if} if (exists($net{$if}{'master'}));
    }

    # Do ethtool processing for offload, ring and others
    doEthtool($self,$config);

    my $cmd;
    ## restart network
    ## capturing system output/exit-status here is not useful.
    ## network status is tested separately

    ## ifdown dev OR network stop
    if ($exifiles{"/etc/sysconfig/network"} == 1) {
        $cmd="/sbin/service network stop";
    } else {
        $cmd="";
        foreach my $if (sort keys %ifdown) {
            ## how do we actually know that the device was up?
            ## eg for non-existing device eth4: /sbin/ifdown eth4 --> usage: ifdown <device name>
            $cmd .= "/sbin/ifdown $if;";
        }
    }
    runrun($cmd);
    ## replace modified/new files
    foreach my $file (keys %exifiles) {
        if (($exifiles{$file} == 1) || ($exifiles{$file} == 2)) {
            copy(bu($file).$fail,$file) || $self->error("Can't copy ".bu($file).$fail." to $file.");
        } elsif ($exifiles{$file} == -1) {
            unlink($file) || $self->error("Can't unlink $file.");
        }
    }
    ## ifup OR network start
    if (($exifiles{"/etc/sysconfig/network"} == 1) ||
        ($exifiles{"/etc/sysconfig/network"} == 2)) {
        $cmd="/sbin/service network start";
    } else {
        $cmd="";
        foreach my $if (sort keys %ifup) {
            ## how do we actually know that the device was up?
            ## eg for non-existing device eth4: /sbin/ifdown eth4 --> usage: ifdown <device name>
            $cmd .= "/sbin/ifup $if boot;";
            $cmd .= "sleep 10;" if ($if =~ m/bond/);
        }
    }
    runrun($cmd);
    ## test network
    if (test_network()) {
        ## if ok, clean up backups
        foreach my $file (keys %exifiles) {
            ## don't clean up files that are not changed
            if ($exifiles{$file} != 0) {
                if (-e bu($file)) {
                    unlink(bu($file)) ||
                        $self->warn("Can't unlink ".bu($file)) ;
                }
                if (-e bu($file).$fail) {
                    unlink(bu($file).$fail) ||
                        $self->warn("Can't unlink ".bu($file).$fail);
                }
            }
        }
    } else {
        $self->error("Network restart failed. ",
                     "Reverting back to original config. ",
                     "Failed modified configfiles can be found in ",
                     bu(" "), "with suffix $fail. ",
                     "(If there aren't any, it means only some devices ",
                     "were removed.)");
        ## if not, revert and pray now done with a pure network
        ## stop/start it's the only thing that should always work.

        ## current config. useful for debugging
        my $failure_config=get_current_config();

        $cmd="/sbin/service network stop";
        runrun($cmd);
        ## revert to original files
        foreach my $file (keys %exifiles) {
            if ($exifiles{$file} == 2) {
                $self->info("RECOVER: Removing new file $file.");
                if (-e $file) {
                    unlink($file) || $self->warn("Can't unlink ".$file) ;
                }
            } elsif ($exifiles{$file} == 1) {
                $self->info("RECOVER: Replacing newer file $file.");
                if (-e $file) {
                    unlink($file) || $self->error("Can't unlink $file.") ;
                }
                copy(bu($file),$file) ||
                    $self->error("Can't copy ".bu($file)." to $file.");
            } elsif ($exifiles{$file} == -1) {
                $self->info("RECOVER: Restoring file $file.");
                if (-e $file) {
                    unlink($file) || $self->warn("Can't unlink ".$file) ;
                }   
                copy(bu($file),$file) ||
                    $self->error("Can't copy ".bu($file)." to $file.");
            }
        }
        ## ifup OR network start
        $cmd="/sbin/service network start";
        runrun($cmd);
        ## test it again
        if (test_network()) {
            $self->info("Old network config restored.");
            $self->info("Some more debug info");
            $self->info("Result of test_network_ping: ".test_network_ping());
            $self->info("Initial setup\n".$init_config);
            $self->info("Setup after failure\n".$failure_config);
            $self->info("Current setup\n".get_current_config());
        } else {
            $self->error("Restoring old config failed.");
            $self->info("Some more debug info");
            $self->info("Result of test_network_ping: ".test_network_ping());
            $self->info("Initial setup\n".$init_config);
            $self->info("Setup after failure\n".$failure_config);
            $self->info("Current setup\n".get_current_config());
            $self->info("The profile of this machine could not be ",
                "retrieved using standard mechanism ccm-fetch. ",
                "Since this should be the original configuration, ",
                "there's either a bug in ncm-network or your profile ",
                "server is/was not reachable. Run \"ccm-fetch\" ",
                "and then \"ncm-ncd --co network\" to find out more. ",
                "If you think there's a bug in this component, ",
                "please let us know.")
        };
    }
    ##
    ## end of configure
    ##

    sub bu {
        my $func="bu";
        ## returns backup filename of file
        my $file = shift || $self->error("$func: No file given.");
        my $back_dir="/tmp";

        my $back="$file";
        $back =~ s/\//_/g;
        my $backup_file = "$back_dir/$back";
        return $backup_file;
    }

    sub mk_bu {
        my $func="mk_bu";
        ## makes backup of file
        my $file = shift || $self->error("$func: No file given.");

        copy($file, bu($file)) || $self->error("$func: Can't create backup of $file to ".bu($file));
    }

    sub test_network {
        #return test_network_ping();
        return test_network_ccm_fetch();
    }

    sub test_network_ccm_fetch {
        ## only download file, don't really ccm-fetch!!
        my $func = "test_network_ccm_fetch";
        ## sometimes it's possible that routing is a bit behind, so set this variable to some larger value
        my $sleep_time = 15;
        sleep($sleep_time);
        ## it should be in $PATH
        $self->info("$func: trying ccm-fetch");
        my $cmd="ccm-fetch";
        runrun($cmd);
        my $exitcode=$?;
        if ($? == 0) {
            $self->info("$func: OK: network up");
            return 1;
        } else {
            $self->warn("$func: FAILED: network down");
            return 0;
        }
    }

    sub get_current_config {
        my $func = "get_current_config";

        my $cmd;
        my $output="";

        $cmd = "cat /etc/sysconfig/network";
        $output .= "\n$cmd\n";
        $output .= runrun($cmd);

        $cmd = "ls -ltr /etc/sysconfig/network-scripts";
        $output .= "\n$cmd\n";
        $output .= runrun($cmd);

        $cmd = "/sbin/ifconfig";
        $output .= "\n$cmd\n";
        $output .= runrun($cmd);

        $cmd="/sbin/route -n";
        $output .= "\n$cmd\n";
        $output .= runrun($cmd);

        $cmd="/usr/sbin/brctl show";
        $output .= "\n$cmd\n";
        $output .= runrun($cmd);

        return $output;
    }

    sub test_network_ping {
        my $func = "test_network_ping";

        ## sometimes it's possible that routing is a bit behind, so
        ## set this variable to some larger value
        my $sleep_time = 15;
        ## set port number of CDB server that should be reachable
        ## (like http or https)
        my $profile = $config->getValue("/software/components/ccm/profile");
        my $pro = $profile;
        $pro =~ s/:\/\/.+//;
        my $host = $profile;
        $host =~ s/.+:\/\///;
        $host =~ s/\/.+//;
        sleep($sleep_time);
        my $p = Net::Ping->new("tcp");

        ## check for portnumber in host
        if ($host =~ m/:(\d+)/) {
            $p->{port_num}=$1;
            $host =~ s/:(\d+)//;
        } else {
            # get it by service if not explicitly defined
            $p->{port_num} = getservbyname($pro, "tcp");
        }

        if ($p->ping($host)) {
            $self->info("$func: OK: network up");
            return 1;
        } else {
            $self->warn("$func: FAILED: network down");
            return 0;
        }
        $p->close();
    }

    sub file_dump {
        ## writes some text to file, but with backup etc etc it also
        ## checks between new and old and return if they are changed
        ## or not
        my $func="file_dump";

        my $file = shift || $self->error("$func: No filename.");
        my $text = shift || $self->error("$func: No text.");
        my $failed = shift || $self->error("$func: No failed suffix.");

        ## check for subdirectories?
        my $backup_file = bu($file);

        if (-e $backup_file.$failed) {
            unlink($backup_file.$failed)||
            $self->warn("$func: Can't unlink ".$backup_file.$failed);
        }

        open(FILE,"> ".$backup_file.$failed) ||
            $self->error("$func: Can't write to ".$backup_file.$failed);
        print FILE $text;
        close(FILE);
        if (compare($file,$backup_file.$failed) == 0) {
            ## they're equal, remove backup files
            unlink($backup_file) ||
            $self->warn("$func: Can't unlink ".$backup_file) ;
            unlink($backup_file.$failed) ||
            $self->warn("$func: Can't unlink ".$backup_file.$failed);
            return 0;
        } else {
            if (-e $file) {
                $self->info("$func: file ".$file." has newer version.");
                return 1;
            } else {
                $self->info("$func: file ".$file." is new.");
                return 2;
            }
        };
    }
    
    ## this is how it used to be used
    sub runrunold {
        my $cmd = shift||"";
        return if ($cmd eq "");

        ## old style
        my $output;
        $self->info("Going to run: $cmd");
        #system($cmd);
        open(FILE,$cmd." 2>&1 |");
        $output .= $_ while (<FILE>);
        close(FILE);
            
        return $output
        
    }

    sub runrun {
        my $cmd = shift|| "";
        return if ($cmd eq "");

        ## new style
        my $output;
        if(LC::Process::execute([$cmd],
                                "stdout" => \$output,
                                "stderr" => "stdout"
            ) && ($? == 0)) {
                $self->debug(4,"runrun succesfully ran \"$cmd\"");
        } else {
                $self->error("runrun failed to run \"$cmd\": output $output");
        }
        return $output;
    }


    #### real end of configure
}

1;
