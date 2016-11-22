# ${license-info}
# ${developer-info}
# ${author-info}

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
use EDG::WP4::CCM::Fetch qw(NOQUATTOR_EXITCODE);
use NCM::Check;

use File::Copy;
use Net::Ping;
use Data::Dumper;
use CAF::Process;
use CAF::FileReader;
use CAF::FileWriter;
use Fcntl qw(SEEK_SET);
use LC::File;
use POSIX qw(WIFEXITED WEXITSTATUS);

# Ethtool formats query information differently from set parameters so
# we have to convert the queries to see if the value is already set correctly

# ethtool opts that have to be ordered
my %ethtool_option_order = (
    "ethtool" => ["autoneg", "speed", "duplex"]
);

my %ethtool_option_map = (
    "offload" => {
        "tso" => "tcp segmentation offload",
        "tx"  => "tx-checksumming",
        "rx"  => "rx-checksumming",
        "ufo" => "udp fragmentation offload",
        "gso" => "generic segmentation offload",
        "gro" => "generic-receive-offload",
        "sg"  => "scatter-gather",
        },
    "ring"    => {
        "tx"  => "TX",
        "rx"  => "RX",
        },
    "ethtool" => {
        "wol" => "Wake-on",
        "autoneg" => "Advertised auto-negotiation",
        "speed" => "Speed",
        "duplex" => "Duplex",
        },
    );

my $ethtoolcmd = "/usr/sbin/ethtool";

use constant FAILED_SUFFIX => '-failed';

# gen_backup_filename: returns backup filename for given file
sub gen_backup_filename
{
    my ($self, $file) = @_;
    my $back_dir="/tmp";

    my $back="$file";
    $back =~ s/\//_/g;
    my $backup_file = "$back_dir/$back";
    return $backup_file;
}

# writes some text to file, but with backup etc etc it also
# checks between new and old and return if they are changed
# or not
sub file_dump
{
    my $func = "file_dump";

    my ($self, $file, $text, $failed) = @_;

    # check for subdirectories?
    my $backup_file = $self->gen_backup_filename($file);

    if (-e $backup_file.$failed) {
        $self->debug(3, "$func: file exits, unlink $backup_file$failed");
        unlink($backup_file.$failed) ||
            $self->warn("$func: Can't unlink $backup_file$failed ($!)");
    }

    my $fh;
    if (-e $file) {
        $self->debug(3, "$func: writing $backup_file$failed with current $file content");
        my $orig = CAF::FileReader->new($file, log => $self);
        $fh = CAF::FileWriter->new($backup_file.$failed, log => $self);
        print $fh "$orig";
        $fh->close();
    } else {
        $self->debug(3, "$func: no current $file");
    };

    $self->debug(3, "$func: writing $backup_file$failed");
    $fh = CAF::FileWriter->new($backup_file.$failed, log => $self);
    print $fh $text;

    my $ec = 0;
    if ($fh->close()) {
        if (-e $file) {
            $self->info("$func: file $file has newer version.");
            $ec = 1;
        } else {
            $self->info("$func: file $file is new.");
            $ec = 2;
        }
    } else {
        # they're equal, remove backup files
        $self->debug(3, "$func: removing equal files $backup_file and $backup_file$failed");
        unlink($backup_file) ||
            $self->warn("$func: Can't unlink $backup_file ($!)") ;
        unlink($backup_file.$failed) ||
            $self->warn("$func: Can't unlink $backup_file$failed ($!)");
    };
    return $ec;
}


