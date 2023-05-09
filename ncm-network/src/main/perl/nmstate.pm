#${PMpre} NCM::Component::nmstate${PMpost}

=head1 NAME

network: Extention of Network to configure Network settings using NetworkManager by configuring in Keyfile format.
Most functions and logic is taken from network module to minimise changes to current network module.

=head1 DESCRIPTION

The I<network> component sets the network settings through C<< /etc/sysconfig/network >>
and the NM keyfile settings in files C<< /etc/NetworkManager/system-connections >>.

New/changed settings are first tested by retrieving the latest profile from the
CDB server (using ccm-fetch). 
If this fails, the component reverts all settings to the previous values. This is no different to network module.

During this test, a sleep value of 15 seconds is used to make sure the restarted network
is fully restarted (routing may need some time to come up completely).

Because of this, configuration changes may cause the ncm-ncd run to take longer than usual.

Be aware that configuration changes can also lead to a brief network interruption.
=cut

use parent qw (NCM::Component::network);

our $EC = LC::Exception::Context->new->will_store_all;
use EDG::WP4::CCM::TextRender;
use Readonly;

Readonly my $NMCFG_DIR => "/etc/nmstate";
Readonly my $NMCLI_CMD => '/usr/bin/nmcli';

# Given the configuration in nmconnection
# Determine if this is a valid interface for ncm-network to manage,
# Return arrayref tuple [interface name, ifdown/ifup name] when valid,
# undef otherwise.
sub is_valid_interface
{
    my ($self, $filename) = @_;

    # Very primitive, based on regex only
    # matchs eth0.yml bond0.yml, or bond0.101.yml
if (

    $filename =~ m{
        # Filename is either right at the beginning or following a slash
        (?: \A | / )
        # $1 will capture for example:
        # eth0  bond1  eth0.101  bond0.102
        ( \w+ \d+ (?: \. \d+ )? )
        # Suffix (not captured)
        \. yml \z
    }x
    ) {
        # name and id for nmstate, this will make connection id and name the same.
        my $name = $1;
        # previous is_valid_interface reuqires suffix, not concerned about this in nmstate so just return $name as suffix too.
        return [$name, $name];
    } else {
        return;
    };
}

# By default, NetworkManager on Red Hat Enterprise Linux (RHEL) 8+ dynamically updates the /etc/resolv.conf
# file with the DNS settings from active NetworkManager connection profiles. we manage this using ncm-resolver. 
# so disable this unless nm_manage_dns = true. resolver details can be set using nmstate but not doing this now.
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

# return hasref of policy rule. interface.tt module uses this to create the rule in nmstate file.
sub make_nm_ip_rule
{
    my ($self, $device, $rules, $routing_table_hash) = @_;

    my @text;
    my $idx=0;
    foreach my $rule (@$rules) {
        my $priority = 100;
        $priority = $rule->{priority} if $rule->{priority};
        if (!$rule->{table_id}) {
            $rule->{table_id} = "$routing_table_hash->{$rule->{table}}" if $rule->{table};
            push(@text, $rule->{table_id});
        }
        if (!$rule->{priority}){
            $rule->{priority} = $priority;
            push(@text, $rule->{priority});
        }
    }
    return \@text;
}

# construct all routes found into array of hashref
# return array of hashref, used by interface.tt module.
sub make_nm_ip_route
{
    my ($self, $device, $routes, $routing_table_hash) = @_;
    my @rt_entry;
    foreach my $route (@$routes) {
        my %rt;
        if ($route->{address} eq 'default') {
                $rt{destination} = '0.0.0.0/0';
        } else {
             if ($route->{netmask}){
                 my $dest_addr = NetAddr::IP->new($route->{address}."/".$route->{netmask});
                 $rt{destination} = $dest_addr->cidr;    
             } else {
                # if no netmask defined for a route, assume its single ip
                $rt{destination} = $route->{address}."/32";
             }
        }        
        $rt{table_id} = "$routing_table_hash->{$route->{table}}" if $route->{table};    
        $rt{next_hop_interface} = $device;
        $rt{next_hop_address} = $route->{gateway} if $route->{gateway};
        push (@rt_entry, \%rt);

    }
    return \@rt_entry;
}

