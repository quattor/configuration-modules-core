#${PMcomponent}

=head1 NAME

network: Configure Network Settings

=head1 DESCRIPTION

The I<network> component sets the network settings through C<< /etc/sysconfig/network >>
and the various files in C<< /etc/sysconfig/network-scripts >>.

New/changed settings are first tested by retrieving the latest profile from the
CDB server (using ccm-fetch).
If this fails, the component reverts all settings to the previous values.

During this test, a sleep value of 15 seconds is used to make sure the restarted network
is fully restarted (routing may need some time to come up completely).

Because of this, configuration changes may cause the ncm-ncd run to take longer than usual.

Be aware that configuration changes can also lead to a brief network interruption.

=head1 EXAMPLES

=head2 CHANNEL BONDING

To enable channel bonding with quattor using devices eth0 and eth1 to form bond0, proceed as follows:

    include 'components/network/config';
    prefix "/system/network/interfaces";
    "eth0/bootproto" = "none";
    "eth0/master" = "bond0";

    "eth1/bootproto" = "none";
    "eth1/master" = "bond0";

    "bond0" = NETWORK_PARAMS;
    "bond0/driver" = "bonding";
    "bond0/bonding_opts/mode" = 6;
    "bond0/bonding_opts/miimon" = 100;

    include 'components/modprobe/config';
    "/software/components/modprobe/modules" = append(dict("name", "bonding", "alias", "bond0"));

    "/software/components/network/dependencies/pre" = append("modprobe");

(see C<< <kernel>/Documentation/networking/bonding.txt >> for more info on the driver options)


=head2 VLAN support

Use the C<< vlan[0-9]{0-4} >> interface devices and set the explicit device name and physdev.
The VLAN ID is the number of the '.' in the device name.
C< physdev > is mandatory for C<< vlan[0-9]{0-4} >> device.

An example:

    prefix "/system/network/interfaces";
    "vlan0" = VLAN_NETWORK_PARAMS;
    "vlan0/device" = "eth0.3";
    "vlan0/physdev" = "eth0";

=head2 IPv6 support

An example:

    prefix "/system/network";
    "ipv6/enabled" = true;
    "ipv6/default_gateway" = "2001:678:123:e030::1";
    "interfaces/eth0/ipv6_autoconf" = false;
    "interfaces/eth0/ipv6addr" = "2001:610:120:e030::49/64";
    "interfaces/eth0/ipv6addr_secondaries" = list(
        "2001:678:123:e030::20:30/64",
        "2001:678:123:e030:172:10:20:30/64",
        );

=cut

use parent qw(NCM::Component CAF::Path);

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use EDG::WP4::CCM::Fetch qw(NOQUATTOR_EXITCODE);

use Net::Ping;

use CAF::Process;
use CAF::Service;
use CAF::FileReader;
use CAF::FileEditor;
use CAF::FileWriter 17.2.1;
use NetAddr::IP;

use POSIX qw(WIFEXITED WEXITSTATUS);
use Readonly;

# Ethtool formats query information differently from set parameters so
# we have to convert the queries to see if the value is already set correctly

# ethtool opts that have to be ordered
Readonly::Hash my %ETHTOOL_OPTION_ORDER => {
    ethtool => ["autoneg", "speed", "duplex"]
};

Readonly::Hash my %ETHTOOL_OPTION_MAP => {
    offload => {
        tso => "tcp segmentation offload",
        tx  => "tx-checksumming",
        rx  => "rx-checksumming",
        ufo => "udp fragmentation offload",
        gso => "generic segmentation offload",
        gro => "generic-receive-offload",
        sg  => "scatter-gather",
    },
    ring    => {
        tx  => "TX",
        rx  => "RX",
    },
    ethtool => {
        wol => "Wake-on",
        autoneg => "Advertised auto-negotiation",
        speed => "Speed",
        duplex => "Duplex",
    },
};


Readonly my $ETHTOOLCMD => '/usr/sbin/ethtool';
Readonly my $BRIDGECMD => '/usr/sbin/brctl';
Readonly my $IPADDR => [qw(ip addr show)];
Readonly my $IPROUTE => [qw(ip route show)];
Readonly my $OVS_VCMD => '/usr/bin/ovs-vsctl';
Readonly my $HOSTNAME_CMD => '/usr/bin/hostnamectl';

Readonly my $NETWORK_PATH => '/system/network';
Readonly my $HARDWARE_PATH => '/hardware/cards/nic';

# Regexp for the supported ifcfg-<device> devices.
# $1 must match the device name
Readonly my $DEVICE_REGEXP => qr{
    - # separator from e.g. ifcfg or route
    ( # start devicename group $1
        (?:
            eth|seth|em|
            bond|br|ovirtmgmt|
            vlan|usb|vxlan|
            ib|
            p\d+p|
            en(?:
                o(?:\d+d)?| # onboard
                (?:p\d+)?s(?:\d+f)?(?:\d+d)? # [pci]slot[function][device]
            )
         )\d+| # mandatory numbering
         enx[[:xdigit:]]{12} # enx MAC address
    )
    (?:\.\d+)? # optional VLAN
    (?::\w+)? # optional alias
    $
}x;

Readonly my $IFCFG_DIR => "/etc/sysconfig/network-scripts";
Readonly my $NETWORKCFG => "/etc/sysconfig/network";

Readonly my $FAILED_SUFFIX => '-failed';
Readonly my $BACKUP_DIR => "$IFCFG_DIR/.quattorbackup";

Readonly my $REMOVE => -1;
Readonly my $NOCHANGES => 0;
Readonly my $UPDATED => 1;
Readonly my $NEW => 2;
# changes to file, but same config (eg for new file formats)
Readonly my $KEEPS_STATE => 3;


# wrapper around -x for easy unittesting
# is not part of CAF::Path
sub _is_executable
{
    my ($self, $fn) = @_;
    return -x $fn;
}

# Given the configuration ifcfg/route[6]/rule[6] filename,
# Determine if this is a valid interface for ncm-network to manage,
# Return interface name when valid, undef otherwise.
sub is_valid_interface
{
    my ($self, $filename) = @_;

    # Very primitive, based on regex only
    # Not even the full filename (eg ifcfg) or anything
    if ($filename =~ m/$DEVICE_REGEXP/) {
        return $1;
    } else {
        return;
    };
}

# Get current ethtool options for the given section
sub ethtool_get_current
{
    my ($self, $ethname, $sectionname) = @_;
    my %current;

    my $showoption = $sectionname eq "ethtool" ? "" : "--show-$sectionname";

    my ($out, $err);
    # Skip empty showoption when calling ethtool (bug reported by D.Dykstra)
    if (CAF::Process->new([$ETHTOOLCMD, $showoption || (), $ethname],
                          stdout => \$out,
                          stderr => \$err,
                          keeps_state => 1,
                          log => $self,
        )->execute() ) {
        foreach my $line (split('\n', $out)) {
            if ($line =~ m/^\s*(\S.*?)\s*:\s*(\S.*?)\s*$/) {
                my ($key, $val) = ($1, $2);
                # speed setting
                $val = $1 if ($key eq $ETHTOOL_OPTION_MAP{ethtool}{speed} && $val =~ m/^(\d+)/);
                # Duplex setting
                $val =~ tr/A-Z/a-z/ if ($key eq $ETHTOOL_OPTION_MAP{ethtool}{duplex});
                # auotneg setting
                if ($key eq $ETHTOOL_OPTION_MAP{ethtool}{autoneg}) {
                    $val = ($val =~ m/(Y|y)es/) ? "on" : "off";
                }

                $current{$key} = $val;
            }
        }
    } else {
        $self->error("ethtool_get_current: cmd \"$ETHTOOLCMD $showoption $ethname\" failed.",
                     " (output: $out, stderr: $err)");
    }
    return %current;
}

