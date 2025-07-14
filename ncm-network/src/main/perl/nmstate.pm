#${PMpre} NCM::Component::nmstate${PMpost}

=head1 NAME

network: New module to configure networking using nmstate and NetworkManager.
Most functions and logic is taken from network module to minimise changes to current network module.

=head1 DESCRIPTION

The I<network> component sets the network settings through nmstate.
Configuration are created in yaml file at C<< /etc/nmstate >> and applied using nmstatectl.
NetworkManager acts as the main (and currently the only) provider supported by nmstate.

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
# pick a config name for nmstate yml to configure dns-resolver: settings. if manage_dns=true
Readonly my $NM_RESOLV_YML => "/etc/nmstate/resolv.yml";
Readonly my $NM_DROPIN_CFG_FILE => "/etc/NetworkManager/conf.d/90-quattor.conf";
Readonly my $NM_DEVICE_DROPIN_CFG_FILE => "/etc/NetworkManager/conf.d/89-device-quattor.conf";

# generate the correct fake yaml boolean value so TextRender can convert it in a yaml boolean
Readonly my $YTRUE => $EDG::WP4::CCM::TextRender::ELEMENT_CONVERT{yaml_boolean}->(1);
Readonly my $YFALSE => $EDG::WP4::CCM::TextRender::ELEMENT_CONVERT{yaml_boolean}->(0);

use constant IFCFG_DIR => "/etc/nmstate";
use constant BOND_MASTER_STARTS_SLAVES => 0;


sub iface_filename
{
    my ($self, $iface) = @_;
    my $filename = $self->IFCFG_DIR . "/$iface.yml";
    $self->verbose("Interface $iface configuration file: $filename");
    return $filename;
}

# Determine if this is a valid interface for ncm-network to manage,
# Return arrayref tuple [interface name, ifdown/ifup name] when valid,
# undef otherwise.
sub is_valid_interface
{
    my ($self, $filename) = @_;

    # Very primitive, based on regex only
    # matches eth0.yml bond0.yml, or bond0.101.yml
    if (
        $filename =~ m{
            # Filename is either right at the beginning or following a slash
            (?: \A | / )
            # $1 will capture for example:
            # eth0  bond1  eth0.101  bond0.102 vlan.456 or dummy_$key
            ( \w+ \d+ (?: \. \d+ )? | \w+ \. \d+ | dummy_.* )
            # Suffix (not captured)
            \. yml \z
        }x
    ) {
        # name and id for nmstate, this will make connection id and name the same.
        my $name = $1;
        # network.pm is_valid_interface supports suffix, not concerned about this in nmstate
        #    so just return name.
        return [$name, $name];
    } else {
        return;
    };
}

# By default, NetworkManager on Red Hat Enterprise Linux (RHEL) 8+ dynamically updates the /etc/resolv.conf
# file with the DNS settings from active NetworkManager connection profiles. we manage this using ncm-resolver.
# so disable this unless manage_dns = true. resolver details can be set using nmstate but not doing this now.
sub disable_nm_manage_dns
{
    my ($self, $manage_dns, $nwsrv) = @_;
    my @data = ('[main]');

    if ( $manage_dns ) {
        # set nothing, will use default.
        $self->verbose("Networkmanager defaults will be used");
    } else {
        push @data, 'dns=none';
        $self->verbose("Configuring networkmanager not to manage dns");
    }
    my $fh = CAF::FileWriter->new($NM_DROPIN_CFG_FILE, mode => oct(444), log => $self, keeps_state => 1);
    print $fh join("\n", @data, '');
    if ($fh->close()) {
        $self->info("File $NM_DROPIN_CFG_FILE changed, reload network");
        $nwsrv->reload();
    };
}