# group all eth bound to a bond together in a hashref for to be used as 
# - port in nmstate config file
sub get_bonded_eth {
    my ($self, $interfaces) = @_;
    my @data =  ();
    foreach my $name (sort keys %$interfaces) {
        my $iface = $interfaces->{$name};
        if ( $iface->{master} ){
            push @data, $name; 
        }
    }
    return \@data;
}

# wirtes the nmstate yml file, uses nmstate/interface.tt module.
sub nmstate_file_dump {
    my ($self, $filename, $ifaceconfig) = @_;
    my $net_module = 'nmstate/interface';
    my $changes = 0;

    my $func = "nmstate_file_dump";
    my $testcfg = $self->testcfg_filename($filename);
    if (! defined($self->cleanup($testcfg, undef, keeps_state => 1))) {
        $self->warn("Failed to cleanup testcfg $testcfg before file_dump: $self->{fail}");
    }

    if (!$self->file_exists($filename) || $self->mk_bu($filename, $testcfg)) {
    
    my $trd = EDG::WP4::CCM::TextRender->new($net_module, $ifaceconfig, relpath => 'network');
    if (! defined($trd->get_text())) {
        $self->error ("Unable to generate network config $filename: $trd->{fail}");
        return;
    };
    my $fh = $trd->filewriter($testcfg,
                            header => "# File generated by " . __PACKAGE__ . ". Do not edit",
                            log => $self);
    my $filestatus;
    if ($fh->close()) {
            if ($self->file_exists($filename)) {
                $self->info("$func: file $filename has newer version scheduled.");
                $filestatus = $self->updated_state();
            } else {
                $self->info("$func: new file $filename scheduled.");
                $filestatus = $self->new_state();
            }
    } else {
        my $is_active = is_active_interface($self, $ifaceconfig->{name});
        if (( $is_active != 1 ) && ($ifaceconfig->{enabled}) eq "true"){
            # if we find no active connection for interface we are managing, lets attempt to start it.
            # mark the enterface schedule to be updated.
            # this will allow nm to report issues with config on every run or if someone deletes the conneciton.
            # if no changes to file, then this will never get applied again.
            $self->info("$func: file $filename has no active conneciton, scheduled for update.");
            $filestatus = $self->updated_state();    
        } else {
            $filestatus = $self->nochanges_state();
            # they're equal, remove backup files
            $self->verbose("$func: no changes scheduled for file $filename. Cleaning up.");
            $self->cleanup_backup_test($filename);
        }
    };
        return $filestatus;
    } else {
        return;
    }
}