# backup_filename: returns backup filename for given file
sub backup_filename
{
    my ($self, $file) = @_;

    my $back = "$file";
    $back =~ s/\//_/g;

    return "$BACKUP_DIR/$back";
}

# Generate the filename to hold the test configuration data
# If this file still exists after the component runs, it means
# that the changes did not lead to a working network config, and
# thus this file has the (new/updated but) failed configuration;
# hence the FAILED suffix in the name.
sub testcfg_filename
{
    my ($self, $file) = @_;
    return $self->backup_filename($file) . $FAILED_SUFFIX;
}

# Given file, cleanup the backup and test config
# Returns nothing
sub cleanup_backup_test
{
    my ($self, $file) = @_;

    foreach my $type (qw(backup testcfg)) {
        my $method = $type."_filename";
        my $filename = $self->$method($file);
        # no keeps_state, under NoAction keep the backup and more importantly the testcfg
        if (! defined($self->cleanup($filename))) {
            $self->warn("Failed to cleanup $type config file $filename: $self->{fail}");
        }
    }
};


# Make copy of original file (if exists) for testing (name from testcfg_filename).
# using FileEditor source options and then write text to this testcfg.
# Return the filestate of this copy (new/updated/nochanges)
# The original file is not modified at all.
# If there were no changes, the backup and the testcfg are removed.
sub file_dump
{
    my ($self, $file, $text) = @_;

    my $func = "file_dump";

    my $testcfg = $self->testcfg_filename($file);

    if (! defined($self->cleanup($testcfg, undef, keeps_state => 1))) {
        $self->warn("Failed to cleanup testcfg $testcfg before file_dump: $self->{fail}");
    }

    # Make hardlinked copy
    #   hardlink is ok, new file will be put in place, no editing of existing file
    if (!$self->file_exists($file) || $self->mk_bu($file, $testcfg)) {
        my $fh = CAF::FileWriter->new($testcfg, log => $self, keeps_state => 1);
        print $fh join("\n", @$text, ''); # add trailing newline

        # Use 'scheduled' in messages to indicate that this method
        # does not make modifications to the file.
        my $filestatus;
        if ($fh->close()) {
            if ($self->file_exists($file)) {
                $self->info("$func: file $file has newer version scheduled.");
                $filestatus = $UPDATED;
            } else {
                $self->info("$func: new file $file scheduled.");
                $filestatus = $NEW;
            }
        } else {
            $filestatus = $NOCHANGES;
            # they're equal, remove backup files
            $self->verbose("$func: no changes scheduled for file $file. Cleaning up.");
            $self->cleanup_backup_test($file);
        };

        return $filestatus;
    } else {
        return;
    }
}

# Make a backup of the file
# Backup in same filesystem, so we can hardlink to create the backup.
# Assumes $NETWORKCFG is in same filesystem
sub mk_bu
{
    my ($self, $file, $dest) = @_;

    $dest = $self->backup_filename($file) if !$dest;
    if ($self->hardlink($file, $dest, keeps_state => 1)) {
        $self->verbose("Created backup $dest for $file");
        return 1;
    } else {
        $self->error("Failed to create backup $dest for $file: $self->{fail}");
        return;
    }
}

sub test_network_ping
{
    my ($self, $profile) = @_;

    my $func = "test_network_ping";
    if (! $profile) {
        $self->warn("$func: no profile, unable to verify network");
        return;
    }

    # sometimes it's possible that routing is a bit behind, so
    # set this variable to some larger value
    my $sleep_time = 15;
    sleep($sleep_time) if ! $self->noAction();

    # set port number of CDB server that should be reachable
    # (like http or https)
    my $proto = $profile;
    $proto =~ s/:\/\/.+//;
    my $host = $profile;
    $host =~ s/.+:\/\///;
    $host =~ s/\/.+//;

    my $ping = Net::Ping->new("tcp");

    # check for portnumber in host
    if ($host =~ m/:(\d+)/) {
        $ping->{port_num} = $1;
        $host =~ s/:(\d+)//;
    } else {
        # get it by service if not explicitly defined
        $ping->{port_num} = getservbyname($proto, "tcp");
    }

    my $ec;
    if ($ping->ping($host)) {
        $self->verbose("$func: OK: network up");
        $ec = 1;
    } else {
        $self->warn("$func: FAILED: network down");
        $ec = 0;
    }
    $ping->close();

    return $ec;
}

# Test network by downloading latest profile.
sub test_network_ccm_fetch
{
    my ($self, $profile) = @_;

    # only download file, don't really ccm-fetch!!
    my $func = "test_network_ccm_fetch";
    # sometimes it's possible that routing is a bit behind, so set this variable to some larger value
    my $sleep_time = 15;
    sleep($sleep_time) if ! $self->noAction();

    # ccm-fetch should be in $PATH
    $self->verbose("$func: trying ccm-fetch");
    # no runrun, as it would trigger error (and dependency failure)
    my $output = CAF::Process->new(["ccm-fetch"], log => $self)->output();
    my $exitcode = $?;
    if ($exitcode == 0) {
        $self->verbose("$func: OK: network up");
        return 1;
    } elsif (WIFEXITED($exitcode) && WEXITSTATUS($exitcode) == NOQUATTOR_EXITCODE) {
        $self->warn("$func: ccm-fetch failed with NOQUATTOR. Testing network with ping.");
        return $self->test_network_ping($profile);
    } else {
        $self->warn("$func: FAILED: network down");
        return 0;
    }
}

# Gather current network configuration using available tools
# Is gathered for debugging in case of failure.
sub get_current_config
{
    my ($self) = @_;

    my $fh = CAF::FileReader->new($NETWORKCFG, log => $self);
    my $output = "$NETWORKCFG\n$fh";

    $output .= "\nls -lrt $IFCFG_DIR\n";
    $output .= $self->runrun(['ls', '-ltr', $IFCFG_DIR]);

    $output .= "\n@$IPADDR\n";
    $output .= $self->runrun($IPADDR);
    $output .= "\n@$IPROUTE\n";
    $output .= $self->runrun($IPROUTE);

    # when brctl is missing, this would generate an error.
    # but it is harmless to skip the show command.
    if ($self->_is_executable($BRIDGECMD)) {
        $output .= "\n$BRIDGECMD show\n";
        $output .= $self->runrun([$BRIDGECMD, "show"]);
    } else {
        $output .= "Missing $BRIDGECMD executable.\n";
    };

    if ($self->_is_executable($OVS_VCMD)) {
        $output .= "\n$OVS_VCMD show\n";
        $output .= $self->runrun([$OVS_VCMD, "show"]);
    } else {
        $output .= "Missing $OVS_VCMD executable.\n";
    };

    return $output;
}