sub Configure
{
    our ($self, $config)=@_;
    my $base_path = '/system/network';
    # keep a hash of all files and links.
    our (%exifiles, %exilinks);

    my ($path, $file_name, $text);

    # current setup, will be printed in case of major failure
    my $init_config = get_current_config();

    # Collect ifconfig info
    my $ifconfig_out;
    my $proc = CAF::Process->new(['/sbin/ifconfig','-a'],
                                 stdout => \$ifconfig_out,
                                 stderr => "stdout",
                                 log => $self);
    if (! $proc->execute()) {
        $ifconfig_out = "" if (! defined($ifconfig_out));

        # holy backporting batman. they finally kicked it out!
        $self->error("Running \"/sbin/ifconfig -a\" failed: output $ifconfig_out");
    }

    my @ifconfig_devs = split(/\n\s*\n/, $ifconfig_out);

    my $ifconfig_mac_regexp = '^(\S+)\s+.*?HWaddr\s+([\dA-Fa-f]{2}([:-])[\dA-Fa-f]{2}(\3[\dA-Fa-f]{2}){4})\s+';

    my (%dev2mac, %mac2dev);
    foreach my $tmp_dev (@ifconfig_devs) {
        $tmp_dev =~ s/\n/ /g;
        if ($tmp_dev =~ m/$ifconfig_mac_regexp/) {
            $dev2mac{$1} = $2;
            $mac2dev{$2} = $1;
        }
    }

    # component wide set_hwaddr setting
    $path = $base_path;
    my $set_hwaddr_default = 0;
    if ($config->elementExists($path."/set_hwaddr")) {
        if ($config->getValue($path."/set_hwaddr") eq "true") {
            $set_hwaddr_default = 1;
        }
    }

    # read interface config in hash
    $path = $base_path.'/interfaces';
    my ($iface, %net, $element, $elementname, $el, $elnr, $l, $ln, $mtu, %ethtoolconfig);
    my $net = $config->getElement($path);
    while ($net->hasNextElement()) {
        $iface = $net->getNextElement();
        my $ifacename = $iface->getName();
        # collect /system settings
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
                        $tmp_el{$ln} = $l->getValue();
                    }
                    if ($elementname =~ m/aliases/) {
                        # overwrite the alias name
                        $elnr = $tmp_el{name} if (exists($tmp_el{name}));
                        delete $tmp_el{name};
                    }
                    $net{$ifacename}{$elementname}{$elnr} = \%tmp_el;
                }
            } elsif ($elementname =~ m/^(bonding|bridging)_opts$/) {
                $net{$ifacename}{$elementname} = make_key_equal_value_string($elementname, $element);
            } elsif (defined($ethtool_option_map{$elementname})) {
                # set ethtool opts in ifcfg config (some are needed on boot (like autoneg/speed/duplex))
                $net{$ifacename}{$elementname."_opts"} = ethtool_options($element) if ($elementname eq "ethtool");
                # add rest of ethtool opts
                my $opts = $element->getTree();
                $net{$ifacename}{$elementname} = $opts;
            } elsif ($elementname =~ m/^ipv6addr_secondaries$/) {
                my $opts = $element->getTree();
                $net{$ifacename}{$elementname} = $opts;
            } else {
                $net{$ifacename}{$elementname} = $element->getValue();
            }
        }

        # collect /hardware info
        my $hw_path= "/hardware/cards/nic/".$ifacename;

        # CERN nic = list patch
        if (! $config->elementExists($hw_path)) {
            $hw_path = "/hardware/cards/nic/".$1 if ($ifacename =~ m/^eth(\d+)/);
        };
        my $hwaddr_path = $hw_path."/hwaddr";

        if ($config->elementExists($hwaddr_path)) {
            my $mac = $config->getValue($hwaddr_path);
            # check MAC address? can we trust type definitions?
            if ($mac =~ m/^[\dA-Fa-f]{2}([:-])[\dA-Fa-f]{2}(\1[\dA-Fa-f]{2}){4}$/) {
                $net{$ifacename}{'hwaddr'} = $mac;
            } else {
                $self->error("The configured hwaddr $mac for interface $ifacename ",
                             "didn't pass the regexp. Setting set_hwaddr to false. ",
                             "(Please contact the developers in case you think it is a valid MAC address).");
                $net{$ifacename}{'set_hwaddr'} = 'false';
            }
        } else {
            my $msg = "No value found for the hwaddr of interface ".
                      "$ifacename. Setting set_hwaddr to false.";
            if ($ifacename =~ m/^(bond|vlan|ib|br|ovirtmgmt)/) {
                my $hr_ifacename = $1;
                if ($hr_ifacename eq "bond") {
                    $hr_ifacename = "bonding";
                } elsif ($hr_ifacename eq "ib") {
                    $hr_ifacename = "IPoIB";
                } elsif ($hr_ifacename =~ m/^(br|ovirtmgmt)/) {
                    $hr_ifacename = "bridging";
                }
                $self->info("$msg. As it appears to be a $hr_ifacename interface, this is considered normal.");
            } else {
                $self->warn($msg);
            };
            $net{$ifacename}{'set_hwaddr'} = 'false';
        }
    }

    # read current config
    my $dir_pref="/etc/sysconfig/network-scripts";
    opendir(DIR, $dir_pref);
    # here's the reason why it only verifies eth, bond, bridge, usb and vlan
    # devices. add regexp at will
    my $dev_regexp='-((eth|seth|em|bond|br|ovirtmgmt|vlan|usb|ib|p\d+p|en(o|(p\d+)?s))\d+|enx[[:xdigit:]]{12})(\.\d+)?';
    # $1 is the device name
    foreach my $file (grep(/$dev_regexp/, readdir(DIR))) {
        my $msg;
        if ( -l "$dir_pref/$file" ) {
            # keep the links separate
            $exilinks{"$dir_pref/$file"} = readlink("$dir_pref/$file");
            $msg = "link";
        } else {
            $exifiles{"$dir_pref/$file"} = -1;
            $msg = "file";
            # backup all involved files
            if ($file =~ m/([:A-Za-z0-9.-]*)/) {
                my $untaint_file = $1;
                mk_bu("$dir_pref/$untaint_file");
            }
        }
        $self->debug(3, "Found ifcfg file $msg in dir ".$dir_pref);
    }
    closedir(DIR);

    # this is the gateway that will be used in case the default_gateway is not set
    my ($first_gateway, $first_gateway_int);

    # generate new files
    foreach $iface ( keys %net ) {
        # /etc/sysconfig/networking-scripts/ifcfg-[dev][i]
        my $file_name = "$dir_pref/ifcfg-$iface";
        $exifiles{$file_name} = 1;
        $text = "";
        if ((! $first_gateway) && $net{$iface}{gateway}) {
            $first_gateway = $net{$iface}{gateway};
            $first_gateway_int = $iface;
        }
        if ($net{$iface}{onboot}) {
            $text .= "ONBOOT=".$net{$iface}{onboot}."\n";
        } else {
            # default: assuming that ONBOOT=yes
            $text .= "ONBOOT=yes\n";
        }
        if (exists($net{$iface}{nmcontrolled}) && $net{$iface}{nmcontrolled}) {
            $text .= "NM_CONTROLLED='".$net{$iface}{nmcontrolled}."'\n";
        } else {
            # default: assuming that ONBOOT=yes
            $text .= "NM_CONTROLLED='no'\n";
        }
        # first check the device
        if ($net{$iface}{'device'}) {
            $text .= "DEVICE=".$net{$iface}{'device'}."\n";
        } else {
            $text .= "DEVICE=".$iface."\n";
        }
        # set the networktype
        if ($net{$iface}{'type'}) {
            $text .= "TYPE=".$net{$iface}{'type'}."\n";
            # Set OVS related variables
            if ($net{$iface}{'type'} =~ /^OVS/) {
                $text .= "DEVICETYPE='ovs'\n";
                if ($net{$iface}{'ovs_bridge'}) {
                    $text .= "OVS_BRIDGE='$net{$iface}{ovs_bridge}'\n";
                }
                if ($net{$iface}{'ovs_opts'}) {
                    $text .= "OVS_OPTIONS='$net{$iface}{ovs_opts}'\n";
                }
                if ($net{$iface}{'ovs_extra'}) {
                    $text .= "OVS_EXTRA=\"$net{$iface}{ovs_extra}\"\n";
                }
                if ($net{$iface}{'bond_ifaces'}) {
                    $text .= "BOND_IFACES='".join(' ',@{$net{$iface}{bond_ifaces}})."'\n";
                }
                if ($net{$iface}{'ovs_tunnel_type'}) {
                    $text .= "OVS_TUNNEL_TYPE='$net{$iface}{ovs_tunnel_type}'\n";
                }
                if ($net{$iface}{'ovs_tunnel_opts'}) {
                    $text .= "OVS_TUNNEL_OPTIONS='$net{$iface}{ovs_tunnel_opts}'\n";
                }
                if ($net{$iface}{'ovs_patch_peer'}) {
                    $text .= "OVS_PATCH_PEER='$net{$iface}{ovs_patch_peer}'\n";
                }
            }
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

        # set the HWADDR
        # what about bonding??
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

        # set the networktype
        if ( $net{$iface}{'mtu'} ) {
            $text .= "MTU=".$net{$iface}{'mtu'}."\n";
        }

        # set the bootprotocol
        my $bootproto;
        if ( $net{$iface}{'bootproto'} ) {
            $bootproto=$net{$iface}{'bootproto'};
        } else {
            $bootproto="static";
        }
        $text .= "BOOTPROTO=".$bootproto."\n";

        if ($bootproto eq "static") {
            # set ipaddr
            if ($net{$iface}{'ip'}) {
                $text .= "IPADDR=".$net{$iface}{'ip'}."\n";
            } else {
                $self->error("Using static bootproto and no ",
                             "ipaddress configured for $iface");
            }
            # set netmask
            if ($net{$iface}{'netmask'}) {
                $text .= "NETMASK=".$net{$iface}{'netmask'}."\n";
            } else {
                $self->error("Using static bootproto and no netmask ",
                             "configured for $iface");
            }
            # set broadcast
            if ($net{$iface}{'broadcast'}) {
                $text .= "BROADCAST=".$net{$iface}{'broadcast'}."\n";
            } else {
                $self->warn("Using static bootproto and no broadcast ",
                            "configured for $iface");
            }
        } elsif (($bootproto eq "none") && $net{$iface}{'master'}) {
            # set bonding master
            $text .= "MASTER=".$net{$iface}{'master'}."\n";
            $text .= "SLAVE=yes\n";
        }

        # IPv6 additions
        my $use_ipv6;

        if ($net{$iface}{'ipv6addr'}) {
            $text .= "IPV6ADDR=".$net{$iface}{'ipv6addr'}."\n";
            $use_ipv6 = 1;
        }
        if ($net{$iface}{'ipv6addr_secondaries'} && @{$net{$iface}{'ipv6addr_secondaries'}}) {
            $text .= "IPV6ADDR_SECONDARIES='".join(' ', @{$net{$iface}{'ipv6addr_secondaries'}})."'\n";
            $use_ipv6 = 1;
        }
        if (exists($net{$iface}{ipv6_autoconf})) {
            if ( $net{$iface}{ipv6_autoconf} eq "true") {
                $text .= "IPV6_AUTOCONF=yes\n";
                $use_ipv6 = 1;
            } else {
                $text .= "IPV6_AUTOCONF=no\n";
                if ( ! $net{$iface}{'ipv6addr'}) {
                    $self->warn("Disabled IPv6 autoconf but no address configured for $iface.");
                }
            }
        }
        if (defined($net{$iface}{'ipv6_rtr'}) ) {
            if ( $net{$iface}{'ipv6_rtr'} eq "true" ) {
                $text .= "IPV6_ROUTER=yes\n";
            } else {
                $text .= "IPV6_ROUTER=no\n";
            }
            $use_ipv6 = 1;
        }
        if (defined($net{$iface}{'ipv6_mtu'})) {
            $text .= "IPV6_MTU=".$net{$iface}{'ipv6_mtu'}."\n";
            $use_ipv6 = 1;
        }
        if (defined($net{$iface}{'ipv6_privacy'}) && $net{$iface}{'ipv6_privacy'}) {
            $text .= "IPV6_PRIVACY=".$net{$iface}{'ipv6_privacy'}."\n";
            $use_ipv6 = 1;
        }
        if (defined($net{$iface}{'ipv6_failure_fatal'}) ) {
            if ( $net{$iface}{'ipv6_failure_fatal'} eq "true" ) {
                $text .= "IPV6_FAILURE_FATAL=yes\n";
            } else {
                $text .= "IPV6_FAILURE_FATAL=no\n";
            }
            $use_ipv6 = 1;
        }
        if (defined($net{$iface}{'ipv4_failure_fatal'}) ) {
            if ( $net{$iface}{'ipv4_failure_fatal'} eq "true" ) {
                $text .= "IPV4_FAILURE_FATAL=yes\n";
            } else {
                $text .= "IPV4_FAILURE_FATAL=no\n";
            }
        }
        if (defined($net{$iface}{ipv6init}) ) {
            # ipv6_init overrides implicit IPv6 enable by config
            if ( $net{$iface}{ipv6init} eq "true") {
                $use_ipv6 = 1;
            } else {
                $use_ipv6 = 0;
            }
        }
        if ( defined ( $use_ipv6 ) ) {
            if ( $use_ipv6 ) {
                $text .= "IPV6INIT=yes\n";
            } else {
                $text .= "IPV6INIT=no\n";
            }
        }

        # LINKDELAY
        if (exists($net{$iface}{linkdelay})) {
            $text .= "LINKDELAY=".$net{$iface}{linkdelay}."\n";
        }

        # set some bridge-releated parameters
        # bridge STP
        if (exists($net{$iface}{stp})) {
            if ($net{$iface}{stp}) {
                $text .= "STP=on\n";
            } else {
                $text .= "STP=off\n";
            }
        }
        # bridge DELAY
        if (exists($net{$iface}{delay})) {
            $text .= "DELAY=".$net{$iface}{delay}."\n";
        }

        # add generated options strings
        if (exists($net{$iface}{bonding_opts})) {
            $text .= $net{$iface}{bonding_opts};
        }

        if (exists($net{$iface}{bridging_opts})) {
            $text .= $net{$iface}{bridging_opts};
        }

        if (exists($net{$iface}{ethtool_opts})) {
            $text .= $net{$iface}{ethtool_opts};
        }


        # VLAN support
        # you do not need to set this for the VLAN device
        $net{$iface}{vlan} = "true" if ($iface =~ m/^vlan\d+/);
        if (exists($net{$iface}{vlan})) {
            if ($net{$iface}{vlan} eq "true") {
                $text .= "VLAN=yes\n";
                # is this really needed?
                $text .= "ISALIAS=no\n";
            } else {
                $text .= "VLAN=no\n";
            }
        }
        # interfaces named vlan need the physdev set and pointing to an existing interface
        if ($iface =~ m/^vlan\d+/) {
            if (exists($net{$iface}{physdev})) {
                $text .= "PHYSDEV=".$net{$iface}{physdev}."\n";
            } else {
                $self->error("vlan device with vlan[0-9]{0-9} naming convention need physdev set.");
            }
        }

        # write iface ifcfg- file text
        $exifiles{$file_name} = $self->file_dump($file_name, $text, FAILED_SUFFIX);
        $self->debug(3,"exifiles $file_name has value ".$exifiles{$file_name});

        # route config, interface based.
        # hey, where are the static routes?
        if (exists($net{$iface}{route})) {
            $file_name = "$dir_pref/route-$iface";
            $exifiles{$file_name} = 1;
            $text = "";
            foreach my $rt (sort keys %{$net{$iface}{route}}) {
                if ($net{$iface}{route}{$rt}{'address'}) {
                    $text .= "ADDRESS$rt=" .
                        $net{$iface}{route}{$rt}{'address'}."\n";
                }
                if ($net{$iface}{route}{$rt}{'gateway'}) {
                    $text .= "GATEWAY$rt=" .
                        $net{$iface}{route}{$rt}{'gateway'}."\n";
                }
                if ($net{$iface}{route}{$rt}{'netmask'}) {
                    $text .= "NETMASK$rt="  .
                        $net{$iface}{route}{$rt}{'netmask'}."\n";
                } else {
                    $text .= "NETMASK".$rt."=255.255.255.255\n";
                }
            };
            $exifiles{$file_name} = $self->file_dump($file_name, $text, FAILED_SUFFIX);
            $self->debug(3, "exifiles $file_name has value ".$exifiles{$file_name});
        }
        # set up aliases for interfaces
        # on file per alias
        if (exists($net{$iface}{aliases})) {
            foreach my $al (keys %{$net{$iface}{aliases}}) {
                $file_name = "$dir_pref/ifcfg-".$iface.":".$al;
                $exifiles{$file_name} = 1;
                my $tmpdev;
                if ($net{$iface}{'device'}) {
                    $tmpdev = $net{$iface}{'device'}.':'.$al;
                } else {
                    $tmpdev = $iface.':'.$al;
                };
                # this is the only way it will work for VLANs
                # if vlan device is vlanX and teh DEVICE is eg ethY.Z
                #   you need a symlink to ifcfg-ethY.Z:alias <- ifcfg-vlanX:alias
                # otherwise ifup 'ifcfg-vlanX:alias' will work, but restart of network will look for
                # ifcfg-ethY.Z:alias associated with vlan0 (and DEVICE field)
                # problem is, we want both
                # adding symlinks however is not the best thing to do...
                if (exists($net{$iface}{vlan}) && ($net{$iface}{vlan} eq "true")) {
                    my $file_name_sym = "$dir_pref/ifcfg-$tmpdev";
                    if ($file_name_sym ne $file_name) {
                        if (! -e $file_name_sym) {
                            # this will create broken link, if $file_name is not yet existing
                            if (! -l $file_name_sym) {
                                symlink($file_name,$file_name_sym) ||
                                    $self->error("Failed to create symlink ",
                                                 "from $file_name to $file_name_sym ($!)");
                            };
                        };
                    };
                };
                $text = "DEVICE=$tmpdev\n";
                if ($net{$iface}{aliases}{$al}{'ip'}) {
                    $text .= "IPADDR=".$net{$iface}{aliases}{$al}{'ip'}."\n";
                }
                if ($net{$iface}{aliases}{$al}{'broadcast'}) {
                    $text .= "BROADCAST=".$net{$iface}{aliases}{$al}{'broadcast'}."\n";
                }
                if ($net{$iface}{aliases}{$al}{'netmask'}) {
                    $text .= "NETMASK=".$net{$iface}{aliases}{$al}{'netmask'}."\n";
                }
                $exifiles{$file_name} = $self->file_dump($file_name, $text, FAILED_SUFFIX);
                $self->debug(3, "exifiles $file_name has value ".$exifiles{$file_name});
            }
        }

    }

    # /etc/sysconfig/network
    # assuming that NETWORKING=yes
    $path=$base_path;
    $file_name = "/etc/sysconfig/network";
    mk_bu($file_name);
    $exifiles{$file_name}=-1;
    $text = "";
    $text .= "NETWORKING=yes\n";
    # set hostname.
    if ($config->elementExists($path."/realhostname")) {
        $text .= "HOSTNAME=".$config->getValue($path."/realhostname")."\n";
    } else {
        $text .= "HOSTNAME=".$config->getValue($path."/hostname").".".$config->getValue($path."/domainname")."\n";
    }
    # default gateway. why is this optional?
    #
    # what happens if no default_gateway is defined?
    # search for first defined gateway and use it.
    # here's the flag: default true
    #
    my $missing_default_gateway_autoguess = 1;
    if ($config->elementExists($path."/guess_default_gateway")) {
        if ($config->getValue($path."/guess_default_gateway") eq "false") {
            $missing_default_gateway_autoguess = 0;
        }
    }

    my $nogw_msg = "No default gateway defined in /system/network/default_gateway";
    if ($config->elementExists($path."/default_gateway")) {
        $text .= "GATEWAY=".$config->getValue($path."/default_gateway")."\n";
    } elsif ($missing_default_gateway_autoguess) {
        if ($first_gateway eq '') {
            $self->warn("$nogw_msg AND no interface found with a gateway configured.");
        } else {
            $self->info("$nogw_msg Going to use the gateway $first_gateway ",
                        "configured for device $first_gateway_int.");
            $text .= "GATEWAY=$first_gateway\n";
        }
    } else {
        $self->warn($nogw_msg);
    }

    # nisdomain
    if ($config->elementExists($path."/nisdomain")) {
        $text .= "NISDOMAIN=".$config->getValue($path."/nisdomain")."\n";
    }
    # nozeroconf
    if ($config->elementExists($path."/nozeroconf")) {
        if ($config->getValue($path."/nozeroconf") eq "true") {
            $text .= "NOZEROCONF=yes\n";
        } else {
            $text .= "NOZEROCONF=no\n";
        }
    }
    # gatewaydev
    if ($config->elementExists($path."/gatewaydev")) {
        $text .= "GATEWAYDEV=".$config->getValue($path."/gatewaydev")."\n";
    }
    # nmcontrolled
    if ($config->elementExists($path."/nmcontrolled")) {
        if ($config->getValue($path."/nmcontrolled") eq "true") {
            $text .= "NM_CONTROLLED=yes\n";
        } else {
            $text .= "NM_CONTROLLED=no\n";
        }
    }

    # Enable and config IPv6 if either set explicitly or v6 config is present
    # but note that the order of the v6 directive processing is important to
    # make the 'default' enable do the right thing
    if ($config->elementExists("$path/ipv6")) {
        my $use_ipv6 = 0;
        if ($config->elementExists("$path/ipv6/default_gateway")) {
            $text .= "IPV6_DEFAULTGW=".$config->getValue("$path/ipv6/default_gateway")."\n";
            $use_ipv6 = 1; # enable ipv6 for now
        }
        if ($config->elementExists("$path/ipv6/gatewaydev")) {
            $text .= "IPV6_DEFAULTDEV=".$config->getValue("$path/ipv6/gatewaydev")."\n";
            $use_ipv6 = 1; # enable ipv6 for now
        }
        if ($config->elementExists("$path/ipv6/enabled")) {
            if ($config->getValue("$path/ipv6/enabled") eq "true") {
                $use_ipv6 = 1;
            } else {
                $use_ipv6 = 0;
            }
        }
        if ($use_ipv6) {
            $text .= "NETWORKING_IPV6=yes\n";
        } else {
            $text .= "NETWORKING_IPV6=no\n";
        }
    }

    $exifiles{$file_name} = $self->file_dump($file_name, $text, FAILED_SUFFIX);
    $self->debug(3, "exifiles $file_name has value ".$exifiles{$file_name});


    # we now have a list with files and values.
    # for general network: separate?
    # for devices: create list of affected devices

    # For now, the order of vlans is not changed and left completely to the network scripts
    # I have 0 (zero) intention to support in this component things like vlans on bonding slaves, aliases on bonded vlans
    # If you need this, buy more network adapters ;)
    my (%ifdown, %ifup);
    foreach my $file (keys %exifiles) {
        if ($file =~ m/$dev_regexp/) {
            my $if = $1;
            # ifdown: all devices that have files with non-zero status
            if ($exifiles{$file} != 0) {
                $self->debug(3, "exifiles file $file with non-zero value found: ".$exifiles{$file});
                $ifdown{$if} = 1;
                # bonding: if you bring down a slave, always bring
                # down it's master
                if (exists($net{$if}{'master'})) {
                    $ifdown{$net{$if}{'master'}} = 1;
                } elsif ($file =~ m/ifcfg-$if/) {
                    # here's the tricky part: see if it used to be a slave. the bond-master must be restarted for this.
                    my $sl = "";
                    my $ma = "";
                    if (-e $file) {
                        $self->debug(3, "reading ifcfg from the backup ", $self->gen_backup_filename($file));
                        my $fh = CAF::FileReader->new($self->gen_backup_filename($file), log => $self);
                        while (my $l = <$fh>) {
                            $sl = $1 if ($l =~ m/SLAVE=(\w+)/);
                            $ma = $1 if ($l =~ m/MASTER=(\w+)/);
                        }
                        $fh->close();
                    }
                    $ifdown{$ma} = 1 if (($sl eq "yes") && ($ma =~ m/bond/));
                } elsif (exists($net{$if}{'set_hwaddr'})
                        && $net{$if}{'set_hwaddr'} eq 'true') {
                    # to use HWADDR
                    # stop the interface with this macaddress (if any)
                    if (exists($mac2dev{$net{$if}{'hwaddr'}})) {
                        $ifdown{$mac2dev{$net{$if}{'hwaddr'}}} = 1;
                    }
                }
            }
        } elsif ($file eq "/etc/sysconfig/network") {
            # nothing needed
        } else {
            $self->error("Filename $file found that doesn't match  the ",
                         "regexp. Must be an error in ncm-network. ",
                         "Exiting.");
            # We can safely exit here, since no files have been
            # modified yet.
            return 1;
        }
    }
    foreach my $if (keys %ifdown) {
        # ifup: all devices that are in ifdown and have a 0 or 1
        # status for ifcfg-[dev]
        $ifup{$if} = 1 if ($exifiles{"$dir_pref/ifcfg-$if"} != -1);
        # bonding devices: don't bring the slaves up, only the master
        delete $ifup{$if} if (exists($net{$if}{'master'}));
    }

    # Do ethtool processing for offload, ring and others
    foreach my $iface ( keys %net ) {
        foreach my $sectionname (keys %ethtool_option_map) {
            ethtoolSetOptions($iface,$sectionname,$net{$iface}{$sectionname}) if ($net{$iface}{$sectionname});
        };
    };

    my @disablenm_cmds = ();

    ## allow NetworkMnager to run or not?
    if ($config->elementExists($path."/allow_nm") && $config->getValue($path."/allow_nm") ne "true") {
        # no checking, forcefully stopping NetworkManager
        # warning: this can cause troubles with the recovery to previous state in case of failure
        # it's always better to disbale the NetworkManager service with ncm-chkconfig and have it run pre ncm-network
        # (or better yet, post ncm-spma)
        push(@disablenm_cmds,["/sbin/chkconfig --level 2345 NetworkManager off"]);
        push(@disablenm_cmds,["/sbin/service NetworkManager stop"]);
        $self->runrun(@disablenm_cmds);
    };

    # restart network
    # capturing system output/exit-status here is not useful.
    # network status is tested separately
    my @cmds = ();
    # ifdown dev OR network stop
    if ($exifiles{"/etc/sysconfig/network"} == 1) {
        @cmds = [qw(/sbin/service network stop)];
    } else {
        foreach my $if (sort keys %ifdown) {
            # how do we actually know that the device was up?
            # eg for non-existing device eth4: /sbin/ifdown eth4 --> usage: ifdown <device name>
            push(@cmds, ["/sbin/ifdown", $if]);
        }
    }
    $self->runrun(@cmds);
    # replace modified/new files
    foreach my $file (keys %exifiles) {
        if (($exifiles{$file} == 1) || ($exifiles{$file} == 2)) {
            copy($self->gen_backup_filename($file).FAILED_SUFFIX,$file) ||
                $self->error("replace modified/new files: can't copy ",
                             $self->gen_backup_filename($file).FAILED_SUFFIX,
                             " to $file. ($!)");
        } elsif ($exifiles{$file} == -1) {
            unlink($file) || $self->error("replace modified/new files: can't unlink $file. ($!)");
        }
    }
    # ifup OR network start
    if (($exifiles{"/etc/sysconfig/network"} == 1) ||
        ($exifiles{"/etc/sysconfig/network"} == 2)) {
        @cmds = [qw(/sbin/service network start)];
    } else {
        @cmds = ();
        foreach my $if (sort keys %ifup) {
            # how do we actually know that the device was up?
            # eg for non-existing device eth4: /sbin/ifdown eth4 --> usage: ifdown <device name>
            push(@cmds, ["/sbin/ifup", $if, "boot"]);
            push(@cmds, [qw(sleep 10)]) if ($if =~ m/bond/);
        }
    }
    $self->runrun(@cmds);
    # test network
    if (test_network()) {
        # if ok, clean up backups
        foreach my $file (keys %exifiles) {
            # don't clean up files that are not changed
            if ($exifiles{$file} != 0) {
                if (-e $self->gen_backup_filename($file)) {
                    unlink($self->gen_backup_filename($file)) ||
                        $self->warn("cleanup backups: can't unlink ",
                                    $self->gen_backup_filename($file),
                                    " ($!)") ;
                }
                if (-e $self->gen_backup_filename($file).FAILED_SUFFIX) {
                    unlink($self->gen_backup_filename($file).FAILED_SUFFIX) ||
                        $self->warn("cleanup backups: can't unlink ",
                                    $self->gen_backup_filename($file).FAILED_SUFFIX,
                                    " ($!)");
                }
            }
        }
    } else {
        $self->error("Network restart failed. ",
                     "Reverting back to original config. ",
                     "Failed modified configfiles can be found in ",
                     $self->gen_backup_filename(" "), "with suffix ",FAILED_SUFFIX,
                     "(If there aren't any, it means only some devices ",
                     "were removed.)");
        # if not, revert and pray now done with a pure network
        # stop/start it's the only thing that should always work.

        # current config. useful for debugging
        my $failure_config=get_current_config();

        $self->runrun([qw(/sbin/service network stop)]);

        # revert to original files
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
                copy($self->gen_backup_filename($file),$file) ||
                    $self->error("Can't copy ".$self->gen_backup_filename($file)." to $file.");
            } elsif ($exifiles{$file} == -1) {
                $self->info("RECOVER: Restoring file $file.");
                if (-e $file) {
                    unlink($file) || $self->warn("Can't unlink ".$file) ;
                }
                copy($self->gen_backup_filename($file),$file) ||
                    $self->error("Can't copy ".$self->gen_backup_filename($file)." to $file.");
            }
        }
        # ifup OR network start
        $self->runrun([qw(/sbin/service network start)]);

        # test it again
        my $nw_test = test_network();
        if ($nw_test) {
            $self->info("Old network config restored.");
        } else {
            $self->error("Restoring old config failed.");
        }
        $self->info("Result of test_network_ping: ".test_network_ping());
        $self->info("Initial setup\n$init_config");
        $self->info("Setup after failure\n$failure_config");
        $self->info("Current setup\n".get_current_config());

        if (! $nw_test) {
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

    # remove all unresolved links
    # final cleanup
    for my $link (keys %exilinks) {
        unlink($link) if (! -e $link);
    };

    # end of Configure

    sub mk_bu {
        my $func="mk_bu";
        ## makes backup of file
        my $file = shift || $self->error("$func: No file given.");

        $self->debug(3,"$func: create backup of $file to ".$self->gen_backup_filename($file));
        copy($file, $self->gen_backup_filename($file)) ||
            $self->error("$func: Can't create backup of $file to ",
                         $self->gen_backup_filename($file), " ($!)");
    }

    sub test_network {
        #return test_network_ping();
        return test_network_ccm_fetch();
    }

    sub test_network_ccm_fetch {
        # only download file, don't really ccm-fetch!!
        my $func = "test_network_ccm_fetch";
        # sometimes it's possible that routing is a bit behind, so set this variable to some larger value
        my $sleep_time = 15;
        sleep($sleep_time);
        # it should be in $PATH
        $self->info("$func: trying ccm-fetch");
        # no runrun, as it would trigger error (and dependency failure)
        my $output = CAF::Process->new(["ccm-fetch"], log => $self)->output();
        my $exitcode=$?;
        if ($exitcode == 0) {
            $self->info("$func: OK: network up");
            return 1;
        } elsif (WIFEXITED($exitcode) && WEXITSTATUS($exitcode) == NOQUATTOR_EXITCODE) {
            $self->warn("$func: ccm-fetch failed with NOQUATTOR. Testing network with ping.");
            return test_network_ping();
        } else {
            $self->warn("$func: FAILED: network down");
            return 0;
        }
    }

    sub get_current_config {
        my $output;
        my $fh = CAF::FileReader->new("/etc/sysconfig/network",
                                      log => $self);
        $output = "$fh";

        $output .= $self->runrun([qw(ls -ltr /etc/sysconfig/network-scripts)]);
        $output .= $self->runrun(["/sbin/ifconfig"]);
        $output .= $self->runrun([qw(/sbin/route -n)]);

        # when brctl is missing, this would generate an error.
        # but it is harmless to skip the show command.
        my $brexe = "/usr/sbin/brctl";
        if (-x $brexe) {
            $output .= $self->runrun([$brexe, "show"]);
        } else {
            $output .= "Missing $brexe executable.\n";
        };

        return $output;
    }

    sub test_network_ping {
        my $func = "test_network_ping";

        # sometimes it's possible that routing is a bit behind, so
        # set this variable to some larger value
        my $sleep_time = 15;
        # set port number of CDB server that should be reachable
        # (like http or https)
        my $profile = $config->getValue("/software/components/ccm/profile");
        my $pro = $profile;
        $pro =~ s/:\/\/.+//;
        my $host = $profile;
        $host =~ s/.+:\/\///;
        $host =~ s/\/.+//;
        sleep($sleep_time);
        my $p = Net::Ping->new("tcp");

        # check for portnumber in host
        if ($host =~ m/:(\d+)/) {
            $p->{port_num} = $1;
            $host =~ s/:(\d+)//;
        } else {
            # get it by service if not explicitly defined
            $p->{port_num} = getservbyname($pro, "tcp");
        }

        my $ec;
        if ($p->ping($host)) {
            $self->info("$func: OK: network up");
            $ec = 1;
        } else {
            $self->warn("$func: FAILED: network down");
            $ec = 0;
        }
        $p->close();

        return $ec;
    }

    sub runrun {
        my ($self, @cmds) = @_;
        return if (!@cmds);

        my @output;

        foreach my $i (@cmds) {
            push(@output, CAF::Process->new($i, log => $self)->output());
            if ($?) {
                $self->error("Error output: $output[-1]");
           }
        }

        return join("", @output);
    }


    # Get current ethtool options for the given section
    sub ethtoolGetCurrent {
        my ($ethname,$sectionname)=@_;
        my %current;

        my $showoption="--show-$sectionname";
        $showoption="" if ($sectionname eq "ethtool");

        my ($out,$err);
        # Skip empty showoption when calling ethtool (bug reported by D.Dykstra)
        if (CAF::Process->new([$ethtoolcmd, $showoption || (), $ethname],
                              "stdout" => \$out,
                              "stderr" => \$err
            )->execute() ) {
            foreach (split('\n', $out)) {
                if (m/^\s*(\S.*?)\s*:\s*(\S.*?)\s*$/) {
                    my $k = $1;
                    my $v = $2;
                    # speed setting
                    $v = $1 if ($k eq $ethtool_option_map{ethtool}{speed} && $v =~ m/^(\d+)/);
                    # Duplex setting
                    $v =~ tr/A-Z/a-z/ if ($k eq $ethtool_option_map{ethtool}{duplex});
                    # auotneg setting
                    if ($k eq $ethtool_option_map{ethtool}{autoneg}) {
                        $v = "off";
                        $v = "on" if ($v =~ m/(Y|y)es/);
                    }

                    $current{$k} = $v;
                }
            }
        } else {
            $self->error("ethtoolGetCurrent: cmd \"$ethtoolcmd $showoption $ethname\" failed.",
                         " (output: $out, stderr: $err)");
        }
        return %current;
    }


    sub ethtoolSetOptions {
        my ($ethname,$sectionname,$optionref)=@_;
        my %options = %$optionref;
        my $cmd;

        # get current values into %current
        my %current = ethtoolGetCurrent($ethname,$sectionname);

        # Loop over template settings and check that they are known but different

        # key ordering (important for autoneg/speed/duplex)
        my @optkeys;
        foreach my $tmp (@{$ethtool_option_order{$sectionname}}) {
            push(@optkeys, $tmp) if (grep {$_ eq $tmp} sort(keys(%options)));
        };
        foreach my $tmp (sort keys %options) {
            push(@optkeys, $tmp) if (!(grep {$_ eq $tmp} @optkeys));
        };

        my @opts;
        for my $k (@optkeys) {
            my $v = $options{$k};
            my $currentv;
            if (exists($current{$k})) {
                $currentv = $current{$k};
            } elsif ($current{$ethtool_option_map{$sectionname}{$k}}) {
                $currentv = $current{$ethtool_option_map{$sectionname}{$k}};
            } else {
                $self->info("ethtoolSetOptions: Skipping setting for ",
                            "$ethname/$sectionname/$k to $v as not in ethtool");
                next;
            }

            # Is the value different between template and the machine
            if ($currentv eq $v) {
                $self->verbose("ethtoolSetOptions: Value for $ethname/$sectionname/$k is already set to $v");
            } else {
                push(@opts, $k, $v);
            }
        }

        ## nothing to do?
        return if (! @opts);

        my $setoption = "--$sectionname";
        $setoption = "--set-$sectionname" if ($sectionname eq "ring");
        $setoption = "--change" if ($sectionname eq "ethtool");
        $self->runrun([$ethtoolcmd, $setoption, $ethname, @opts])
    }

    # Creates a string defining the bonding/bridging or ethtool options.
    sub make_key_equal_value_string {
        my ($variablename, $el) = @_;
        my $opts = $el->getTree();
        my @op;

        while (my ($k, $v) = each(%$opts)) {
            push(@op, "$k=$v");
        }

        return uc($variablename) . "='" . join(' ', @op) . "'\n";
    }

    sub ethtool_options {
        my ($el) = @_;
        my $opts = $el->getTree();
        my $st = "ETHTOOL_OPTS=";

        # key ordering (important for autoneg/speed/duplex)
        my @optkeys;
        foreach my $tmp (@{$ethtool_option_order{ethtool}}) {
            push(@optkeys, $tmp) if (grep {$_ eq $tmp} sort(keys(%$opts)));
        };
        foreach my $tmp (sort keys %$opts) {
            push(@optkeys, $tmp) if (!(grep {$_ eq $tmp} @optkeys));
        };


        my @op;
        foreach my $k (@optkeys) {
            my $v = ${$opts}{$k};
            push(@op, "$k $v");
        }

        return "$st'" . join(' ', @op) . "'\n";
    }


    # real end of Configure
    return 1;
}

1;
