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

use parent qw(NCM::Component::network);
use NCM::Component::network;  # required for the import of the (default) exports

our $EC = LC::Exception::Context->new->will_store_all;
use EDG::WP4::CCM::TextRender;
use Readonly;

Readonly my $NMSTATECTL => '/usr/bin/nmstatectl';
Readonly my $NMCLI_CMD => '/usr/bin/nmcli';
# pick a config name for nmstate yml to configure dns-resolver: settings. if nm_manage_dns=true
Readonly my $NM_RESOLV_YML => "/etc/nmstate/resolv.yml";

# generate the correct fake yaml boolean value so TextRender can convert it in a yaml boolean
Readonly my $YTRUE => $EDG::WP4::CCM::TextRender::ELEMENT_CONVERT{yaml_boolean}->(1);
Readonly my $YFALSE => $EDG::WP4::CCM::TextRender::ELEMENT_CONVERT{yaml_boolean}->(0);

use constant IFCFG_DIR => "/etc/nmstate";

sub iface_filename
{
    my ($self, $iface) = @_;
    return $self->IFCFG_DIR . "/$iface.yml";
}

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
    if ( $manage_dns ) {
        # cleanup the config if was created previously
        if ($self->file_exists($filename)) {
            my $msg = "REMOVE config $filename, NOTE: networkmanager will manage resolv.conf";
            if ($self->cleanup($filename)) {
                $self->info($msg);
                $self->verbose("Reload NetworkManager");
                $nwsrv->reload();
            } else {
                $self->error("$msg failed. ($self->{fail})");
            };
        };
    } else {
        $self->verbose("Configuring networkmanager not to manage resolv.conf");
        my $fh = CAF::FileWriter->new($filename, mode => oct(444), log => $self, keeps_state => 1);
        print $fh join("\n", @data, '');
        if ($fh->close()) {
            $self->info("File $filename changed, reload network");
            $nwsrv->reload();
        };
    }
}

# return hasref of policy rule.
sub make_nm_ip_rule
{
    my ($self, $device, $rules, $routing_table_hash) = @_;

    my @rule_entry;
    foreach my $rule (@$rules) {
        my %thisrule;
        my $priority = 100;
        $priority = $rule->{priority} if $rule->{priority};
        $thisrule{priority} = $priority;
        $thisrule{'route-table'} = "$routing_table_hash->{$rule->{table}}" if $rule->{table};
        $thisrule{'ip-to'} = $rule->{to} if $rule->{to};
        $thisrule{'ip-from'} = $rule->{from} if $rule->{from};
        push (@rule_entry, \%thisrule);
    }
    return \@rule_entry;
}

# construct all routes found into array of hashref
# return array of hashref
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
        $rt{'table-id'} = "$routing_table_hash->{$route->{table}}" if $route->{table};
        $rt{'next-hop-interface'} = $device;
        $rt{'next-hop-address'} = $route->{gateway} if $route->{gateway};
        push (@rt_entry, \%rt);

    }
    return \@rt_entry;
}