# Given ethtool section options hashref, return ordered
# list of keys.
# Option ordering is important for autoneg/speed/duplex
sub order_ethtool_options
{
    my ($self, $section, $options) = @_;

    # Add options from preordered section
    my @keys = grep {exists($options->{$_})} @{$ETHTOOL_OPTION_ORDER{$section}};

    # Add remaining keys alphabetically
    foreach my $key (sort keys %$options) {
        push(@keys, $key) if (!(grep {$_ eq $key} @keys));
    };

    return @keys;
}

# Set ethtool options outside changes to the ifcfg files
sub ethtool_set_iface_options
{
    my ($self, $iface, $sectionname, $options) = @_;

    # get current values into %current
    my %current = $self->ethtool_get_current($iface, $sectionname);

    # Loop over template settings and check that they are known but different
    my @opts;
    foreach my $k (order_ethtool_options($sectionname, $options)) {
        my $v = $options->{$k};
        my $currentv;
        if (exists($current{$k})) {
            $currentv = $current{$k};
        } elsif ($current{$ETHTOOL_OPTION_MAP{$sectionname}{$k}}) {
            $currentv = $current{$ETHTOOL_OPTION_MAP{$sectionname}{$k}};
        } else {
            $self->info("ethtool_set_iface_options: Skipping setting for ",
                        "$iface/$sectionname/$k to $v as not in ethtool");
            next;
        }

        # Is the value different between template and the machine
        if ($currentv eq $v) {
            $self->verbose("ethtool_set_options: value for $iface/$sectionname/$k is already set to $v");
        } else {
            push(@opts, $k, $v);
        }
    }

    # nothing to do?
    return if (! @opts);

    my $setoption;
    if ($sectionname eq "ring") {
        $setoption = "--set-$sectionname";
    } elsif ($sectionname eq "ethtool") {
        $setoption = "--change";
    } else {
        $setoption = "--$sectionname";
    };

    $self->runrun([$ETHTOOLCMD, $setoption, $iface, @opts])
}

# ethtool processing for offload, ring and others of all interfaces
sub ethtool_set_options
{
    my ($self, $ifaces) = @_;
    foreach my $iface (sort keys %$ifaces) {
        foreach my $sectionname (sort keys %ETHTOOL_OPTION_MAP) {
            $self->ethtool_set_iface_options($iface, $sectionname, $ifaces->{$iface}->{$sectionname})
                if ($ifaces->{$iface}->{$sectionname});
        };
    };
}


# Create ifcfg ETHTOOL_OPTS entry as arrayref from hashref $options
sub ethtool_options
{
    my ($self, $options) = @_;

    my @eth_opts;
    foreach my $key (order_ethtool_options('ethtool', $options)) {
        push(@eth_opts, $key, $options->{$key});
    }
    return \@eth_opts;
}

# Run list of arrayref of commands (via CAF::Process) or
# CAF::Service instances with 2nd element the method to run.
# CAF::Service instances are expected to be initialised with logger.
# Failing command has error reported; failing CAF::Service assumes
# to log its own error.
# Returns joined output of all processes.
# If a CAF::Service instance is passed, its output is not added / returned.
sub runrun
{
    my ($self, @cmds) = @_;

    my @output;
    foreach my $cmd (@cmds) {
        if (ref($cmd->[0]) eq 'CAF::Service') {
            my $srv = $cmd->[0];
            my $action = $cmd->[1];
            $srv->$action();
        } else {
            my $proc = CAF::Process->new($cmd, log => $self);
            push(@output, $proc->output());
            if ($?) {
                $self->error("Error '$proc' output: $output[-1]");
            }
        }
    }

    return join("", @output);
}


# Create a mapping of device names to MAC address
# Returns hashref with key found device name and value MAC
# same MAC can be used by several devices
sub make_dev2mac
{
    my ($self) = @_;

    # Collect ifconfig info
    my $out;
    my $proc = CAF::Process->new($IPADDR,
                                 stdout => \$out,
                                 stderr => "stdout",
                                 log => $self,
                                 keeps_state => 1);
    if (! $proc->execute()) {
        $out = "" if (! defined($out));
        $self->error("Running \"$proc\" failed: output $out");
    }

    # each new device starts at begin of line
    #   all its properties have indentation
    # one dev per line afterwards
    $out =~ s/\s*\n[ \t]+/ /g;

    # this does not handle inifiband MACs yet
    my $mac_regexp = qr{^\d+:\s* # start with numbering
                        ([^:\s@]+)(?:@[^:\s]+)?:  # the device; the vlans have vlan@dev format, ignore the @dev
                        \s.*?\s
                        link/ether\s+ # only ether for now
                        ([\da-f]{2}([:-])[\da-f]{2}(\3[\da-f]{2}){4}) # mac address, case insensitive search
                        \s}xi;

    my %dev2mac;
    foreach my $tmp_dev (split(/\n/, $out)) {
        $dev2mac{$1} = lc($2) if ($tmp_dev =~ m/$mac_regexp/);
    }
    return \%dev2mac;
}

# Gather network interface data
# Takes the /system/network data and makes some (minor) modifications to it.
# Returns nwtree with modifications, not a copy.
sub process_network
{
    my ($self, $config) = @_;

    # Use another copy of network tree.
    # It will be modified, so do not pass nwtree from Configure
    my $nwtree = $config->getTree($NETWORK_PATH);
    my $nics = $config->getTree($HARDWARE_PATH);

    my $set_hwaddr_default = $nwtree->{set_hwaddr} ? 1 : 0;
    $self->verbose("Set hwaddr default $set_hwaddr_default");

    # Mapping for interface without hwaddr, value is human readable type
    my $hr_map = {
        bond => 'bonding',
        vlan => 'VLAN',
        vxlan => 'VXLAN tunnel',
        ib => 'IPoIB',
        br => 'bridge',
        ovirtmgmt => 'virt bridge',
    };
    # Pattern to match interface name to hr_map. $1 is the key
    my $hr_pattern = '^('.join('|', sort keys %$hr_map).')';

    # read and modify interface config in hash
    foreach my $ifname (sort keys %{$nwtree->{interfaces}}) {
        my $iface = $nwtree->{interfaces}->{$ifname};

        # handle aliases name: substitute the name for the key
        $iface->{aliases} ||= {};
        foreach my $name (sort keys %{$iface->{aliases}}) {
            my $alias = $iface->{aliases}->{$name};
            my $new_name = delete $alias->{name};
            if (defined($new_name)) {
                $self->debug(1, "Replaced alias $name with alias name $new_name for interface $ifname");
                $iface->{aliases}->{$new_name} = $alias;
                delete $iface->{aliases}->{$name};
            }
        }

        # bonding/bridging options
        foreach my $attr (qw(bonding_opts bridging_opts)) {
            my $opts = $iface->{$attr};
            if (defined($opts) && keys %$opts) {
                $iface->{$attr} = [map {"$_=$opts->{$_}"} sort keys %$opts];
                $self->debug(1, "Replaced $attr with ", join(' ', @{$iface->{$attr}}), " for interface $ifname");
            }
        }

        # add ethtool options preparsed. These will be set in ifcfg- config
        # some are needed on boot (like autoneg/speed/duplex)
        if (exists($iface->{ethtool})) {
            $iface->{ethtool_opts} = $self->ethtool_options($iface->{ethtool});
            $self->debug(1, "Added ethtool_opts with ", join(' ', @{$iface->{ethtool}}), " for interface $ifname");
        }

        # Handle hardware address
        my $nicname = $ifname;

        # TODO: can we get rid of this?
        if (! exists($nics->{nicname}) and $ifname =~ m/^eth(\d+)/) {
            # Try CERN nic as list
            if (exists($nics->{1})) {
                $nicname = $1 ;
                $self->verbose("No nic found for $ifname, using nic-as-list name $nicname");
            };
        };


        # Each iface must have set_hwaddr attribute
        # If set_hwaddr is true, hwaddr must be set
        my $nic = $nics->{$nicname} || {};
        my $mac = $nic->{hwaddr};
        $iface->{set_hwaddr} = $set_hwaddr_default if !exists($iface->{set_hwaddr});

        my $no_hw_msg = "interface $ifname. Setting set_hwaddr to false.";
        if ($mac) {
            # check MAC address. or can we trust type definitions?
            if ($mac =~ m/^[\da-f]{2}([:-])[\da-f]{2}(\1[\da-f]{2}){4}$/i) {
                $iface->{hwaddr} = $mac;
            } else {
                $self->error("Found invalid configured hwaddr $mac for $no_hw_msg",
                             "(Please contact the developers in case you think it is a valid MAC address).");
                $iface->{set_hwaddr} = 0;
            }
        } else {
            $iface->{set_hwaddr} = 0;

            my $msg = "No value found for the hwaddr of $no_hw_msg";
            if ($ifname =~ m/$hr_pattern/) {
                $self->verbose("$msg This is considered normal for a $hr_map->{$1}.");
            } else {
                $self->warn($msg);
            }
        }

        # set vlan flag for the VLAN device
        if ($ifname =~ m/^vlan\d+/ && ! exists($self->{vlan})) {
            $iface->{vlan} = 1;
            $self->verbose("$ifname is a VLAN device");
        }

        # interfaces named vlan need the physdev set
        # and pointing to an existing interface
        if ($self->{vlan} && ! $iface->{physdev}) {
            $self->error("vlan device $ifname (with vlan[0-9]{0-9} naming convention) needs physdev set.");
        }

        # split route/rule in IPv4 and IPv6
        foreach my $type (qw(route rule)) {
            my $mixed = delete $iface->{$type};
            foreach my $entry (@$mixed) {
                # If there's a : in either configured value, it's IPv6
                my $flavour = (grep {$entry->{$_} =~ m/:/} sort keys %$entry) ? "${type}6" : $type;
                push(@{$iface->{$flavour}}, $entry);
            }
        }
    }

    return $nwtree;
}

