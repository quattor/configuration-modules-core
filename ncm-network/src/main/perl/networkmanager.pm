#${PMpre} NCM::Component::networkmanager${PMpost}

=head1 NAME

network: Configure Network Settings using NetworkManager Keyfile format. Most functions and logic is taken from network module. 

=head1 DESCRIPTION

The I<network> component sets the network settings through C<< /etc/sysconfig/network >>
and the keyfile format files in C<< /etc/NetworkManager/system-connections >>.

New/changed settings are first tested by retrieving the latest profile from the
CDB server (using ccm-fetch).
If this fails, the component reverts all settings to the previous values.

During this test, a sleep value of 15 seconds is used to make sure the restarted network
is fully restarted (routing may need some time to come up completely).

Because of this, configuration changes may cause the ncm-ncd run to take longer than usual.

Be aware that configuration changes can also lead to a brief network interruption.
=cut

use parent qw (NCM::Component::network);

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use Readonly;

Readonly my $HOSTNAME_CMD => '/usr/bin/hostnamectl';

Readonly my $NETWORK_PATH => '/system/network';
Readonly my $HARDWARE_PATH => '/hardware/cards/nic';
Readonly my $NMCFG_DIR => "/etc/NetworkManager/system-connections";
Readonly my $BACKUP_DIR => "$NMCFG_DIR/.quattorbackup";
Readonly my $NETWORKCFG => "/etc/sysconfig/network";

Readonly my $RESOLV_CONF => '/etc/resolv.conf';
Readonly my $RESOLV_CONF_SAVE => '/etc/resolv.conf.save';
Readonly my $RESOLV_SUFFIX => '.ncm-network';

# need this to remain same value as what is in network.pm
Readonly my $REMOVE => -1;
Readonly my $NOCHANGES => 0;
Readonly my $UPDATED => 1;
Readonly my $NEW => 2;
# changes to file, but same config (eg for new file formats)
Readonly my $KEEPS_STATE => 3;


# NOTE: Had to pull in some fucntions from network.pm in order to satisfy location of new paths.
# this to avoid to trying modify too much in network.pm.

# backup_filename: returns backup filename for given file
sub backup_filename
{
    my ($self, $file) = @_;

    my $back = "$file";
    $back =~ s/\//_/g;

    return "$BACKUP_DIR/$back";
}