# generates the hasrefs for interface used by nmstate/interface.tt module.
# bulk of the config settings needed by the nmstate yml is done here.
sub generate_nmstate_config {
    my ($self, $name, $net, $ipv6, $routing_table) = @_;

    my $bonded_eth = get_bonded_eth($self, $net->{interfaces});
    my $iface = $net->{interfaces}->{$name};
    my $device = $iface->{device} || $name;
    my $is_eth = $iface->{set_hwaddr};
    my $eth_bootproto = $iface->{bootproto};
    my $is_ip = exists $iface->{ip} ? 1 : 0;
    my $is_vlan_eth = exists $iface->{vlan} ? 1 : 0;
    my $is_bond_eth = exists $iface->{master} ? 1 : 0;
    my $iface_changed = 0;
    
    # create hash of interface entries that will be used by nmstate config.   
    my $ifaceconfig->{name} = $name;
    $ifaceconfig->{device} = $device;
    if ($is_eth) {
        $ifaceconfig->{type} = "ethernet";
        if ($is_bond_eth) {
            # no ipv4 address for bonded eth, plus in nmstate bonded eth is controlled by controller. no config is required.
            $ifaceconfig->{enabled} = "false";
            $ifaceconfig->{state} = "up";
        }
    } elsif ($is_vlan_eth) {
        my $vlan_id = $name;
        # replace eveytthing upto and include . to get vlan id of the interface.
        $vlan_id =~ s/^[^.]*.//;;    
        $ifaceconfig->{type} = "vlan";
        $ifaceconfig->{vlan}->{base_iface} = $iface->{physdev};
        $ifaceconfig->{vlan}->{vlan_id} = $vlan_id;
    } else {
        # if bond device
        $ifaceconfig->{type} = "bond";
        $ifaceconfig->{link_aggregation} = $iface->{link_aggregation};
        if ($bonded_eth){
            $ifaceconfig->{link_aggregation}->{port} = $bonded_eth;
        }
    }
    
    if ($eth_bootproto eq 'static') {
        $ifaceconfig->{state} = "up";
        if ($is_ip) {
            # if device has manual ip assigned
            my $ip;
            if ($iface->{netmask}) {
                $ip = NetAddr::IP->new($iface->{ip}."/".$iface->{netmask});
            } else {
                $self->error("$name with (IPv4) ip and no netmask configured");
            }
            my $ip_list=();
            $ip_list->{ip} = $ip->addr;
            $ip_list->{prefix} = $ip->masklen;
            # TODO: append alias ip to ip_list as array, providing ips as array of hashref.
            $ifaceconfig->{ipv4}->{address} = [$ip_list];
            $ifaceconfig->{enabled} = "true";
        } else {
            # TODO: configure IPV6 enteries
            if ($iface->{ipv6addr}) {
                $self->warn("ipv6 addr found but not supported");
                # TODO create ipv6.address entries here. i.e
                #$ifaceconfig->{ipv6}->{address} = [$ipv6_list];
                #.tt module support is added.                
            } else {
                $self->verbose("no ipv6 entries");
            }
        }
    } elsif (($eth_bootproto eq "none") && (!$is_bond_eth)) {
            # no ip on interface and is not a bond eth, assume not managed so disable eth. 
            $ifaceconfig->{enabled} = "false";
            $ifaceconfig->{state} = "down";
    }
    # create default route entry.
    my %default_rt;
    if (defined($iface->{gateway})){
        $default_rt{destination} = '0.0.0.0/0';
        $default_rt{next_hop_address} = $iface->{gateway};
        $default_rt{next_hop_interface} = $device;
    }
    # combined default route with any policy routing/rule, if any
    # combination of default route, plus any additional policy routes.
    # read and set by tt module as 
    # routes:
    #   config:
    #   - desitionation:
    #     next-hop-address:
    #     next-hop-interface:
    #  and so on.
    my $routes;
    if (defined($iface->{route})) {
        $self->verbose("policy route found, nmstate will manage it");
        my $route = $iface->{route};
        $routes = $self->make_nm_ip_route($name, $route, $routing_table);
        push @$routes, \%default_rt if scalar %default_rt;
    } elsif (scalar %default_rt){
        push @$routes, \%default_rt if scalar %default_rt;
    }

    if (defined($iface->{rule})) {
        my $rule = $iface->{rule};
        $self->make_nm_ip_rule($iface, $rule, $routing_table);
        $self->verbose("policy rule found, nmstate will manage it");
    }
    if (scalar $routes){
        $ifaceconfig->{routes}->{config} = $routes;
    }
    #print (YAML::XS::Dump($ifaceconfig));
    
    # TODO: ethtool settings to add in config file? setting via cmd cli working as is.
    # TODO: aliases ip addresses
    # TODO: bridge_options
    # TODO: veth, anymore?

    return $ifaceconfig;
};


# enable NetworkManager service
#   without enabled network service, this component is pointless
#  
sub enable_network_service
{
    my ($self) = @_;
    # vendor preset anyway
    return $self->runrun([qw(systemctl enable NetworkManager)]);
}

# keep nmstate service disbaled (vendor preset anyway), we will apply config ncm component.
# nmstate service applies all files found in /etc/nmstate and changes to .applied, which will keep change if component is managing the .yml file.
#   
sub disable_nmstate_service
{
    my ($self) = @_;
    # vendor preset anyway
    return $self->runrun([qw(systemctl disable nmstate)]);
}

# check to see if we have active connection for interface we manage.
# this allow ability to start a connection again that may have failed with nmstate apply
sub is_active_interface
{
    my ($self, $ifacename) = @_;
    my $output = $self->runrun(["$NMCLI_CMD -f name conn show --active"]);
    my @existing_conn = split('\n', $output);
    my %current_conn;
    my $found = 0;
    foreach  my $conn_name  (@existing_conn) {
        $conn_name =~ s/\s+$//;
        if ($conn_name eq $ifacename){
            $found = 1;
            return $found ;
        };
    }
    return $found;
}