# Look for existing interface configuration files (and symlinks)
# Return hashref for files and links, with key the absolute filepath
# and value REMOVE status for files and target for symlinks.
sub gather_existing
{
    my ($self) = @_;

    my (%exifiles, %exilinks);

    # read current config
    my $files = $self->listdir($IFCFG_DIR, test => sub { return $self->is_valid_interface($_[0]); });
    foreach my $filename (@$files) {
        if ($filename =~ m/^([:\w.-]+)$/) {
            $filename = $1; # untaint
        } else {
            $self->warn("Cannot untaint filename $IFCFG_DIR/$filename. Skipping");
            next;
        }

        my $file = "$IFCFG_DIR/$filename";

        my $msg;
        if ($self->is_symlink($file)) {
            # keep the links separate
            # TODO: value not used?
            $exilinks{$file} = readlink($file);
            $msg = "link (to target $exilinks{$file})";
        } else {
            # Flag all found files for removal at this stage
            # and make a backup.
            $exifiles{$file} = $REMOVE;
            $msg = "file";
            return (undef, undef) if ! defined($self->mk_bu($file));
        }
        $self->debug(3, "Found ifcfg $msg $file");
    }

    return (\%exifiles, \%exilinks);
}


# ifcfg are bash script that are sourced
# simple form: KEY=$href->{$key} (no newline)
# if value/default is arrayref, it is joined to string
# options:
#    def: default value
#    var: variable name to use instead of key (will be uc'ed)
#    bool: yesno/onoff : value (and default) are booleans, need to be converted to yesno
#    quote: boolean quote the value in singlequotes
#    quoteval: string to use for quoting (still requires quote=>1 for actual quoting)
#    join: if value is arrayref, use separator to join (default is ' ')
# returns empty string is neither value or default exist
sub _make_ifcfg_line
{
    my ($href, $key, %opts) = @_;

    my $var = $opts{var} || $key;
    my $value = defined($href->{$key}) ? $href->{$key} : $opts{def};
    my $quoteval = $opts{quoteval} ? $opts{quoteval} : "'";
    my $quote = $opts{quote} ? $quoteval : '';
    my $sep = defined($opts{join}) ? $opts{join} : ' ';

    if (defined($value)) {
        if ($opts{bool}) {
            $value = $value ? 'yes' : 'no' if ($opts{bool} eq 'yesno');
            $value = $value ? 'on' : 'off' if ($opts{bool} eq 'onoff');
        } elsif (ref($value) eq 'ARRAY') {
            $value = join($sep, @$value);
        }
        return uc($var)."=$quote$value$quote";
    } else{
        return ''; # return string
    };

}

# return anonymous sub that calls
# _make_ifcfg_line with first arg $href
# and appends result it not empty string to arrayref
# and returns value
sub _make_make_ifcfg_line
{
    my ($href, $aref) = @_;
    return sub {
        my $res = _make_ifcfg_line($href, @_);
        if (defined($aref) and $res ne '') {
            push(@$aref, $res);
        };
        return $res;
    };
}