# Look for existing interface configuration files (and symlinks)
# Return hashref for files and links, with key the absolute filepath
# and value REMOVE status for files and target for symlinks.
sub gather_existing
{
    my ($self) = @_;

    my (%exifiles, %exilinks);

    # read current config
    my $files = $self->listdir($NMCFG_DIR, test => sub { return $self->is_valid_interface($_[0]); });
    foreach my $filename (@$files) {
        if ($filename =~ m/^([:\w.-]+)$/) {
            $filename = $1; # untaint
        } else {
            $self->warn("Cannot untaint filename $NMCFG_DIR/$filename. Skipping");
            next;
        }

        my $file = "$NMCFG_DIR/$filename";

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

# Given the configuration in nmconnection
# Determine if this is a valid interface for ncm-network to manage,
# Return arrayref tuple [interface name, ifdown/ifup name] when valid,
# undef otherwise.
sub is_valid_interface
{
    my ($self, $filename) = @_;

    # Very primitive, based on regex only
    # Not even the full filename (eg ifcfg) or anything
    if ($filename =~ /(\w+\d+)\.(nmconnection)/) {
        # name and id in keyfile format, so connection id and name will always be same.
        my $name = $1;
        # don't suffix is something we will need care about in nmconnection files.
        my $suffix = $2;
        return [$name, $name];
    } else {
        return;
    };
}

# By default, NetworkManager on Red Hat Enterprise Linux (RHEL) 8+ dynamically updates the /etc/resolv.conf
# file with the DNS settings from active NetworkManager connection profiles. we manage this using nmc-resolver. 
# so disable this unless nm_manage_dns = true
sub disable_nm_manage_dns
{
    my ($self, $manage_dns, $nwsrv) = @_;
    my $filename = "/etc/NetworkManager/conf.d/90-quattor-dns-none.conf";
    my @data = ('[main]');
    push @data, 'dns=none';
    if ( (defined($manage_dns) && !$manage_dns) || (! defined($manage_dns)) ) {
        $self->verbose("Configuring networkmanager not to manage resolv.conf");
        my $fh = CAF::FileWriter->new($filename, mode =>0444, log => $self, keeps_state => 1);
        print $fh join("\n", @data, '');
        if ($fh->close())
        {
            $self->info("File $filename changed, reload network");
            $nwsrv->reload();
        };
    } else {
        # cleanup the config if was created previously
        if (-e $filename)
        {
            my $msg = "REMOVE config $filename, NOTE: networkmanager will manage resolv.conf";
            if(unlink($filename)) {
                $self->info($msg);
                $self->verbose("Reload NetworkManager");
                $nwsrv->reload();
            } else {
                $self->error("$msg failed. ($self->{fail})");
            };
        };
    }

}

# generate networkmanager keyfile format config for device
# Return keyfile format content
# NOTE: currenly only single interface config and bonding is supportted. more to follow
# 
sub make_nm_keyfile { # arg1 = 'eth0'

    my ($self, $device, $net, $ipv6) = @_;

    # grab the devices config info
    my $iface = $net->{interfaces}->{$device};

    # generate some conditional flags
    my $is_eth = exists $iface->{media} ? 1 : 0;
    my $is_bond_eth = exists $iface->{master} ? 1 : 0;
    my $is_ip = exists $iface->{ip} ? 1 : 0;

    my $eth_bootproto = $iface->{bootproto};
    my $onboot = $iface->{onboot};

    # ------------------------------------------------------------------
    # generate data structure supporting bond and ethernet device types
    # ------------------------------------------------------------------

    # shared config
    my @data = ('[connection]');
    push @data, 'id=' . $device;
    push @data, 'interface-name=' . $device;
    if ((defined($onboot)) && ($onboot eq 'no'))
    {
        push @data, 'autoconnect=false';
    }
    # switch on ethernet / bond device type
    if ($is_eth) {
        # if eth device
        push @data, 'type=ethernet';
        if ($is_bond_eth) {
            # if bonded ethernet device
            push @data, 'master=' . $iface->{master};
            push @data, 'slave-type=bond';
        }
    } else {
        # if bond device
        push @data, 'type=bond';
        push @data, '[bond]';
        # if bonding options are in config
        my $bond_config = $iface->{'bonding_opts'};
        if (scalar $bond_config) {
            foreach my $key (@$bond_config) {
                push @data, $key;
            }
        }
    }

    # if ethernet device, map the mac address to the keyfile
    if ($is_eth) {
        push @data, '[ethernet]';
        push @data, 'mac-address=' . uc($iface->{hwaddr});
        # add mut if defined
        if (defined($iface->{mtu})) {
            push @data, 'mtu='.$iface->{mtu};
        }
    }

    # ipaddr config
    my $msg;
    if ($eth_bootproto eq 'static') {
        if ($is_ip) {
            # if device has manual ip assigned
            $msg = "Using static bootproto for $device";
            my $ip;
            if ($iface->{netmask}) {
                $ip = NetAddr::IP->new($iface->{ip}."/".$iface->{netmask});
            } else {
                $self->error("$msg with (IPv4) ip and no netmask configured");
            }
            push @data, '[ipv4]';
            push @data, 'address1=' . $ip->cidr . ',' . $iface->{gateway};
            push @data, 'ignore-auto-dns=true';
            push @data, 'method=manual';
        } else {
            $msg .= " and no (IPv4) ip configured";
            if ($ipv6 && $iface->{ipv6addr}) {
                $self->verbose("$msg (but ipv6 is enabled and ipv6 addr configured)");
            } else {
                $self->error($msg);
            }
        }
    } elsif (($eth_bootproto eq "none") && (!$is_bond_eth)) {
            # no ip on interface andis not a bond eth, assume not managed so disabled ip. 
            push @data, '[ipv4]';
            push @data, 'method=disabled';
            # TODO: check if ipv6 enabled, do stuff
    
    }

    # add generated options for ethtool settings. offload, ring, pause, calesce.
    # ethtool section
    push (@data, '[ethtool]');
    my @ethtool_config = keys %{$iface->{'ethtool'}};
    if (scalar @ethtool_config) {
        # TODO: add required ethtool options to keyfile for perm setting.
        $self->verbose("ethtool_opts found, NM will manage it");
        foreach my $key ( @ethtool_config ){ 
            push @data, $key . '=' . $iface->{ethtool}->{$key};
        }  
    }
    my @ethtool_offload = keys %{$iface->{'offload'}};
    if (scalar @ethtool_offload) {
        # TODO: add required ethtool options to keyfile for perm setting.
        $self->verbose("ethtool offload found, NM will manage it");
        foreach my $key ( @ethtool_offload ){ 
            push @data, 'feature-'. $key . '=' . $iface->{offload}->{$key};
        }
    }
    my @ethtool_ring = keys %{$iface->{'ring'}};
    if (scalar @ethtool_ring) {
        # TODO: add required ethtool options to keyfile for perm setting.
        $self->verbose("ethtool ring buffer setting found, NM will manage it");
        foreach my $key ( @ethtool_ring ){ 
            push @data, 'ring-'. $key . '=' . $iface->{ring}->{$key};
        } 
    }
    my @ethtool_pause = keys %{$iface->{'pause'}};
    if (scalar @ethtool_pause) {
        # TODO: add required ethtool options to keyfile for perm setting.
        $self->verbose("ethtool pause buffer setting found, NM will manage it");
        foreach my $key ( @ethtool_pause ){ 
            push @data, 'pause-'. $key . '=' . $iface->{pause}->{$key};
        }
    }
    my @ethtool_coalesce = keys %{$iface->{'coalesce'}};
    if (scalar @ethtool_coalesce) {
        # TODO: add required ethtool options to keyfile for perm setting.
        $self->verbose("ethtool coalesce setting found, NM will manage it");
        foreach my $key ( @ethtool_coalesce ){ 
            push @data, 'coalesce-'. $key . '=' . $iface->{coalesce}->{$key};
        } 
    }
    # end ethtool section.
    
    my $bridge_config = $iface->{'bridging_opts'};
    if (scalar $bridge_config) {
        # TODO: findout keyfile config for bridgings_opts
        $self->warn("briging_opts found, but not supported.");
        # perhaps below will work, needs testing.
        #foreach my $key (@$bridge_config) {
        #    push @data, $key;
        #}
    }
    # IPv6 additions, for now disabled
    push(@data,'[ipv6]');
    if ($ipv6) {
        # TODO: create ipv6 configs, not yet fully tested or supported.
        $self->warn("ipv6 is enabled but not supported yet");
        push (@data, "address1=" . $iface->{ipv6addr});
        my $ipv6addr_secondaries = $iface->{'ipv6addr_secondaries'};
        if (scalar $ipv6addr_secondaries) {
            my $idx=2;
            foreach my $ipv6 (@$ipv6addr_secondaries) {
                push (@data, "address$idx=$ipv6");
                $idx++;
            }
        }

        push(@data, 'method=manual');
    } else {
        push(@data, 'method=disabled')
    }
    return \@data;
}

# enable NetworkManager service
#   without enabled network service, this component is pointless
#   best to also enable the network service with ncm-chkconfig
sub enable_network_service
{
    my ($self) = @_;
    # do not start it!
    return $self->runrun([qw(systemctl enable NetworkManager)]);
}

# For NetworkManager, reload is enough here, 
# keeping stop the same, but we are only doing reload of config.
# Returns if something was done or not
sub stop
{
    my ($self, $exifiles, $ifdown, $nwsrv) = @_;

    my @ifaces = sort keys %$ifdown;

    my $action;
    my $nwupdated = $exifiles->{$NETWORKCFG} == $UPDATED;

    if ($nwupdated || @ifaces) {
        if (@ifaces) {
            my @cmds;
            foreach my $iface (@ifaces) {
                # can do nmcli conn up $iface if required but I dont think its required. relaod is safer.
                push(@cmds, ["nmcli conn reload $iface"]);
            }
            $self->verbose("reload interfaces ",join(', ', @ifaces));
            $action = 1;
            $self->runrun(@cmds);
        }

        if ($nwupdated) {
            $self->verbose("$NETWORKCFG UPDATED, reloading network");
            $action = 1;
            $nwsrv->reload();
        }
    } else {
        $self->verbose('Nothing to stop');
        $action = 0;
    }

    return $action;
}


# NetworkManager will be reload. Keeping start/stop as before but doing reload.
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
            # can do nmcli conn up $iface but I dont think its required
            push(@cmds, ["nmcli conn reload $iface"]);
            push(@cmds, ["nmcli conn up $iface"]);
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


sub Configure
{
    my ($self, $config) = @_;
    return if ! defined($self->init_backupdir());

    # current setup, will be printed in case of major failure
    my $init_config = $self->get_current_config();
    # The original, assumed to be working resolv.conf
    # Using an FileEditor: it will read the current content, so we can do a close later to save it
    # in case something changed it behind our back.
    my $resolv_conf_fh = CAF::FileEditor->new($RESOLV_CONF, backup => $RESOLV_SUFFIX, log => $self);
    # Need to reset the original content (otherwise the close will not check the possibly updated content on disk)
    *$resolv_conf_fh->{original_content} = undef;

    my $net = $self->process_network($config);
    my $ifaces = $net->{interfaces};

    # keep a hash of all files and links.
    # makes a backup of all files
    my ($exifiles, $exilinks) = $self->gather_existing();
    return if ! defined($exifiles);

    my $comp_tree = $config->getTree($self->prefix());
    my $nwtree = $config->getTree($NETWORK_PATH);

    # no backup, restart or anything else required
    $self->routing_table($nwtree->{routing_table});

    # main network config
    return if ! defined($self->mk_bu($NETWORKCFG));

    my $hostname = $nwtree->{realhostname} || "$nwtree->{hostname}.$nwtree->{domainname}";

    my $use_hostnamectl = $self->_is_executable($HOSTNAME_CMD);
    # if hostnamectl exists, do not set it via the network config file
    # systemd rpm --script can remove it anyway
    my $nwcfg_hostname = $use_hostnamectl ? undef : $hostname;

    my ($text, $ipv6) = $self->make_network_cfg($nwtree, $net, $nwcfg_hostname);
    $exifiles->{$NETWORKCFG} = $self->file_dump($NETWORKCFG, $text);

    if ($exifiles->{$NETWORKCFG} == $UPDATED && $use_hostnamectl) {
        # Network config was updated, check if it was due to removal of HOSTNAME
        # when hostnamectl is present.
        my ($hntext, $hnipv6) = $self->make_network_cfg($nwtree, $net, $hostname);
        $self->legacy_keeps_state($NETWORKCFG, $hntext, $exifiles);
    };
    
    # keyfile to manage network manager
    foreach my $ifacename (sort keys %$ifaces) {
        my $iface = $ifaces->{$ifacename};
        my $keyfile = make_nm_keyfile($self, $ifacename, $net, $ipv6);
        my $file_name = "$NMCFG_DIR/$ifacename.nmconnection";
        
        $exifiles->{$file_name} = $self->file_dump($file_name, $keyfile);

        # TODO: not sure about what is going on here, keeping it out for now
        #$self->default_broadcast_keeps_state($file_name, $ifacename, $iface, $exifiles, 0);
        $self->ethtool_opts_keeps_state($file_name, $ifacename, $iface, $exifiles);

        if ($exifiles->{$file_name} == $UPDATED) {
            # interface configuration was changed
            # check if this was due to addition of resolv_mods / peerdns
            my $no_resolv = $self->make_ifcfg($ifacename, $iface, $ipv6, resolv_mods => 0, peerdns => 0);
            $self->legacy_keeps_state($file_name, $no_resolv, $exifiles);
        }

        # route/rule config, interface based.
        foreach my $flavour (qw(route route6 rule rule6)) {
            if (defined($iface->{$flavour})) {
                my $method = "make_ifcfg_ip_$flavour";
                $method =~ s/6$//;
                # pass device, not system interface name
                my $text = $self->$method($flavour, $iface->{device} || $ifacename, $iface->{$flavour});

                my $file_name = "$NMCFG_DIR/$flavour-$ifacename";
                $exifiles->{$file_name} = $self->file_dump($file_name, $text);
            }
        }

        # legacy IPv4 format
        # TODO: this won't work with nm, alternative setup?
        $file_name = "$NMCFG_DIR/route-$ifacename";
        if (exists($exifiles->{$file_name}) && $exifiles->{$file_name} == $UPDATED) {
            # IPv4 route data was modified.
            # Check if it was due to conversion of legacy format or
            #   if there were actual changes in the config (or both)
            $self->legacy_keeps_state($file_name, $self->make_ifcfg_route4_legacy($iface->{route}), $exifiles);
        }


        # set up aliases for interfaces
        # one file per alias
        # TODO: not done anything to support with keyfile alias approach here.
        # alias interfaces have fallen out of favor. https://access.redhat.com/discussions/4221861
        # need to find out how add this in keyfile format.
        foreach my $al (sort keys %{$iface->{aliases} || {}}) {
            my $al_dev = ($iface->{device} || $ifacename) . ":$al";
            my $al_iface = $iface->{aliases}->{$al};
            my $text = $self->make_ifcfg_alias($al_dev, $al_iface);

            my $file_name = "$NMCFG_DIR/ifcfg-$ifacename:$al";
            $exifiles->{$file_name} = $self->file_dump($file_name, $text);

            $self->default_broadcast_keeps_state($file_name, $al_dev, $al_iface, $exifiles, 1);

            # This is the only way it will work for VLANs
            # If vlan device is vlanX and the DEVICE is eg ethY.Z
            # you need a symlink to ifcfg-ethY.Z:alias <- ifcfg-vlanX:alias
            # Otherwise ifup 'ifcfg-vlanX:alias' will work, but restart of network will look for
            # ifcfg-ethY.Z:alias associated with vlan0 (and DEVICE field)
            # Problem is, we want both
            # Adding symlinks however is not the best thing to do.

            my $file_name_sym = "$NMCFG_DIR/ifcfg-$al_dev";
            if ($iface->{vlan} &&
                $file_name_sym ne $file_name &&
                ! $self->any_exists($file_name_sym)) { # TODO: should check target with readlink
                # this will create broken link, if $file_name is not yet existing
                $self->symlink($file_name, $file_name_sym) ||
                    $self->error("Failed to create symlink from $file_name to $file_name_sym ($!)");
            };
        }
    }

    my $dev2mac = $self->make_dev2mac();

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

    my $ifdown = $self->make_ifdown($exifiles, $ifaces, $dev2mac);
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

    $self->enable_network_service();

    $self->start_openvswitch($ifaces, $ifup);

    $self->set_hostname($hostname);

    # TODO: why do that here? should be done after any restarting of devices or whole network?
    $self->ethtool_set_options($ifaces);

    # Record any changes wrt the init config (e.g. due to stopping of NetworkManager)
    $init_config .= "\nPRE STOP\n";
    $init_config .= $self->get_current_config();

    # restart network
    # capturing system output/exit-status here is not useful.
    # network status is tested separately
    # flow:
    #   1. stop everythig using old config
    #   2. replace updated/new config; remove REMOVE
    #   3. (re)start things
    my $nwsrv = CAF::Service->new(['NetworkManager'], log => $self);
    $self->disable_nm_manage_dns($nwtree->{nm_manage_dns}, $nwsrv);

    # Rename special/magic RESOLV_CONF_SAVE, so it does not get picked up by ifdown.
    # If it exists, and contains faulty DNS config, things might go haywire.
    # When there is no RESOLV_MODS=no or PEERDNS=no set (e.g. initial anaconda generated
    # ifcfg files which also have DNS1 set), ifdown-post might cause restore of previously saved /etc/resolv.conf
    # (most likely in this scenario saved by ifup-post)
    # and leave a system without configured DNS (which ncm-network can't recover from,
    # as it does not manage /etc/resolv.conf). Without working DNS, the ccm-fetch network test will probably fail.
    $self->move($RESOLV_CONF_SAVE, $RESOLV_CONF_SAVE.$RESOLV_SUFFIX);

    my $stopstart = $self->stop($exifiles, $ifdown, $nwsrv);

    $init_config .= "\nPOST STOP\n";
    $init_config .= $self->get_current_config();

    my $rename;
    if ($comp_tree->{rename}) {
        # Rename the (physical) network devices
        $rename = $self->make_rename_map($dev2mac, $net->{interfaces});

        if (!$rename) {
            $self->error("Failed to make rename map, nothing to rename");
        } else {
            if (%$rename) {
                # Rename
                #   either the devices are scheduled for in ifdown or
                #   scheduled for start in ifup (but not in ifdown),
                #   or conifgured but somehow we don't care?
                #   In any case, it's ok to down any device in the rename map
                $self->down_rename_devices($rename);

                $init_config .= "\nPOST DOWN RENAME\n";
                $init_config .= $self->get_current_config();

                # rerun ethtool
                # TODO: why do that here? should be done after any restarting of devices or whole network?
                $self->ethtool_set_options($ifaces);
            } else {
                $self->verbose("Nothing to rename");
            }
        }
    }

    my $config_changed = $self->deploy_config($exifiles);

    # Save/Restore last known working (i.e. initial) /etc/resolv.conf
    $resolv_conf_fh->close();

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

        $self->cleanup($RESOLV_CONF.$RESOLV_SUFFIX);
        $self->cleanup($RESOLV_CONF_SAVE.$RESOLV_SUFFIX);
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