# group all eth bound to a bond together in a hashref for to be used as
# - port in nmstate config file
sub get_bonded_eth
{
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

# writes the nmstate yml file, using yaml module.
sub nmstate_file_dump
{
    my ($self, $filename, $ifaceconfig) = @_;
    # ATM interfaces hash will only have one entry per interface. so looking at first entry is fine. long as file isn't resolv.yml
    my $iface = $ifaceconfig->{'interfaces'}[0] if ($filename ne $NM_RESOLV_YML);

    my $changes = 0;

    my $func = "nmstate_file_dump";
    my $testcfg = $self->testcfg_filename($filename);
    if (! defined($self->cleanup($testcfg, undef, keeps_state => 1))) {
        $self->warn("Failed to cleanup testcfg $testcfg before file_dump: $self->{fail}");
    }

    if (!$self->file_exists($filename) || $self->mk_bu($filename, $testcfg))
    {
        my $trd = EDG::WP4::CCM::TextRender->new('yaml', $ifaceconfig, relpath => 'network');
        if (! defined($trd->get_text()))
        {
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
                $filestatus = $UPDATED;
            } else {
                $self->info("$func: new file $filename scheduled.");
                $filestatus = $NEW;
            }
        } else {
            if ($filename ne $NM_RESOLV_YML)
            {
                # if it's interface file, lets check if there is a active connection.
                my $is_active = is_active_interface($self, $iface->{name});
                if (( $is_active != 1 ) && ($iface->{state}) eq "up") {
                    # if we find no active connection for interface we are managing, lets attempt to start it.
                    # mark the enterface schedule to be updated.
                    # this will allow nm to report issues with config on every run instead of just first run when change is made.
                    # or if someone deletes the conneciton.
                    # if no changes to file, then this will never get applied again.
                    $self->info("$func: file $filename has no active connection, scheduled for update.");
                    $filestatus = $UPDATED;
                } else {
                    $filestatus = $NOCHANGES;
                    # they're equal, remove backup files
                    $self->verbose("$func: no changes scheduled for file $filename. Cleaning up.");
                    $self->cleanup_backup_test($filename);
                }
            } else {
                $filestatus = $NOCHANGES;
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

# generates the hasrefs for interface in yaml file format needed by nmstate.
# bulk of the config settings needed by the nmstate yml is done here.
# to add additional options, it should be constructed here.
sub generate_nmstate_config
{
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
    if ($is_eth) {
        $ifaceconfig->{type} = "ethernet";
        if ($is_bond_eth) {
            # no ipv4 address for bonded eth, plus in nmstate bonded eth is controlled by controller. no config is required.
            $ifaceconfig->{ipv4}->{enabled} = "false";
            $ifaceconfig->{state} = "up";
        }
    } elsif ($is_vlan_eth) {
        my $vlan_id = $name;
        # replace eveything upto and including . to get vlan id of the interface.
        # TODO: instead of this, should perhaps add valid-id  in schema? but may not be backward compatible for existing host entreis, aqdb will need updating?
        $vlan_id =~ s/^[^.]*.//;;
        $ifaceconfig->{type} = "vlan";
        $ifaceconfig->{vlan}->{'base-iface'} = $iface->{physdev};
        $ifaceconfig->{vlan}->{'id'} = $vlan_id;
    } else {
        # if bond device
        $ifaceconfig->{type} = "bond";
        $ifaceconfig->{'link-aggregation'} = $iface->{link_aggregation};
        if ($bonded_eth){
            $ifaceconfig->{'link-aggregation'}->{port} = $bonded_eth;
        }
    }

    if (defined($eth_bootproto)) {
        if ($eth_bootproto eq 'static') {
            $ifaceconfig->{state} = "up";
            if ($is_ip) {
                # if device has manual ip assigned
                my $ip_list = {};
                if ($iface->{netmask}) {
                    my $ip = NetAddr::IP->new($iface->{ip}."/".$iface->{netmask});
                    $ip_list->{ip} = $ip->addr;
                    $ip_list->{'prefix-length'} = $ip->masklen;
                } else {
                    $self->error("$name with (IPv4) ip and no netmask configured");
                }

                # TODO: append alias ip to ip_list as array, providing ips as array of hashref.
                $ifaceconfig->{ipv4}->{address} = [$ip_list];
                $ifaceconfig->{ipv4}->{enabled} = $YTRUE;
            } else {
                # TODO: configure IPV6 enteries
                if ($iface->{ipv6addr}) {
                    $self->warn("ipv6 addr found but not supported");
                    $ifaceconfig->{ipv6}->{enabled} = $YFALSE;
                    # TODO create ipv6.address entries here. i.e
                    #$ifaceconfig->{ipv6}->{address} = [$ipv6_list];
                } else {
                    $self->verbose("no ipv6 entries");
                }
            }
        } elsif (($eth_bootproto eq "none") && (!$is_bond_eth)) {
            # no ip on interface and is not a bond eth, assume not managed so disable eth.
            $ifaceconfig->{ipv4}->{enabled} = "false";
            $ifaceconfig->{ipv6}->{enabled} = "false";
            $ifaceconfig->{state} = "down";
        }
    }

    # create default route entry.
    my %default_rt;
    if (defined($iface->{gateway})){
        $default_rt{destination} = '0.0.0.0/0';
        $default_rt{'next-hop-address'} = $iface->{gateway};
        $default_rt{'next-hop-interface'} = $device;
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
    my $routes = [];
    if (defined($iface->{route})) {
        $self->verbose("policy route found, nmstate will manage it");
        my $route = $iface->{route};
        $routes = $self->make_nm_ip_route($name, $route, $routing_table);
        push @$routes, \%default_rt if scalar %default_rt;
    } elsif (scalar %default_rt){
        push @$routes, \%default_rt if scalar %default_rt;
    }

    my $policy_rule = [];
    if (defined($iface->{rule})) {
        my $rule = $iface->{rule};
        $policy_rule = $self->make_nm_ip_rule($iface, $rule, $routing_table);
        $self->verbose("policy rule found, nmstate will manage it");
    }
    # return hash construct that will match what nmstate yml needs.
    my $interface->{interfaces} = [$ifaceconfig];
    if (scalar @$routes) {
        $interface->{routes}->{config} = $routes;
    }
    if (scalar @$policy_rule) {
        $interface->{'route-rules'}->{config} = $policy_rule;
    }

    #print (YAML::XS::Dump($interface));

    # TODO: ethtool settings to add in config file? setting via cmd cli working as is.
    # TODO: add aliases ip addresses
    # TODO: bridge_options
    # TODO: veth, anymore?

    return $interface;
};

# Genareate hash of dns-resolver config for nmstate.
# only used if nm_manage_dns = true.
sub generate_nm_resolver_config
{
    my ($self, $net, $manage) = @_;
    # resolver content will be empty if mange_dns is false
    my $nm_dns_config->{'dns-resolver'}->{config}->{search} = [];
    $nm_dns_config->{'dns-resolver'}->{config}->{server} = [];
    if ($manage)
    {
        # TODO: adding nameservers and domainname from network path, maybe we need to consider similar approach to ncm-resolver?
        my $searchpath;
        push @$searchpath, $net->{domainname};
        my $dnsservers = $net->{nameserver};
        $nm_dns_config->{'dns-resolver'}->{config}->{search} = $searchpath;
        $nm_dns_config->{'dns-resolver'}->{config}->{server} = $dnsservers;
    }
    return $nm_dns_config
}

# enable NetworkManager service
# without enabled NetworkManager, this component is pointless
#
sub enable_network_service
{
    my ($self) = @_;
    # vendor preset anyway
    return $self->runrun([qw(systemctl enable NetworkManager)]);
}

# keep nmstate service disbaled (vendor preset anyway), we will apply config ncm component.
# nmstate service applies all files found in /etc/nmstate and changes to .applied, which will keep changing if component is managing the .yml file.
# we don't need this.
#
sub disable_nmstate_service
{
    my ($self) = @_;
    # vendor preset anyway
    return $self->runrun([qw(systemctl disable nmstate)]);
}

# check to see if we have active connection for interface we manage.
# this allow ability to start a connection again if last config run failed to nmstate apply.
sub is_active_interface
{
    my ($self, $ifacename) = @_;
    my $output = $self->runrun([$NMCLI_CMD, "-t", "-f", "name,device", "conn", "show", "--active"]);
    # outoput returned by nmclie -t is colon seperated
    # i.e eth0:eth0
    my @existing_conn = split('\n', $output);
    my $found = 0;
    foreach my $conn_name (@existing_conn) {
        my ($name, $dev) = split(':', $conn_name);
        # trim
        if ("$dev" eq "$ifacename") {
            # ncm-network will set connection same as interface name, if this doesn't match,
            # it means this connection existed before nmstate did its first apply.
            # doesn't break anything as nmstate resuses the conn, but worth a warning to highlight it?
            if ("$name" ne "$ifacename"){
                $self->warn("connection name '$name' doesn't match $ifacename for device $dev, possible connection reuse occured")
            }
            $found = 1;
            return $found ;
        };
    }
    return $found;
}

# check for existing connections, will clear the default connections created by 'NM with Wired connecton x'
# good to have.
sub clear_default_nm_connections
{
    my ($self) = @_;
    # NM creates auto connections with Wired connection x
    # Delete all connections with name 'Wired connection', everything ncm-network creates will have connection name set to interface name.
    my $output = $self->runrun([$NMCLI_CMD, "-t", "-f", "name", "conn"]);
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
    my ($self, $exifiles, $ifup, $ifdown, $nwsrv) = @_;

    my @ifaces = sort keys %$ifup;
    my @ifaces_down = sort keys %$ifdown;
    my $action;

    if (@ifaces) {
        $self->info("Applying changes using $NMSTATECTL ", join(', ', @ifaces));
        my @cmds;
        # clear any connections created by NM with 'Wired connection x' to start fresh.
        $self->clear_default_nm_connections();
        foreach my $iface (@ifaces) {
            # apply config using nmstatectl
            my $ymlfile = $self->iface_filename($iface);
            if ($self->any_exists($ymlfile)){
                push(@cmds, [$NMSTATECTL, "apply", $ymlfile]);
                push(@cmds, [qw(sleep 10)]) if ($iface =~ m/bond/);
            } else {
                # TODO: perhaps try down the interface? it's done later anyway
                $self->verbose("$ymlfile does not exist for $iface, not applying");
            }
        }
        $action = 1;
        my $out = $self->runrun(@cmds);
        $self->verbose($out);
    } else {
        $self->verbose('Nothing to apply');
        $action = 0;
    }
    # apply resolver config if exists.
    # this will exist at this stage if nm_manage_dns is set to true.
    my $resolv_state = $exifiles->{$NM_RESOLV_YML} || 0;
    if ($self->file_exists($NM_RESOLV_YML))
    {
        my $nwstate = $exifiles->{$NM_RESOLV_YML};
        my @cmds;
        if (($nwstate == $UPDATED) || ($nwstate == $NEW)) {
            $self->verbose("$NM_RESOLV_YML: going to apply ", ($nwstate == $NEW ? 'NEW' : 'UPDATED'), " config");
            push(@cmds, [$NMSTATECTL, "apply", $NM_RESOLV_YML]);
            my $out = $self->runrun(@cmds);
            $self->verbose($out);
            $nwsrv->reload();
            $action = 1;
        }
    }
    # check if we need to stop any interface whose config has been removed.
    if (@ifaces_down) {
        my @cmds;
        foreach my $iface (@ifaces_down)
        {
            # nmcli down: all devices that are in ifdown
            # and have state of REMOVE
            my $cfg_filename = $self->iface_filename($iface);
            if (exists($exifiles->{"$cfg_filename"}) &&
                $exifiles->{"$cfg_filename"} == $REMOVE)
            {
                $self->verbose("REMOVE connection for interface $iface");
                push(@cmds, [$NMCLI_CMD, "connection", "delete", $iface]);
            }
        }
        $action = 1;
        my $out = $self->runrun(@cmds);
        $self->verbose($out);
    }
    return $action;
}

sub get_current_config_post
{
    my ($self) = @_;

    # Full output of nmstate
    my $output = $self->runrun([$NMSTATECTL, "show"]);

    # few useful outputs from nmcli
    $output .= $self->runrun([$NMCLI_CMD, "dev", "status"]);
    $output .= $self->runrun([$NMCLI_CMD, "connection"]);
    return $output;
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

    my $hostname = $nwtree->{realhostname} || "$nwtree->{hostname}.$nwtree->{domainname}";
    my $manage_dns = $nwtree->{nm_manage_dns} || 0;

    my $ipv6 = $nwtree->{ipv6};
    foreach my $ifacename (sort keys %$ifaces) {
        my $iface = $ifaces->{$ifacename};
        my $nmstate_cfg = generate_nmstate_config($self, $ifacename, $net, $ipv6, $nwtree->{routing_table});
        my $file_name = $self->iface_filename($ifacename);
        $exifiles->{$file_name} = $self->nmstate_file_dump($file_name, $nmstate_cfg);

        $self->ethtool_opts_keeps_state($file_name, $ifacename, $iface, $exifiles);
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

    # TODO: not tested with nmstate. leaving it here. needs work.lol y
    $self->start_openvswitch($ifaces, $ifup);

    # TODO: This can be set with nmstate config but we doing the triditional way using hostnamectl
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

    # NetworkManager manages dns by default, but we manage dns with e.g. ncm-resolver, new option to enable/disable it.
    $self->disable_nm_manage_dns($manage_dns, $nwsrv);

    my $dnsconfig = $self->generate_nm_resolver_config($nwtree, $manage_dns);
    $exifiles->{$NM_RESOLV_YML} = $self->nmstate_file_dump($NM_RESOLV_YML, $dnsconfig);
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
    # if nm is allowed to manage_dns, set dns-resolver: using nmstate.
    if (!$manage_dns) {
        $self->move($RESOLV_CONF_SAVE, $RESOLV_CONF_SAVE.$RESOLV_SUFFIX);
    }

    # only need to deploy config.
    my $config_changed = $self->deploy_config($exifiles);

    # Save/Restore last known working (i.e. initial) /etc/resolv.conf
    # if nm is allowed to manage dns, then this should be allowed to have changed
    # TODO: @stdweird still reverts back to orignal resolv.conf when manage_dns=true, why?
    if (!$manage_dns) {
        $resolv_conf_fh->close();
    }

    # Since there's per interface reload, interface changes will be applied via nmstatectl.
    # nmstatectl manages rollback too when options are misconfigured in yml config
    # This is still used to marke interfaces to apply any changes via nmstatectl
    # This will also down/delete any interface conection for which config was removed.
    my $stopstart += $self->nmstate_apply($exifiles, $ifup, $ifdown, $nwsrv);
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

        $self->cleanup($RESOLV_CONF.$RESOLV_SUFFIX);
        $self->cleanup($RESOLV_CONF_SAVE.$RESOLV_SUFFIX);
    }

    # remove all broken links: use file_exists
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