sub nm_create_device_config_dropin
{
    my ($self, $nm_device_config, $nwsrv) = @_;
    my @data = ('[device]');

    if ( $nm_device_config ) {
        foreach my $key (sort keys %$nm_device_config){
            push @data, $key."=".$nm_device_config->{$key};
        };

        $self->verbose("setting device configuration dropin");
    }
    my $fh = CAF::FileWriter->new($NM_DEVICE_DROPIN_CFG_FILE, mode => oct(444), log => $self);
    print $fh join("\n", @data, '');
    if ($fh->close()) {
        $self->info("File $NM_DEVICE_DROPIN_CFG_FILE changed, reload network");
        $nwsrv->reload();
    };
}

# return hashref of ipv4 policy rule
sub make_nm_ip_rule
{
    my ($self, $device, $rules, $routing_table_hash) = @_;

    my @rule_entry;
    my %rule_entry_absent;
    foreach my $rule (@$rules) {
        if ($rule->{command}){
            $self->warn("Rule command entry not supported with nmstate, ignoring '$rule->{command}'");
            next;
        };
        my %thisrule;
        my $priority = 100;
        $priority = $rule->{priority} if $rule->{priority};
        $thisrule{family} = "ipv4";
        $thisrule{priority} = $priority;
        $thisrule{'route-table'} = "$routing_table_hash->{$rule->{table}}" if $rule->{table};
        $thisrule{'ip-to'} = $rule->{to} if $rule->{to};
        $thisrule{'ip-from'} = $rule->{from} if $rule->{from};
        $thisrule{'action'} = $rule->{'action'} if $rule->{'action'};
        $thisrule{'state'} = $rule->{'state'} if $rule->{'state'};
        $thisrule{'iif'} = $rule->{'iif'} if $rule->{'iif'};
        $thisrule{'fwmark'} = $rule->{'fwmark'} if $rule->{'fwmark'};
        $thisrule{'fwmask'} = $rule->{'fwmask'} if $rule->{'fwmask'};
        push (@rule_entry, \%thisrule);

        # Add a default absent rule to match table defined. This will clear any existing rules for this table, instead of merging.
        if ($rule->{table}) {
           $rule_entry_absent{'state'} = "absent";
           $rule_entry_absent{'route-table'} = $routing_table_hash->{$rule->{table}};
        };
    }
    push (@rule_entry, \%rule_entry_absent) if %rule_entry_absent;
    return \@rule_entry;
}