# check for existing connections, will clear the default connections created by 'NM with Wired connecton x'
sub clear_default_nm_connections
{
    my ($self) = @_;
    # NM creates auto connections with Wired connection x
    # Delete all connections with name 'Wired connection', everything ncm-network creates will have connection name set to interface name.
    my $output = $self->runrun(["$NMCLI_CMD -f name conn"]);
    my @existing_conn = split('\n', $output);
    my %current_conn;
    foreach  my $conn_name  (@existing_conn) {
        $conn_name =~ s/\s+$//;
        if ($conn_name =~ /Wired connection/){
            $self->verbose("Clearing default connections created automatically by NetworkManager [ $conn_name ]");
            $output = $self->runrun([$NMCLI_CMD,"conn", "delete", $conn_name]);
            $self->verbose($output);
        } 
    }
}

sub nmstate_apply
{
    my ($self, $exifiles, $ifup, $nwsrv) = @_;

    my @ifaces = sort keys %$ifup;
    my $nwstate = $exifiles->{$self->networkcfg()};
    
    my $action;
    my $nmstateclt_cmd = $self->nmstatectl();
    $self->verbose("Apply config using nmstatectl for each interface");
    if (($nwstate == $self->updated_state()) || ($nwstate == $self->new_state())) {
        # Do not need to start networking in nmstate.
        #$self->verbose($self->networkcfg(), ($nwstate == $self->new_state() ? 'NEW' : 'UPDATED'), " starting network");
        $action = 1;
    } 
    if (@ifaces) {
        $self->info("Applying changes using $nmstateclt_cmd ",join(', ', @ifaces));
        my @cmds;
        foreach my $iface (@ifaces) {
            # clear any connections created by NM with 'Wired connection x' to start fresh.
            $self->clear_default_nm_connections();
            # apply config using nmstatectl
            my $ymlfile = "$NMCFG_DIR/$iface.yml";
            if ($self->any_exists($ymlfile)){
                push(@cmds, ["$nmstateclt_cmd apply $ymlfile"]);
                push(@cmds, [qw(sleep 10)]) if ($iface =~ m/bond/);
            } else {
                # do we down the interface?
                $self->verbose("$ymlfile does not exist, not applying");
            }
        }
        $action = 1;
        my $out = $self->runrun(@cmds);
        $self->verbose($out);
    } else {
        $self->verbose('Nothing to apply');
        $action = 0;
    }

    return $action;
}