# Return ifcfg content
sub make_ifcfg
{
    my ($self, $ifacename, $iface) = @_;

    my @text;
    my $makeline = _make_make_ifcfg_line($iface, \@text);

    &$makeline('onboot', bool => 'yesno', def => 1);

    &$makeline('nmcontrolled', var => 'nm_controlled', bool => 'yesno', def => 0, quote => 1);

    &$makeline('device', def => $ifacename);

    &$makeline('type', def => 'Ethernet');

    if ( ($iface->{type} || '') =~ m/^OVS/) {
        # Set OVS related variables
        push(@text, "DEVICETYPE='ovs'");

        foreach my $attr (qw(ovs_bridge ovs_opts ovs_extra bond_ifaces
                          ovs_tunnel_type ovs_tunnel_opts ovs_patch_peer)) {
            my $var = $attr;
            $var =~ s/_opts$/_options/;
            # legacy: ovs_extra has double quoted string for variable interpolation
            #         but it was not a good idea, because the order of the variables is pretty random
            my $quoteval = $attr eq 'ovs_extra' ? '"' : undef;
            &$makeline($attr, var => $var, quote => 1, quoteval => $quoteval);
        }
    }

    &$makeline('bridge', quote => 1);
    if ($iface->{bridge} && (! $self->_is_executable($BRIDGECMD))) {
        $self->error ("Error: bridge specified but $BRIDGECMD not found");
    }

    # set the HWADDR
    &$makeline('hwaddr') if $iface->{set_hwaddr};

    &$makeline('mtu');

    # set the bootprotocol
    &$makeline('bootproto', def => 'static');

    my $bootproto = $iface->{bootproto} || 'static';
    if ($bootproto eq 'static') {
        foreach my $attr (qw(ip netmask broadcast)) {
            if ($iface->{$attr}) {
                &$makeline($attr, var => ($attr eq 'ip') ? 'ipaddr' : undef);
            } else {
                $self->error("Using static bootproto for $ifacename and no $attr configured");
            }
        }
    } elsif (($bootproto eq "none") && $iface->{master}) {
        # set bonding master
        &$makeline('master');
        push(@text, "SLAVE=yes");
    }

    &$makeline('defroute', bool => 'yesno');

    # IPv6 additions
    my $use_ipv6;

    if ($iface->{ipv6addr}) {
        &$makeline('ipv6addr');
        $use_ipv6 = 1;
    }
    if ($iface->{ipv6addr_secondaries}) {
        &$makeline('ipv6addr_secondaries', quote => 1);
        $use_ipv6 = 1;
    }

    if (defined($iface->{ipv6_autoconf})) {
        &$makeline('ipv6_autoconf', bool => 'yesno');
        if($iface->{ipv6_autoconf}) {
            $use_ipv6 = 1;
        } else {
            $self->warn("Disabled IPv6 autoconf but no ipv6 address configured for $ifacename.")
                if (!$iface->{ipv6addr});
        }
    }

    if (defined($iface->{ipv6_rtr}) ) {
        &$makeline('ipv6_rtr', bool => 'yesno');
        $use_ipv6 = 1;
    }

    if (defined($iface->{ipv6_mtu})) {
        &$makeline('ipv6_mtu');
        $use_ipv6 = 1;
    }

    if ($iface->{ipv6_privacy}) {
        &$makeline('ipv6_privacy');
        $use_ipv6 = 1;
    }

    &$makeline('ipv6_defroute', bool => 'yesno', def => $iface->{defroute});

    if (defined($iface->{ipv6_failure_fatal}) ) {
        &$makeline('ipv6_failure_fatal', bool => 'yesno');
        $use_ipv6 = 1;
    }
    if (defined($iface->{ipv4_failure_fatal}) ) {
        &$makeline('ipv4_failure_fatal', bool => 'yesno');
    }

    # when both are undef, nothing is added
    &$makeline('ipv6init', def => $use_ipv6, bool => 'yesno');

    &$makeline('linkdelay');

    # set some bridge-releated parameters
    # bridge STP
    &$makeline('stp', bool => 'onoff');
    # bridge DELAY
    &$makeline('delay');

    # add generated options strings
    foreach my $attr (qw(bonding_opts bridging_opts ethtool_opts)) {
        &$makeline($attr, quote => 1);
    };

    # VLAN support
    &$makeline('vlan', bool => 'yesno');

    push(@text, "ISALIAS=no") if ($iface->{vlan});

    &$makeline('physdev');

    my $vxlan = $iface->{plugin}->{vxlan};
    if ($vxlan) {
        if (!defined($vxlan->{vni})) {
            my $device = $iface->{device} || $ifacename;
            if ($device =~ /^vxlan(\d+)/) {
                $vxlan->{vni} = $1;
            } else {
                $self->error("No VNI for vxlan plugin from devicename $device for $ifacename");
            }
        };

        push(@text, "VXLAN=yes");

        my $vxlanml = _make_make_ifcfg_line($vxlan, \@text);
        &$vxlanml('vni');

        &$vxlanml('group', var => 'group_ipaddr');
        # set remote and local ip addr twice
        &$vxlanml('remote', var => 'remote_ipaddr');
        &$vxlanml('remote', var => 'peer_outer_ipaddr');

        &$vxlanml('local', var => 'local_ipaddr');
        &$vxlanml('local', var => 'my_outer_ipaddr');

        &$vxlanml('dstport');
        &$vxlanml('gbp', bool => 'yesno');
    };

    return \@text;
}

# Return legacy ifcfg IPv4 route content
sub make_ifcfg_route4_legacy
{
    my ($self, $routes) = @_;

    my @text;
    foreach my $idx (0 .. scalar(@$routes) -1) {
        my $makeline = _make_make_ifcfg_line($routes->[$idx], \@text);
        foreach my $attr (qw(address gateway netmask)) {
            &$makeline($attr, var => "$attr$idx", def => ($attr eq 'netmask') ? '255.255.255.255' : undef);
        }
    }

    return \@text;
}

# Return ifcfg route content in ip format
# device must be device, not name of interface on system
sub make_ifcfg_ip_route
{
    my ($self, $flavour, $device, $routes) = @_;

    my @text;
    foreach my $route (@$routes) {
        if (!$route->{command}) {
            my $ip;
            if ($route->{prefix}) {
                $ip = NetAddr::IP->new("$route->{address}/$route->{prefix}");
            } else {
                # in absence of netmask, NetAddr::IP uses 32 or 128
                $ip = NetAddr::IP->new($route->{address}, $route->{netmask});
            }
            # Generate it
            $route->{command} = "$ip";
            $route->{command} .= " via $route->{gateway}" if $route->{gateway};
            $route->{command} .= " dev $device";
        }
        push(@text, $route->{command});
    }

    return \@text;
}

# Return ifcfg rule content in ip format
# Very simple atm, only command supported.
# device must be device, not name of interface on system
sub make_ifcfg_ip_rule
{
    my ($self, $flavour, $device, $rules) = @_;

    my @text;
    foreach my $rule (@$rules) {
        $self->error("Rule flavour $flavour device $device without command; skipping") if (!$rule->{command});
        push(@text, $rule->{command});
    }

    return \@text;
}


# Return ifcfg alias content
sub make_ifcfg_alias
{
    my ($self, $device, $alias) = @_;

    my @text = ("DEVICE=$device");

    my $makeline = _make_make_ifcfg_line($alias, \@text);
    foreach my $attr (qw(ip broadcast netmask)) {
        &$makeline($attr, var => ($attr eq 'ip') ? 'ipaddr' : undef);
    }

    return \@text;
}

# Return /etc/sysconfig/network content
sub make_network_cfg
{
    my ($self, $nwtree, $net, $hostname) = @_;

    # assuming that NETWORKING=yes
    my @text = ("NETWORKING=yes");

    # set hostname
    push(@text, "HOSTNAME=$hostname") if defined($hostname);

    # default gateway. why is this optional?
    #
    # what happens if no default_gateway is defined?
    # search for first defined gateway and use it.
    # here's the flag: default true
    my $guess_dgw = defined($nwtree->{guess_default_gateway}) ? $nwtree->{guess_default_gateway} : 1;

    my $nodgw_msg = "No default gateway configured";
    my $dgw = $nwtree->{default_gateway};
    if (! defined($dgw) && $guess_dgw) {
        # this is the gateway that will be used in case the default_gateway is not set
        my $first_gateway;
        foreach my $iface (sort keys %{$net->{interfaces}}) {
            if ($net->{interfaces}->{$iface}->{gateway}) {
                $dgw = $net->{interfaces}->{$iface}->{gateway};
                $self->info("$nodgw_msg. Found first gateway $dgw on interface $iface");
                last;
            }
        };
        # Set add the end, no conditional needed
        $nodgw_msg .= " and no interface found with a gateway configured.";
    }

    if ($dgw) {
        push(@text, "GATEWAY=$dgw");
    } else {
        $self->warn($nodgw_msg);
    }

    my $makeline = _make_make_ifcfg_line($nwtree, \@text);

    &$makeline('nisdomain');

    &$makeline('nozeroconf', bool => 'yesno');

    &$makeline('gatewaydev');

    &$makeline('nmcontrolled', var => 'nm_controlled', nbool => 'yesno');

    # Enable and config IPv6 if either set explicitly or v6 config is present
    # but note that the order of the v6 directive processing is important to
    # make the 'default' enable do the right thing
    my $ipv6 = $nwtree->{ipv6};
    if ($ipv6) {
        # No ipv6 makeline (yet), all different variable names etc
        my $use_ipv6 = 0;

        if ($ipv6->{default_gateway}) {
            push(@text, "IPV6_DEFAULTGW=$ipv6->{default_gateway}");
            $use_ipv6 = 1; # enable ipv6 for now
        }
        if ($ipv6->{gatewaydev}) {
            push(@text, "IPV6_DEFAULTDEV=$ipv6->{gatewaydev}");
            $use_ipv6 = 1; # enable ipv6 for now
        }

        if (defined($ipv6->{enabled})) {
            $use_ipv6 = $ipv6->{enabled};
        }
        push(@text, "NETWORKING_IPV6=".($use_ipv6 ? "yes" : "no"));
    }

    return \@text;
}