# construct all routes found into arrayref
# return arrayref
sub make_nm_ip_route
{
    my ($self, $device, $routes, $routing_table_hash) = @_;
    my @rt_entry;
    foreach my $route (@$routes) {
        if ($route->{command}){
            # TODO: perhaps run ip add route $route->{command} ?
            # Speak to RHEL for support for unreachable route with nmstate.
            $self->warn("Route command entry not supported with nmstate, ignoring '$route->{command}'");
            next;
        };
        my %rt;
        if ($route->{address} eq 'default') {
            $self->debug(3, "Route destination is 'default', rewriting to '0.0.0.0/0'");
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
        $rt{'cwnd'} = int($route->{cwnd}) if $route->{cwnd};
        $rt{'initcwnd'} = int($route->{initcwnd}) if $route->{initcwnd};
        $rt{'initrwnd'} = int($route->{initrwnd}) if $route->{initrwnd};

        push (@rt_entry, \%rt);

    }
    return \@rt_entry;
}

# create an absent route entry.
# if you prepend the routes with the 'absent', then nmstate will clear the existing matches and apply the routes
# This will allow nmstate to clear all routes for the interface and only apply routes defined in config.
# useful when routes are changed later on in profile once host is built.
# return arrayref
sub make_nm_route_absent {
    my ($self, $device) = @_;

    my @rt_entry;
    my %rt;
    $rt{'state'} = "absent";
    $rt{'next-hop-interface'} = $device;
    push (@rt_entry, \%rt);
    return \@rt_entry;
}

# group all eth bound to a bond together in a hashref for to be used as
# - port in nmstate config file
sub get_bonded_eth
{
    my ($self, $bond_name, $interfaces) = @_;
    my @data =  ();
    foreach my $name (sort keys %$interfaces) {
        my $iface = $interfaces->{$name};
        if ( $iface->{master} ){
            push @data, $name if $iface->{master} eq $bond_name;
        }
    }
    return \@data;
}

# writes the nmstate yml file, using yaml module.
sub nmstate_file_dump
{
    my ($self, $filename, $ifaceconfig) = @_;
    # ATM interfaces hash will only have one entry per interface, so looking at first entry is fine, as long as the file isn't resolv.yml
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
                # if it's an interface file, let's check if there is a active connection.
                my $is_active = is_active_interface($self, $iface->{name});
                if (( $is_active != 1 ) && ($iface->{state}) eq "up") {
                    # if we find no active connection for the interface we are managing, let's attempt to start it.
                    # mark the interface as scheduled to be updated.
                    # this will allow nm to report issues with config on every run instead of just first run when change is made.
                    # or if someone deletes the connection.
                    # if no changes to the file, then this will never get applied again.
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

# given ip/netmask address return cidr mask length
sub get_masklen {
    my ($self, $ip_netmask) = @_;
    $self->debug(1, "Converting $ip_netmask to cidr notation");
    my $ip = NetAddr::IP->new($ip_netmask);
    return $ip->masklen;
}

# generate dummy interface config (aka loopback) for all service address vip
# return hashrefs needed by nmstate interface config
sub generate_vip_config {
    my ($self, $iface_name, $vip) = @_;
    my %dummy_iface;
    my $ip_list = {};
    my $netmask = $vip->{netmask} || "255.255.255.255";
    my $ip = $vip->{ip};
    $ip_list->{ip} = $ip;
    $ip_list->{'prefix-length'} = $self->get_masklen("$ip/$netmask");
    my $iface_cfg->{interfaces} = [{
        'profile-name' => $iface_name,
        name => $iface_name,
        type => "dummy",
        state => "up",
        ipv4 => {
            enabled => $YTRUE,
            address => [$ip_list],
        },
    }];
    return $iface_cfg;
}

# private sub to extract vlan id from name
# i.e given eth0.123 return 123
sub _get_vlan_id {
    my ($self, $name) = @_;
    return $1 if ($name =~ m/\.(\d+)$/);
}

# find vlan id from either the name or device.
# i.e eth0.123 will return 123. by checking iface name and device
# returns vlan id.
sub find_vlan_id {
    my ($self, $iface, $device) = @_;
    # a vlan interface can defined in two ways
    # interface/name.vlanid/
    # or interface/name/device=device.vlanid
    # replace everything up-to and including . to get vlan id of the interface.
    # favors ifacename.vlanid, then device.vlanid
    my $vlanid = $self->_get_vlan_id($iface);
    # if vlanid is empty here, lets check if device has vlan id.
    if ((! $vlanid) && ($device)) {
        $vlanid = $self->_get_vlan_id($device);
    }
    return $vlanid;
}

# Check if given ip belongs to a network
sub ip_in_network {
    my ($self, $check_ip, $ip, $netmask) = @_;
    # is the given ip in this ip/netmask.
    my $subnet = NetAddr::IP->new("$ip", "$netmask");
    return NetAddr::IP->new("$check_ip")->within($subnet);
}

# construct alias ip structure.
sub generate_alias_ips {
    my ($self, $alias_list) = @_;
    my $all_ip = [];
    foreach my $alias_name (sort keys %$alias_list) {
        my $ip_list = {};
        my $netmask = $alias_list->{$alias_name}->{'netmask'};
        my $ip = $alias_list->{$alias_name}->{'ip'};
        $ip_list->{ip} = $ip;
        $ip_list->{'prefix-length'} = $self->get_masklen("$ip/$netmask");
        push (@$all_ip, \%$ip_list);
    }
    return \@$all_ip;
}

sub generate_ipv6_secondaries {
    my ($self, $secondaries) = @_;
    my $ips = [];
    foreach my $secondary (@$secondaries) {
        my $ip = NetAddr::IP->new($secondary);
        if (defined($ip)) {
            my $ip_list = {};
            $ip_list->{ip} = $ip->addr;
            $ip_list->{'prefix-length'} = $ip->masklen;
            push @$ips, $ip_list;
        }
    }
    return \@$ips;
}

# generates the hashrefs for interface in yaml file format needed by nmstate.
# bulk of the config settings needed by the nmstate yml is done here.
# to add additional options, it should be constructed here.
sub generate_nmstate_config
{
    my ($self, $name, $net, $ipv6, $routing_table, $default_gw) = @_;

    my $iface = $net->{interfaces}->{$name};
    my $device = $iface->{device} || $name;
    my $is_eth = $iface->{hwaddr} ? 1 : 0;
    my $eth_bootproto = $iface->{bootproto} || 'static';
    my $is_ip = exists $iface->{ip} ? 1 : 0;
    my $is_vlan_eth = exists $iface->{vlan} ? 1 : 0;
    my $is_partof_bond = exists $iface->{master} ? 1 : 0;
    my $can_ignore_bootproto = $is_partof_bond;
    my $iface_changed = 0;

    # create hash of interface entries that will be used by nmstate config.
    my $ifaceconfig = {
        name => $name,
        'profile-name' => $name,
    };

    $ifaceconfig->{mtu} = $iface->{mtu} if $iface->{mtu};
    $ifaceconfig->{'mac-address'} = $iface->{hwaddr} if $iface->{hwaddr};

    # this will be empty if the interface isnt a bond interface.
    # we can use this to determine if this interface is bond interface.
    my $bonded_eth = get_bonded_eth($self, $name, $net->{interfaces});

    my $vlan_id = $self->find_vlan_id($name, $iface->{device});

    my $lctype = lc($iface->{type} || '');

    if ($lctype eq 'infiniband') {
        $ifaceconfig->{type} = "infiniband";
        my $ib = {};
        my $pkey = $vlan_id || 65535;
        if ($vlan_id) {
            my $ibdev = $name;
            $ibdev =~ s/\.\d+$//;
            $ib->{'base-iface'} = $ibdev;
        };
        $ib->{pkey} = "0x" . sprintf("%04x", $pkey);
        $ib->{mode} = 'datagram';  # TODO: add connected mode, but who still uses that
        $ifaceconfig->{infiniband} = $ib;
    } elsif ($lctype eq 'ovsbridge') {
        $can_ignore_bootproto ||= 1;
        $ifaceconfig->{type} = "ovs-bridge";
        $ifaceconfig->{state} = "up";
        $ifaceconfig->{bridge}->{port} = [ map { {name => $_} } (@{$iface->{ports}}, $name) ];
    } elsif ($lctype eq 'ovsintport') {
        $can_ignore_bootproto ||= 1;
        # TODO: when extending this to ovsport, deal with eg type=ovsport driver=bonding
        #    (which is a bond interface and should not be handled here)
        $ifaceconfig->{type} = "ovs-interface";
        $ifaceconfig->{state} = "up";
    } elsif ($is_eth) {
        $ifaceconfig->{type} = "ethernet";
        if ($is_partof_bond) {
            # no ipv4 address for bonded eth, plus in nmstate bonded eth is controlled by controller. no config is required.
            $ifaceconfig->{ipv4}->{enabled} = $YFALSE;
            $ifaceconfig->{state} = "up";
        }
    } elsif ($is_vlan_eth) {
        # if vlan_id is empty, error
        if (! $vlan_id) {
            $self->error("Could not find vlan id for vlan device $name");
        }
        $ifaceconfig->{type} = "vlan";
        $ifaceconfig->{vlan}->{'base-iface'} = $iface->{physdev};
        $ifaceconfig->{vlan}->{'id'} = $vlan_id;
    } elsif (@$bonded_eth) {
        # if bond device
        $can_ignore_bootproto ||= 1;
        $ifaceconfig->{type} = "bond";
        $ifaceconfig->{state} = "up";
        $ifaceconfig->{'link-aggregation'} = $iface->{link_aggregation};
        if ($bonded_eth){
            $ifaceconfig->{'link-aggregation'}->{port} = $bonded_eth;
        }
    }

    if ($eth_bootproto eq 'static') {
        $ifaceconfig->{state} = "up";
        if ($is_ip || $iface->{ipv6addr}) {
            # If primary IPv4 or primary IPv6 is defined. We allow configuration
            # with IPv4 & IPv6 on same interface but also IPv6 only interface.
            # if device has manual ip assigned
            my $ip_list = {};
            my $all_ip = [];
            # IPv4 configuration
            if ($is_ip) {
                if ($iface->{netmask}) {
                    my $ip = NetAddr::IP->new($iface->{ip} . "/" . $iface->{netmask});
                    $ip_list->{ip} = $ip->addr;
                    $ip_list->{'prefix-length'} = $ip->masklen;
                } else {
                    $self->error("$name with (IPv4) ip and no netmask configured");
                }
                push @$all_ip, $ip_list if scalar $ip_list;
                if ($iface->{aliases}) {
                    # if device has additional alias ipv4 addresses defined. add them to config
                    $self->verbose("alias ip (ipv4) addr defined for $name, configuring additional ips");
                    push @$all_ip, @{$self->generate_alias_ips($iface->{aliases})};
                }
            $ifaceconfig->{ipv4}->{address} = $all_ip;
                $ifaceconfig->{ipv4}->{dhcp} = $YFALSE;
                $ifaceconfig->{ipv4}->{enabled} = $YTRUE;
            }
            # IPv6 configuration
            if ($iface->{ipv6addr}) {
                $ifaceconfig->{ipv6}->{enabled} = $YFALSE;
                my $ip_list = {};
                my $ip = NetAddr::IP->new($iface->{ipv6addr});
                if (defined($ip)) {
                    my $ips = [];
                    $ip_list->{ip} = $ip->addr;
                    $ip_list->{'prefix-length'} = $ip->masklen;
                    push @$ips, $ip_list;

                    if ($iface->{ipv6addr_secondaries}) {
                        # If interface has additional ipv6 addresses defined, add them
                        $self->verbose("additional ip (ipv6) addr defined for $name, configuring additional ips");
                        push @$ips, @{$self->generate_ipv6_secondaries($iface->{ipv6addr_secondaries})};
                    }

                    $ifaceconfig->{ipv6}->{address} = $ips;
                    $ifaceconfig->{ipv6}->{enabled} = $YTRUE;
                } else {
                    $self->error($iface->{ipv6addr}." invalid format")
                }
            }
        } else {
            $self->error("No ip address defined for static bootproto");
        }
    } elsif (($eth_bootproto eq "dhcp") && (!$can_ignore_bootproto)) {
        # dhcp configuration
        $ifaceconfig->{state} = "up";
        $ifaceconfig->{ipv4}->{dhcp} = $YTRUE;
        $ifaceconfig->{ipv4}->{enabled} = $YTRUE;
    } elsif (($eth_bootproto eq "none") && (!$can_ignore_bootproto)) {
        # no ip on interface and is not a part of a bonded interface, assume not managed so disable eth.
        $ifaceconfig->{ipv4}->{enabled} = $YFALSE;
        $ifaceconfig->{ipv6}->{enabled} = $YFALSE;
        $ifaceconfig->{state} = "down";
    } elsif ($eth_bootproto eq "bootp"){
        $self->error("bootp bootproto not supported by nmstate");
    }

    # create default route entry.
    my %default_rt;
    if ($default_gw) {
        # create default gw entry on this interface only if it falls within the subnet boundary.
        # otherwise this interface is not the default gw interface.
        # next-hop-interface is mandatory in nmstate therefore we need interface to create default route entry.
        if ((defined($iface->{ip})) and (defined($iface->{netmask}))) {
            my $is_dgw_iface = $self->ip_in_network($default_gw, $iface->{ip}, $iface->{netmask});
            if ($is_dgw_iface) {
                $self->debug(3, "Adding the default IPv4 gateway to interface '$name'");
                $default_rt{destination} = '0.0.0.0/0';
                $default_rt{'next-hop-address'} = $default_gw;
                $default_rt{'next-hop-interface'} = $name;
            }
        }
    }

    my %default_ipv6_rt;
    if ($ipv6) {
        if (defined($iface->{ipv6addr})) {
            my $ip6 = NetAddr::IP->new($iface->{ipv6addr});
            my $is_ipv6gw_iface = NetAddr::IP->new($ipv6->{default_gateway}."/128")->within($ip6);
            if ($is_ipv6gw_iface) {
                $self->debug(3, "Adding the default IPv6 gateway to interface '$name'");
                $default_ipv6_rt{destination} = '::/0';
                $default_ipv6_rt{'next-hop-address'} = $ipv6->{default_gateway};
                $default_ipv6_rt{'next-hop-interface'} = $name;
            }
        }
    }
    # combined default route with any policy routing/rule, if any
    # combination of default route, plus any additional policy routes.
    # read and set by tt module as
    # routes:
    #   config:
    #   - destination:
    #     next-hop-address:
    #     next-hop-interface:
    #  and so on.
    my $routes = [];
    push @$routes, @{$self->make_nm_route_absent($name)};
    push @$routes, \%default_rt if scalar %default_rt;
    push @$routes, \%default_ipv6_rt if scalar %default_ipv6_rt;
    if (defined($iface->{route})) {
        $self->verbose("policy route found, nmstate will manage it");
        my $route = $iface->{route};
        my $policyroutes = $self->make_nm_ip_route($name, $route, $routing_table);
        push @$routes, @{$policyroutes};
    }

    my $policy_rule = [];
    if (defined($iface->{rule})) {
        my $rule = $iface->{rule};
        $policy_rule = $self->make_nm_ip_rule($iface, $rule, $routing_table);
        $self->verbose("policy rule found, nmstate will manage it");
    }
    # return hash construct that will match what nmstate yml needs.
    my $interface->{interfaces} = [$ifaceconfig];

    # insert 2nd interface: an ovs-interface with same name (a so-called admin interafce)
    if (($ifaceconfig->{type} || '') eq 'ovs-bridge') {
        push(@{$interface->{interfaces}}, {
            type => "ovs-interface",
            state => "up",
            name => $name,
            'profile-name' => $name,
            ipv4 => {
                enabled => $YFALSE,
            },
            ipv6 => {
                enabled => $YFALSE,
            },
        });
    };

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

    return $interface, $ifaceconfig;
};

# Generate hash of dns-resolver config for nmstate.
# only used if manage_dns = true.
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
    my @cmds;
    push(@cmds, ["systemctl", "enable", "NetworkManager"]);
    # adding to start the service here will mean it does this every ncm run, we don't really want this.
    # NetworkManager is started by default on el7+, but if it doesn't do this one off in ks post perhaps?
    return $self->runrun(@cmds);
}

# keep nmstate service disabled (vendor preset anyway), we will apply config ncm component.
# nmstate service applies all files found in /etc/nmstate and changes to .applied, which will keep changing if component is managing the .yml file.
# we don't need this, as this component will manage it.
#
sub disable_nmstate_service
{
    my ($self) = @_;
    # vendor preset anyway
    my @cmds;
    push(@cmds, ["systemctl", "disable", "nmstate"]);
    push(@cmds, ["systemctl", "stop", "nmstate"]);
    return $self->runrun(@cmds);
}

# check to see if we have active connection for interface we manage.
# this is to allow ability to start a connection again if last config run failed on nmstate apply.
sub is_active_interface
{
    my ($self, $ifacename) = @_;
    my $output = $self->runrun([$NMCLI_CMD, "-t", "-f", "name,device", "conn", "show", "--active"]);
    # output returned by nmcli -t is colon separated
    # i.e eth0:eth0
    my @existing_conn = split('\n', $output);
    my $found = 0;
    foreach my $conn_name (@existing_conn) {
        my ($name, $dev) = split(':', $conn_name);
        if ("$dev" eq "$ifacename") {
            # ncm-network will set connection same as interface name, if this doesn't match,
            # it means this connection existed before nmstate did its first apply.
            # doesn't break anything as nmstate resuses the conn, but worth a warning to highlight it?
            if ("$name" ne "$ifacename"){
                $self->warn("connection name '$name' doesn't match $ifacename for device $dev, possible connection reuse occured. $output");
            }
            $found = 1;
            return $found ;
        };
    }
    return $found;
}

# check for existing connections, any connections which are not active.
# good to have.
sub clear_inactive_nm_connections
{
    my ($self) = @_;
    # clean any inactive connections
    my $output = $self->runrun([$NMCLI_CMD, "-t", "-f", "uuid,device,name,state,active", "conn"]);
    my @all_conn = split('\n', $output);
    foreach  my $conn  (@all_conn) {
        my ($uuid,$device,$name,$state,$active) = split(':', $conn);
        if ($active eq 'no') {
           $self->verbose("Clearing inactive connection for [ uuid=$uuid, name=$name, state=$state, active=$active ]");
           $output = $self->runrun([$NMCLI_CMD,"conn", "delete", $uuid]);
            $self->verbose($output);
        }
    }
}

# return ordered list of interface keys
#    if_updwon is a hasref in if_up / if_down format
sub nmstate_order
{
    my ($self, $if_updown, $full_ifaces) = @_;

    # do no use the value 0 in the score; it will break the || $default logic when the value is 0
    my $default = 10;  # lowest / first
    # these are nmstate types
    my $score = {
        bond => 20,  # slaves need to be alive
        "ovs-interface" => 30,  # can only be ports of a bridge, this could probably be 0 as well
        "ovs-bridge" => 40,  # needs ports alive; these can be anything with lower score
    };

    my $get_score = sub {
        my $ifname = shift;

        # devices to remove most likely have no data
        my $guesstype = 'unknown';
        $guesstype = 'bond' if $ifname =~ m/^bond/;

        my $ifdata = $full_ifaces->{$ifname} || {};
        return $score->{$ifdata->{type} || $guesstype} || $default;
    };

    # sort on score, and with equal score alphabetic
    my @sorted_ifnames = sort {
        &$get_score($a) <=> &$get_score($b) || $a cmp $b
    } keys %$if_updown;

    # re-apply the ovs-interfaces, an all-in-one config yaml would solve this
    my @reapply = grep { &$get_score($_) == 30 } @sorted_ifnames;

    return @sorted_ifnames, @reapply;
}


sub nmstate_apply
{
    my ($self, $exifiles, $ifup, $ifdown, $nwsrv, $ifaces) = @_;


    my @ifaces = $self->nmstate_order($ifup, $ifaces);
    my @ifaces_down = reverse $self->nmstate_order($ifdown, $ifaces);

    my $action;

    if (@ifaces) {
        $self->info("Applying changes using $NMSTATECTL ", join(', ', @ifaces));
        my @cmds;
        foreach my $iface (@ifaces) {
            # apply config using nmstatectl
            my $ymlfile = $self->iface_filename($iface);
            if ($self->any_exists($ymlfile)){
                push(@cmds, [$NMSTATECTL, "apply", $ymlfile]);
                push(@cmds, [qw(/usr/bin/sleep 10)]) if ($iface =~ m/^bond/);
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
    # this will exist at this stage if manage_dns is set to true.
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
    my $net = $self->process_network($config);
    my $ifaces = $net->{interfaces};

    # keep a hash of all files and links.
    # makes a backup of all files
    my ($exifiles, $exilinks) = $self->gather_existing();
    return if ! defined($exifiles);

    my $comp_tree = $config->getTree($self->prefix());
    my $nwtree = $config->getTree($NETWORK_PATH);

    my $hostname = $nwtree->{realhostname} || "$nwtree->{hostname}.$nwtree->{domainname}";
    my $manage_dns = $nwtree->{manage_dns} || 0;
    my $dgw = $nwtree->{default_gateway};
    if (!$dgw) {
        $self->warn ("No default gateway configured");
    }
    # The original, assumed to be working resolv.conf
    # Using an FileEditor: it will read the current content, so we can do a close later to save it
    # in case something changed it behind our back. Only if NM is not set to manage dns.
    my $resolv_conf_fh = CAF::FileEditor->new($RESOLV_CONF, backup => $RESOLV_SUFFIX, log => $self);
    if (!$manage_dns) {
        # Need to reset the original content (otherwise the close will not check the possibly updated content on disk)
        *$resolv_conf_fh->{original_content} = undef;
    }

    # create routing tables if defined.
    $self->routing_table($nwtree->{routing_table});

    my $ipv6 = $nwtree->{ipv6};
    my $nmifaces = {};
    foreach my $ifacename (sort keys %$ifaces) {
        my $iface = $ifaces->{$ifacename};
        my ($nm_cfg, $nm_iface) = generate_nmstate_config($self, $ifacename, $net, $ipv6, $nwtree->{routing_table}, $dgw);
        $nmifaces->{$ifacename} = $nm_iface;
        my $file_name = $self->iface_filename($ifacename);
        $exifiles->{$file_name} = $self->nmstate_file_dump($file_name, $nm_cfg);

        $self->ethtool_opts_keeps_state($file_name, $ifacename, $iface, $exifiles);
    }

    # configure vips defined under path /system/network/vips/ as dummy interface
    # only if manage_vips is set to true.
    if ($net->{manage_vips} && defined($net->{vips})) {
        $self->verbose("Service address vips found, configuring dummy interfaces");
        my $vips = $net->{vips};
        foreach my $name (sort keys %$vips) {
            my $dummy_name = "dummy_$name";
            my $nmstate_dummy_cfg = $self->generate_vip_config($dummy_name, $vips->{$name});
            my $dummy_filename = $self->iface_filename($dummy_name);
            $exifiles->{$dummy_filename} = $self->nmstate_file_dump($dummy_filename, $nmstate_dummy_cfg);
        }
    };

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

    # TODO: openvswitch configs for nmstate. Commented out for now.
    # $self->start_openvswitch($ifaces, $ifup);

    # TODO: This can be set with nmstate config but we doing the traditional way using hostnamectl
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
    #   1. stop everything using old config
    #   2. replace updated/new config; remove REMOVE
    #   3. (re)start things
    my $nwsrv = CAF::Service->new(['NetworkManager'], log => $self);

    # NetworkManager device configuration, if defined.
    my $nm_device_cfg = $nwtree->{device_config};
    if ($nm_device_cfg){
        $self->nm_create_device_config_dropin($nm_device_cfg, $nwsrv);
    } else {
        $self->cleanup($NM_DEVICE_DROPIN_CFG_FILE);
    }

    # NetworkManager manages dns by default, but we manage dns with e.g. ncm-resolver, new option to enable/disable it.
    $self->disable_nm_manage_dns($manage_dns, $nwsrv);

    my $dnsconfig = $self->generate_nm_resolver_config($nwtree, $manage_dns);
    $exifiles->{$NM_RESOLV_YML} = $self->nmstate_file_dump($NM_RESOLV_YML, $dnsconfig);
    # nmstate files are applied uinsg nmstate apply via this component. We don't want nmstate svc to manage it.
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
    if (!$manage_dns) {
        $resolv_conf_fh->close();
    }

    # Since there's per interface reload, interface changes will be applied via nmstatectl.
    # nmstatectl manages rollback too when options are misconfigured in yml config
    # This is still used to mark interfaces to apply any changes via nmstatectl
    # This will also down/delete any interface connection for which config was removed.
    my $stopstart += $self->nmstate_apply($exifiles, $ifup, $ifdown, $nwsrv, $nmifaces);
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

    # cleanup dangling inactive connections after ncm network changes are applied.
    # defaults to cleanup
    my $clean_inactive_conn = $net->{clean_inactive_conn};
    if ($clean_inactive_conn and $stopstart) {
        # look to cleanup connections only when something is changed.
        $self->clear_inactive_nm_connections;
    }

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
                $self->debug(1, "Successfully cleaned up broken symlink $link");
            } else {
                $self->error("Failed to unlink broken symlink $link: $self->{fail}");
            };
        }
    };

    return 1;
}

1;