sub Configure
{
    my ($self, $config) = @_;

    $self->set_cfg_dir($NMCFG_DIR);
    return if ! defined($self->init_backupdir());
    
    # current setup, will be printed in case of major failure
    my $init_config = $self->get_current_config();
    # The original, assumed to be working resolv.conf
    # Using an FileEditor: it will read the current content, so we can do a close later to save it
    # in case something changed it behind our back.
    my $resolv_conf_fh = CAF::FileEditor->new($self->resolv_conf(), backup => $self->resolv_suffix(), log => $self);
    # Need to reset the original content (otherwise the close will not check the possibly updated content on disk)
    *$resolv_conf_fh->{original_content} = undef;

    my $net = $self->process_network($config);
    my $ifaces = $net->{interfaces};

    # keep a hash of all files and links.
    # makes a backup of all files
    my ($exifiles, $exilinks) = $self->gather_existing();
    return if ! defined($exifiles);

    my $comp_tree = $config->getTree($self->prefix());
    my $nwtree = $config->getTree($self->network_path());

    # no backup, restart or anything else required
    $self->routing_table($nwtree->{routing_table});

    # main network config
    return if ! defined($self->mk_bu($self->networkcfg()));

    my $hostname = $nwtree->{realhostname} || "$nwtree->{hostname}.$nwtree->{domainname}";

    my $use_hostnamectl = $self->_is_executable($self->hostname_cmd());
    # if hostnamectl exists, do not set it via the network config file
    # systemd rpm --script can remove it anyway
    my $nwcfg_hostname = $use_hostnamectl ? undef : $hostname;

    my ($text, $ipv6) = $self->make_network_cfg($nwtree, $net, $nwcfg_hostname);
    $exifiles->{$self->networkcfg()} = $self->file_dump($self->networkcfg(), $text);

    if ($exifiles->{$self->networkcfg()} == $self->updated_state() && $use_hostnamectl) {
        # Network config was updated, check if it was due to removal of HOSTNAME
        # when hostnamectl is present.
        my ($hntext, $hnipv6) = $self->make_network_cfg($nwtree, $net, $hostname);
        $self->legacy_keeps_state($self->networkcfg(), $hntext, $exifiles);
    };
    
    foreach my $ifacename (sort keys %$ifaces) {
        my $iface = $ifaces->{$ifacename};
        my $nmstate_cfg = generate_nmstate_config($self, $ifacename, $net, $ipv6, $nwtree->{routing_table});
        my $file_name = "$NMCFG_DIR/$ifacename.yml";
        $exifiles->{$file_name} = $self->nmstate_file_dump($file_name, $nmstate_cfg);

        # TODO: not sure about what is going on here, keeping it out for now
        #$self->default_broadcast_keeps_state($file_name, $ifacename, $iface, $exifiles, 0);
        $self->ethtool_opts_keeps_state($file_name, $ifacename, $iface, $exifiles);

        if ($exifiles->{$file_name} == $self->updated_state()) {
            # interface configuration was changed
            # check if this was due to addition of resolv_mods / peerdns
            my $no_resolv = $self->make_ifcfg($ifacename, $iface, $ipv6, resolv_mods => 0, peerdns => 0);
            $self->legacy_keeps_state($file_name, $no_resolv, $exifiles);
        }
    }

    my $dev2mac = $self->make_dev2mac();

    # We now have a map with files and values.
    # Changes to the general network config file are handled separately.
    # For devices: we will create a list of affected devices

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

    # TODO: not tested with nmstate. leaving it here.
    $self->start_openvswitch($ifaces, $ifup);

    $self->set_hostname($hostname);

    # TODO: ethtool options are set using cli, but do we need to update in nmstate config? works for now
    $self->ethtool_set_options($ifaces);

    # Record any changes wrt the init config (e.g. due to stopping of NetworkManager)
    $init_config .= "\nPRE APPLY\n";
   
    $init_config .= $self->get_current_config();

    # restart network
    # capturing system output/exit-status here is not useful.
    # network status is tested separately
    # flow:
    #   1. stop everythig using old config
    #   2. replace updated/new config; remove REMOVE
    #   3. (re)start things
    my $nwsrv = CAF::Service->new(['NetworkManager'], log => $self);
    
    # NetworkManager manages dns by default, but we manage dns with ncm-resolver, new option to eanble/disable it.
    $self->disable_nm_manage_dns($nwtree->{nm_manage_dns}, $nwsrv);

    # nmstate files are applied uinsg nmstate apply via this componant. We don't want nmstate svc to manage it.
    # If nmstate svc manages the files, it will apply the config for any files found in /etc/nmstate with .yml extension. Once the config is applied, 
    # the file name changes to .applied, which won't be ideal if ncm-component is managing .yml files.
    # for this reason we don't really need nmstate service running. It comes disabled by default anyway.
    $self->disable_nmstate_service();

    # Rename special/magic RESOLV_CONF_SAVE, so it does not get picked up by ifdown.
    # If it exists, and contains faulty DNS config, things might go haywire.
    # When there is no RESOLV_MODS=no or PEERDNS=no set (e.g. initial anaconda generated
    # ifcfg files which also have DNS1 set), ifdown-post might cause restore of previously saved /etc/resolv.conf
    # (most likely in this scenario saved by ifup-post)
    # and leave a system without configured DNS (which ncm-network can't recover from,
    # as it does not manage /etc/resolv.conf). Without working DNS, the ccm-fetch network test will probably fail.
    $self->move($self->resolv_conf_save(), $self->resolv_conf_save().$self->resolv_suffix());

    # only need to deploy config.
    my $config_changed = $self->deploy_config($exifiles);

    # Save/Restore last known working (i.e. initial) /etc/resolv.conf
    $resolv_conf_fh->close();

    # Since there's per interface reload, interface changes will be applied via nmstatectl.
    # nmstatectl manages rollback too when options are misconfigured in yml config
    # This is still used to marke interfaces to apply any changes via nmstatectl
    # TODO apply changes if exisitng connection is not active but we manage the file.
    my $stopstart += $self->nmstate_apply($exifiles, $ifup, $nwsrv);
    $init_config .= "\nPOST APPLY\n";
    $init_config .= $self->get_current_config();

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

        $self->cleanup($self->resolv_conf().$self->resolv_suffix());
        $self->cleanup($self->resolv_conf_save().$self->resolv_suffix());
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