# Build and return ifdown hashref: key is the interface name,
# value boolean to stop interface (but is ignored in rest of code).
# Returns undef in case of severe issue
# No actual ifdown is executed (see usage of `will` in messages).
sub make_ifdown
{
    my ($self, $exifiles, $ifaces) = @_;

    my $dev2mac = $self->make_dev2mac();

    my %ifdown;
    foreach my $file (sort keys %$exifiles) {
        next if ($file eq $NETWORKCFG);

        my $iface = $self->is_valid_interface($file);
        if ($iface) {
            # ifdown: all devices that have files with non-zero status
            if ($exifiles->{$file} == $NOCHANGES) {
                $self->verbose("No changes for interface $iface (cfg file $file)");
            } elsif ($exifiles->{$file} == $KEEPS_STATE) {
                $self->verbose("Change for interface $iface keeps state (cfg file $file)");
            } else {
                $self->verbose("Will ifdown $iface due to changes in $file (state $exifiles->{$file})");
                # TODO: ifdown new devices? better safe than sorry?
                $ifdown{$iface} = 1;

                # bonding: if you bring down a slave, always bring down it's master
                if ($ifaces->{$iface}->{master}) {
                    my $master = $ifaces->{$iface}->{master};
                    $self->verbose("Changes to slave $iface will force ifdown of master $master.");
                    $ifdown{$master} = 1;

                    # to use HWADDR, stop the interface with this macaddress (if any)
                    my $mac = lc($ifaces->{$iface}->{hwaddr} || 'not a mac');
                    foreach my $dev (sort keys %$dev2mac) {
                        if ($dev2mac->{$dev} eq $mac) {
                            $self->verbose("Will force ifdown of $dev; old configured/active interface $dev ",
                                           "has same MAC as interface $iface which is now a master.");
                            $ifdown{$dev} = 1;
                        }
                    }
                } elsif (($ifaces->{$iface}->{type} || 'Ethernet') =~ m/(ovs)?bridge/i) {
                    # If this is a bridge (or OVSBridge), also stop the attached devices
                    # Those will be readded on device start (starting the bridge does not attach those)
                    foreach my $attached (sort keys %$ifaces) {
                        my $bridge = $ifaces->{$attached}->{bridge} || $ifaces->{$attached}->{ovs_bridge} || '';
                        if ($bridge eq $iface) {
                            $self->verbose("Changes to bridge $iface force ifdown of attached device $attached");
                            $ifdown{$attached} = 1;
                        }
                    }
                } elsif ($file eq "$IFCFG_DIR/ifcfg-$iface" && $self->any_exists($file)) {
                    # here's the tricky part: see if it used to be a slave.
                    # the bond-master must be restarted if a device was removed from the bond.
                    # TODO: why read from backup?
                    $self->debug(3, "reading ifcfg from the backup ", $self->backup_filename($file));
                    my $fh = CAF::FileReader->new($self->backup_filename($file), log => $self);
                    my ($slave, $master);
                    $slave = $1 if ($fh =~ m/^SLAVE\s*=\s*(\w+)\s*$/m);
                    $master = $1 if ($fh =~ m/^MASTER\s*=\s*(\w+)\s*$/m);
                    $fh->close();

                    # SLAVE=yes is the logic used in ifup
                    if ($slave && $slave eq "yes" &&
                        $master && $master =~ m/^bond/) {
                        $ifdown{$master} = 1;
                        $self->verbose("Changes to previous slave $iface will force ifdown of master $master.");
                    }
                }
            }
        } else {
            $self->error("Filename $file found that doesn't match the device ",
                         "regexp. Must be an error in ncm-network.");
            return;
        }
    }

    return \%ifdown;
}

# Build and return ifup hashref: key is the interface name,
# value boolean to start interface (but is ignored in rest of code).
# No actual ifup is executed (see usage of `will` in messages).
sub make_ifup
{
    my ($self, $exifiles, $ifaces, $ifdown) = @_;

    my %ifup;
    foreach my $iface (sort keys %$ifdown) {
        # ifup: all devices that are in ifdown
        # and have state other than REMOVE
        # e.g. master with NOCHANGES state can be added here
        # when a slave had modifications
        if ($exifiles->{"$IFCFG_DIR/ifcfg-$iface"} == $REMOVE) {
            $self->verbose("Not starting $iface scheduled for removal");
        } else {
            if ($ifaces->{$iface}->{master}) {
                # bonding devices: don't bring the slaves up, only the master
                $self->verbose("Found SLAVE interface $iface in ifdown map, ",
                               "not starting it with ifup; is left for master $ifaces->{$iface}->{master}.");
            } else {
                $self->verbose("Will start $iface with ifup");
                $ifup{$iface} = 1;
            }
        }
    }

    return \%ifup;
}

# If allow is defined and false, disable and stop NetworkManager
sub disable_networkmanager
{
    my ($self, $allow) = @_;

    # allow NetworkMnager to run or not?
    if (defined($allow) && !$allow) {
        # no checking, forcefully stopping NetworkManager
        # warning: this can cause troubles with the recovery to previous state in case of failure
        # it's always better to disable the NetworkManager service with ncm-chkconfig and have it run pre ncm-network
        my @disablenm_cmds;

        # TODO: do something smart with 'require NCM::Component::Systemd::...' to turn it off
        push(@disablenm_cmds, [qw(/sbin/chkconfig --level 2345 NetworkManager off)]);

        push(@disablenm_cmds, [CAF::Service->new(["NetworkManager"], log => $self), "stop"]);

        $self->runrun(@disablenm_cmds);
    };
};

# If any of the interfaces to start has on OVS type
# (try to) start openvswitch service.
sub start_openvswitch
{
    my ($self, $ifaces, $ifup) = @_;

    my $start;
    foreach my $intf (sort keys %$ifup) {
        if (($ifaces->{$intf}->{type} || '') =~ m/^OVS/) {
            $start = 1;
        }
    }

    if ($start) {
        # use runrun. failure to start is an actual issue
        $self->runrun([CAF::Service->new(["openvswitch"], log => $self), "start"]);
    }
}

# set the hostname
# hostname is set in the main network config
# but could also be configured in other ways
sub set_hostname
{
    my ($self, $hostname) = @_;

    if ($self->_is_executable($HOSTNAME_CMD)) {
        $self->runrun([$HOSTNAME_CMD, 'set-hostname', $hostname, "--static"]);
    };
}


# network stop OR ifdown
# Returns if something was done or not
sub stop
{
    my ($self, $exifiles, $ifdown, $nwsrv) = @_;

    my @ifaces = sort keys %$ifdown;

    my $action;
    if ($exifiles->{$NETWORKCFG} == $UPDATED) {
        $self->verbose("$NETWORKCFG UPDATED, stopping network");
        $action = 1;
        $nwsrv->stop();
    } elsif (@ifaces) {
        my @cmds;
        foreach my $iface (@ifaces) {
            # how do we actually know that the device was up?
            # eg for non-existing device eth4: /sbin/ifdown eth4 --> usage: ifdown <device name>
            push(@cmds, ["/sbin/ifdown", $iface]);
        }
        $self->verbose("Stopping interfaces ",join(', ', @ifaces));
        $action = 1;
        $self->runrun(@cmds);
    } else {
        $self->verbose('Nothing to stop');
        $action = 0;
    }

    return $action;
}

# Copy test configurations to correct location
# Remove configuration files that is scheduled for removal
# Returns if something was done or not
sub deploy_config
{
    my ($self, $exifiles) = @_;

    # replace UPDATED/NEW files, remove REMOVE files
    my $action = 0;
    foreach my $file (sort keys %$exifiles) {
        my $state = $exifiles->{$file};
        # only these states get new/updated config
        my $write = ($state == $UPDATED) || ($state == $NEW) || ($state == $KEEPS_STATE);
        if (($state == $REMOVE) || $write) {
            my $msg = "REMOVE config $file";
            if($self->cleanup($file)) {
                $self->verbose($msg);
            } else {
                $self->error("$msg failed. ($self->{fail})");
            };
            $action = 1 if ($state != $KEEPS_STATE);

            # set new config file from testcfg
            if ($write) {
                my $testcfg = $self->testcfg_filename($file);
                # KEEPS_STATE is considered UPDATED here
                my $msg = "hardlink ". ($state == $NEW ? 'NEW' : 'UPDATED')." testcfg $testcfg to config $file";
                if ($self->hardlink($testcfg, $file)) {
                    $self->verbose($msg);
                } else {
                    $self->error("$msg failed: $self->{fail}");
                }
            }
        } else {
            $self->verbose("Nothing to do for config $file with status $exifiles->{$file}.");
        }
    }

    return $action;
}

# network start or ifup
# Returns if something was done or not
sub start
{
    my ($self, $exifiles, $ifup, $nwsrv) = @_;

    my @ifaces = sort keys %$ifup;
    my $nwstate = $exifiles->{$NETWORKCFG};

    my $action;
    if (($nwstate == $UPDATED) || ($nwstate == $NEW)) {
        $self->verbose("$NETWORKCFG ", ($nwstate == $NEW ? 'NEW' : 'UPDATED'), " starting network");
        $action = 1;
        $nwsrv->start();
    } elsif (@ifaces) {
        my @cmds;
        foreach my $iface (@ifaces) {
            push(@cmds, ["/sbin/ifup", $iface, "boot"]);
            push(@cmds, [qw(sleep 10)]) if ($iface =~ m/bond/);
        }
        $self->verbose("Starting interfaces ",join(', ', @ifaces));
        $action = 1;
        $self->runrun(@cmds);
    } else {
        $self->verbose('Nothing to start');
        $action = 0;
    }

    return $action;
}

# Recover failed network changes
sub recover
{
    my ($self, $exifiles, $nwsrv, $init_config, $profile) = @_;

    $self->error("Network restart failed. Reverting back to original config. ",
                 "Failed modified configfiles can be found in ",
                 "$BACKUP_DIR with suffix $FAILED_SUFFIX. ",
                 "(If there aren't any, it means only some devices were removed.)");

    # stop/recover/start whole network is the only thing that should always work.
    # Not trying to minimise the impact

    # current config. useful for debugging
    my $failure_config = $self->get_current_config();

    $self->verbose("RECOVER: stop network");
    $nwsrv->stop();

    my $unlink = sub {
        my $file = shift;
        if ($self->any_exists($file)) {
            if($self->cleanup($file)) {
                $self->debug(1, "RECOVER: unlinked failed orig $file") ;
            } else {
                $self->error("RECOVER: Can't unlink failed orig $file ($self->{fail})") ;
            };
        }
    };

    my $recover = sub {
        my $file = shift;
        my $backup = $self->backup_filename($file);
        &$unlink($file);
        if($self->hardlink($backup, $file)) {
            $self->debug(1, "RECOVER: hardlink backup $backup to orig $file");
        } else {
            $self->error("RECOVER: Can't hardlink backup $backup to orig $file ($self->{fail})");
        };
    };


    # revert to original files
    foreach my $file (sort keys %$exifiles) {
        if ($exifiles->{$file} == $NEW) {
            $self->info("RECOVER: Removing new file $file.");
            &$unlink($file);
        } elsif ($exifiles->{$file} == $UPDATED) {
            $self->info("RECOVER: Replacing newer file $file.");
            &$recover($file);
        } elsif ($exifiles->{$file} == $REMOVE) {
            $self->info("RECOVER: Restoring file $file.");
            &$recover($file);
        }
    }

    # network start
    $self->verbose("RECOVER: start network");
    $nwsrv->start();

    # test it again
    my $nw_test = $self->test_network_ccm_fetch($profile);
    if ($nw_test) {
        $self->info("Old network config restored.");
    } else {
        $self->error("Restoring old config failed.");
    }

    $self->info("Initial setup\n$init_config");
    $self->info("Setup after failure\n$failure_config");
    $self->info("Current setup\n".$self->get_current_config());

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


# Create new backupdir
# Returns 1 on success, undef on failure (and reports error).
sub init_backupdir
{
    my $self = shift;

    if (!defined($self->cleanup($BACKUP_DIR, undef, keeps_state => 1))) {
        $self->error("Failed to cleanup previous backup directory $BACKUP_DIR: $self->{fail}");
        return;
    }
    if (!defined($self->directory($BACKUP_DIR, mode => oct(700), keeps_state => 1))) {
        $self->error("Failed to create backup directory $BACKUP_DIR: $self->{fail}");
        return;
    }

    return 1;
}

# Given filename and legacy text reference, check if present content matches
# the genertaed legacy text. If so, set the state of the file to KEEPS_STATE
sub legacy_keeps_state
{
    my ($self, $filename, $legacy_text_ref, $exifiles) = @_;
    my $fh = CAF::FileReader->new($filename, log => $self);
    if (join("\n", @$legacy_text_ref, '') eq "$fh") {
        $self->verbose("File $filename will get new content, but due to difference from legacy format. KEEPS_STATE $KEEPS_STATE set");
        $exifiles->{$filename} = $KEEPS_STATE;
    };
}


sub Configure
{
    my ($self, $config) = @_;

    return if ! defined($self->init_backupdir());

    # current setup, will be printed in case of major failure
    my $init_config = $self->get_current_config();

    my $net = $self->process_network($config);
    my $ifaces = $net->{interfaces};

    # keep a hash of all files and links.
    # makes a backup of all files
    my ($exifiles, $exilinks) = $self->gather_existing();
    return if ! defined($exifiles);

    my $nwtree = $config->getTree($NETWORK_PATH);

    # main network config
    return if ! defined($self->mk_bu($NETWORKCFG));

    my $hostname = $nwtree->{realhostname} || "$nwtree->{hostname}.$nwtree->{domainname}";

    my $use_hostnamectl = $self->_is_executable($HOSTNAME_CMD);
    # if hostnamectl exists, do not set it via the network config file
    # systemd rpm --script can remove it anyway
    my $nwcfg_hostname = $use_hostnamectl ? undef : $hostname;

    my $text = $self->make_network_cfg($nwtree, $net, $nwcfg_hostname);
    $exifiles->{$NETWORKCFG} = $self->file_dump($NETWORKCFG, $text);

    if ($exifiles->{$NETWORKCFG} == $UPDATED && $use_hostnamectl) {
        # Network config was updated, check if it was due to removal of HOSTNAME
        # when hostnamectl is present.
        $self->legacy_keeps_state($NETWORKCFG, $self->make_network_cfg($nwtree, $net, $hostname), $exifiles);
    };

    # ifcfg- / route[6]- files
    foreach my $ifacename (sort keys %$ifaces) {
        my $iface = $ifaces->{$ifacename};
        my $text = $self->make_ifcfg($ifacename, $iface);

        my $file_name = "$IFCFG_DIR/ifcfg-$ifacename";
        $exifiles->{$file_name} = $self->file_dump($file_name, $text);

        # route/rule config, interface based.
        foreach my $flavour (qw(route route6 rule rule6)) {
            if (defined($iface->{$flavour})) {
                my $method = "make_ifcfg_ip_$flavour";
                $method =~ s/6$//;
                # pass device, not system interface name
                my $text = $self->$method($flavour, $iface->{device} || $ifacename, $iface->{$flavour});

                my $file_name = "$IFCFG_DIR/$flavour-$ifacename";
                $exifiles->{$file_name} = $self->file_dump($file_name, $text);
            }
        }

        # legacy IPv4 format
        $file_name = "$IFCFG_DIR/route-$ifacename";
        if (exists($exifiles->{$file_name}) && $exifiles->{$file_name} == $UPDATED) {
            # IPv4 route data was modified.
            # Check if it was due to conversion of legacy format or
            #   if there were actual changes in the config (or both)
            $self->legacy_keeps_state($file_name, $self->make_ifcfg_route4_legacy($iface->{route}), $exifiles);
        }


        # set up aliases for interfaces
        # one file per alias
        foreach my $al (sort keys %{$iface->{aliases} || {}}) {
            my $al_dev = ($iface->{device} || $ifacename) . ":$al";
            my $text = $self->make_ifcfg_alias($al_dev, $iface->{aliases}->{$al});

            my $file_name = "$IFCFG_DIR/ifcfg-$ifacename:$al";
            $exifiles->{$file_name} = $self->file_dump($file_name, $text);

            # This is the only way it will work for VLANs
            # If vlan device is vlanX and the DEVICE is eg ethY.Z
            # you need a symlink to ifcfg-ethY.Z:alias <- ifcfg-vlanX:alias
            # Otherwise ifup 'ifcfg-vlanX:alias' will work, but restart of network will look for
            # ifcfg-ethY.Z:alias associated with vlan0 (and DEVICE field)
            # Problem is, we want both
            # Adding symlinks however is not the best thing to do.

            my $file_name_sym = "$IFCFG_DIR/ifcfg-$al_dev";
            if ($iface->{vlan} &&
                $file_name_sym ne $file_name &&
                ! $self->any_exists($file_name_sym)) { # TODO: should check target with readlink
                # this will create broken link, if $file_name is not yet existing
                $self->symlink($file_name, $file_name_sym) ||
                    $self->error("Failed to create symlink from $file_name to $file_name_sym ($!)");
            };
        }
    }


    # We now have a map with files and values.
    # Changes to the general network config file are handled separately.
    # For devices: we will create a list of affected devices

    # Since there's per interface reload, interface changes will be applied via ifdown/ifup.
    # This is very coarse, but reimplementing the ifup/ifdown logic is highly non-trivial.
    # ifdown: all interfaces that will be stopped
    # ifup: all interfaces that will be (re)started

    # For now, the order of vlans is not changed and
    # left completely up to the network scripts.
    # There's 0 (zero) intention to support things like vlans on bonding slaves,
    # aliases on bonded vlans ...
    # If you need this, buy more network adapters ;)

    my $ifdown = $self->make_ifdown($exifiles, $ifaces);
    if (! defined($ifdown)) {
        # file_dump does not modify the original files.
        # It's safe to exit the component here.
        # Error reported in make_ifdown
        return;
    }

    my $ifup = $self->make_ifup($exifiles, $ifaces, $ifdown);

    #
    # Action starts here
    #

    $self->disable_networkmanager($nwtree->{allow_nm});

    $self->start_openvswitch($ifaces, $ifup);

    $self->set_hostname($hostname);

    # TODO: why do that here? should be done after any restarting of devices or whole network?
    $self->ethtool_set_options($ifaces);

    # restart network
    # capturing system output/exit-status here is not useful.
    # network status is tested separately
    # flow:
    #   1. stop everythig using old config
    #   2. replace updated/new config; remove REMOVE
    #   3. (re)start things
    my $nwsrv = CAF::Service->new(['network'], log => $self);

    my $stopstart = $self->stop($exifiles, $ifdown, $nwsrv);

    my $config_changed = $self->deploy_config($exifiles);

    $stopstart += $self->start($exifiles, $ifup, $nwsrv);

    # sanity check
    if ($config_changed) {
        if ($stopstart) {
            $self->debug(1, "Configuration changed and something was stopped and/or started");
        } else {
            $self->error("Configuration changed and nothing was stopped and/or started");
            # force a test
            $stopstart = 1;
        }
    } else {
        if ($stopstart) {
            $self->error("Configuration not changed and something was stopped and/or started");
        } else {
            $self->debug(1, "Configuration not changed and nothing was stopped and/or started");
        }
    };

    # test network
    my $ccm_tree = $config->getTree("/software/components/ccm");
    my $profile = $ccm_tree && $ccm_tree->{profile};

    my $cleanup;
    if (! $stopstart) {
        $self->verbose("Nothing was stopped and/or started, no need to retest network");
        $cleanup = 1; # eg from KEEPS_STATE
    } elsif ($self->test_network_ccm_fetch($profile)) {
        $self->verbose("Network ok after test");
        $cleanup = 1;
    } else {
        $self->recover($exifiles, $nwsrv, $init_config, $profile);
        $cleanup = 0; # for debugging afterwards
    }

    if ($cleanup) {
        # it's ok, clean up backups
        my @files = sort keys %$exifiles;
        $self->verbose("Cleaning up leftover backup and test config files for ",
                       join(', ', @files));
        foreach my $file (@files) {
            $self->cleanup_backup_test($file);
        }
    }

    # remove all broken links: use file_exists
    # TODO: why is there no try/recover for the symlinks?
    foreach my $link (sort keys %$exilinks) {
        if (! $self->file_exists($link)) {
            if ($self->cleanup($link)) {
                $self->debug(1, "Succesfully cleaned up broken symlink $link");
            } else {
                $self->error("Failed to unlink broken symlink $link: $self->{fail}");
            };
        }
    };

    return 1;
}


1;
