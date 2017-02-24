#${PMpre} NCM::Component::OpenNebula::AII${PMpost}

use NCM::Component::OpenNebula::Server qw($ONEADMIN_USER);
use Readonly;

Readonly my $MINIMAL_ONE_VERSION => version->new("4.8.0");
Readonly my $AII_OPENNEBULA_CONFIG => "/etc/aii/opennebula.conf";
Readonly my $HOSTNAME => "/system/network/hostname";
Readonly my $DOMAINNAME => "/system/network/domainname";
Readonly my $MAXITER => 20;
Readonly my $TIMEOUT => 30;
Readonly my $ONE_DEFAULT_URL => 'http://localhost:2633/RPC2';
Readonly my $ONE_DEFAULT_PORT => 2633;
Readonly my $BOOT_V4 => [qw(network hd)];
Readonly my $BOOT_V5 => [qw(nic0 disk0)];

=head1 NAME

C<NCM::Component::OpenNebula::AII> adds C<AII> hook 
to generate the required resources and templates 
to instantiate/create/remove VMs within an C<OpenNebula> infrastructure.

=head2 AII

This section describes AII's OpenNebula hook.

=head3 SYNOPSIS

This AII hook generates the required resources and templates to instantiate/create/remove VMs within an OpenNebula infrastructure.

=head3 RESOURCES

=head4 AII setup

Set OpenNebula endpoints RPC connector /etc/aii/opennebula.conf

It must include at least one RPC endpoint and password.

To connect to a secure https endpoint for example you can set the URL endpoint and CA certificate location:

    url=https://host.example.com:2633
    ca=/etc/pki/CA/certs/mycabundle.pem

By default ONE AII uses oneadmin user and port 2633.

It is also possible to set a different endpoint for each VM domain or use a fqdn pattern
as example:

    [rpc]
    password=
    url=https://localhost/RPC2
    ca=/etc/pki/CA/certs/mycabundle.pem

    [example.com]
    password=
    user=

    [myhosts]
    pattern=myhos\d+.example.com
    password=
    url=http://example.com:2633/RPC2

=head2 Public methods

=over

=item process_template_aii

Detect and process C<OpenNebula> C<VM> templates.

=cut

sub process_template_aii
{
    my ($self, $config, $tt_name, $oneversion) = @_;

    my $tree = $config->getElement('/')->getTree();
    if ((defined $oneversion) and ($oneversion >= version->new("5.0.0"))) {
        $tree->{system}->{opennebula}->{boot} = $BOOT_V5;
        $self->verbose("BOOT section set to support OpenNebula versions >= 5.0.0");
    } else {
        $self->verbose("BOOT section set to support OpenNebula versions < 5.0.0");
        $tree->{system}->{opennebula}->{boot} = $BOOT_V4;
    };

    my $tpl = CAF::TextRender->new(
        $tt_name,
        $tree,
        relpath => 'opennebula',
        log => $self,
        );
    if (!$tpl) {
        $self->error("TT processing of $tt_name failed.", $tpl->{fail});
        return;
    }
    return "$tpl";
}

=item read_one_aii_conf

Reads a config file in C<.ini> style with a minimal RPC endpoint setup.
Returns an C<OpenNebula> instance afterwards.

=cut

sub read_one_aii_conf
{
    my ($self, $data) = @_;

    my $rpc = "rpc";

    if (! -f $AII_OPENNEBULA_CONFIG) {
        $self->error("No AII configfile $AII_OPENNEBULA_CONFIG.");
        return;
    }

    my $config = Config::Tiny->new;
    my $domainname = $data->getElement ($DOMAINNAME)->getValue;
    my $hostname = $data->getElement ($HOSTNAME)->getValue;
    my $fqdn = "$hostname.$domainname";

    $config = Config::Tiny->read($AII_OPENNEBULA_CONFIG);
    foreach my $section (sort keys %{$config}) {
        $self->verbose("Found RPC section: $section");
        my $pattern = $config->{$section}->{pattern};
        if ($pattern and $fqdn =~ /^$pattern$/ and $rpc eq 'rpc') {
            $rpc = $section;
            $self->verbose("Match pattern in RPC section: [$rpc]");
            last;
        };
    };
    if (exists($config->{$domainname}) and $rpc eq 'rpc') {
        $rpc = $domainname;
        $self->info ("Detected domainname within configfile RPC section: [$rpc]");
    };
    $config->{$rpc}->{port} //= $ONE_DEFAULT_PORT;
    my $port = $config->{$rpc}->{port};
    my $host = $config->{$rpc}->{host};
    $config->{$rpc}->{url} //= $ONE_DEFAULT_URL;
    $config->{$rpc}->{user} //= $ONEADMIN_USER;

    # Keep backwards compatibility
    if ($host) {
        $self->warn("RPC old host section detected: $host. ",
                    "Please use metaconfig to generate a proper OpenNebula aii configuration. ",
                    "ONE aii will replace the RPC url by the assigned host at this point.");
        $config->{$rpc}->{url} = "http://$host:$port/RPC2";
    };

    if (! $config->{$rpc}->{password} ) {
        $self->error("No password set in configfile $AII_OPENNEBULA_CONFIG. Section [$rpc]");
        return;
    };

    return $self->make_one($config->{$rpc});
}

=item is_supported_one_version

Detects C<OpenNebula> version.
Returns false if <OpenNebula> version is not supported.

=cut

sub is_supported_one_version
{
    my ($self, $one) = @_;

    my $oneversion = $one->version();

    if ($oneversion) {
        $self->info("Detected OpenNebula version: $oneversion");
    } else {
        $self->error("OpenNebula RPC endpoint is not reachable.");
        return;
    }

    my $res = $oneversion >= $MINIMAL_ONE_VERSION;
    if ($res) {
        $self->verbose("Version $oneversion is ok.");
        return $oneversion;
    } else {
        $self->error("Quattor component requires OpenNebula >= v$MINIMAL_ONE_VERSION (found $oneversion).");
    }
    return;
}

=item get_fqdn

Returns C<fqdn> of the VM

=cut

sub get_fqdn
{
    my ($self,$config) = @_;
    my $hostname = $config->getElement ($HOSTNAME)->getValue;
    my $domainname = $config->getElement ($DOMAINNAME)->getValue;
    return "$hostname.$domainname";
}

=item get_resource_instance

Returns ONE virtual resource instance from C<RPC>

=cut

sub get_resource_instance
{
    my ($self, $one, $resource, $name) = @_;
    my $method = "get_${resource}s";

    $method = "get_users" if ($resource eq "owner");

    my @existres = $one->$method(qr{^$name$});

    foreach my $t (@existres) {
        $self->info("Found requested $resource in ONE database: $name");
        return $t;
    };
    $self->error("Not able to find $resource name $name in ONE database");
    return;
}


=item is_timeout

Check if the resource is available
before our C<$TIMEOUT>

=cut

sub is_timeout
{
    my ($self, $one, $resource, $name) = @_;
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm $TIMEOUT;
        do {
            sleep(2);
        } while($self->is_one_resource_available($one, $resource, $name));
        alarm 0;
    };
    if ($@ eq "alarm\n") {
        $self->error("VM image deletion: $name. TIMEOUT");
    }
}

=item is_one_resource_available

Detects if the resource is already there.
Returns 1 if resource is already used, undef otherwise.

=cut

sub is_one_resource_available
{
    my ($self, $one, $type, $name) = @_;
    my $gmethod = "get_${type}s";
    my @existres = $one->$gmethod(qr{^$name$});
    if (@existres) {
        $self->info("Name: $name is already used by a $type resource.");
        return 1;
    }
    return;
}

=item aii_post_reboot

Performs C<AII> C<post_reboot>.
C<ACPID> service is mandatory for ONE VMs.

=cut

sub aii_post_reboot
{
    my ($self, $config, $path) = @_;
    my $tree = $config->getElement($path)->getTree();

    print <<EOF;
yum -c /tmp/aii/yum/yum.conf -y install acpid
service acpid start
EOF
}

=item aii_configure

Based on Quattor template this method:

=over

=item Stops running VM if necessary.

=item Creates/updates VM templates.

=item Creates new VM image for each C<$harddisks>.

=item Creates new C<VNET> C<ARs> if required.

=item Enables acpid service

=back

Rename hdx/sdx device disks by vdx to use virtio module

=cut

sub aii_configure
{
    my ($self, $config, $path) = @_;
    my $tree = $config->getElement($path)->getTree();
    my $createimage = $tree->{image};
    my $msg = '';
    $msg .= " image $createimage" if defined($createimage);
    my $createvmtemplate = $tree->{template};
    $msg .= " template $createvmtemplate" if defined($createvmtemplate);
    $self->verbose("Create VM flags:$msg") if $msg;
    my $permissions = $self->get_permissions($config);

    my $fqdn = $self->get_fqdn($config);

    # Set one endpoint RPC connector
    my $one = $self->read_one_aii_conf($config);
    if (!$one) {
        $self->error("No ONE instance returned");
        return 0;
    }

    # Check RPC endpoint and OpenNebula version
    my $oneversion = $self->is_supported_one_version($one);
    return 0 if !$oneversion;

    my %images = $self->get_images($config);
    $self->remove_or_create_vm_images($one, $createimage, \%images, $permissions);

    my %ars = $self->get_vnetars($config);
    $self->remove_and_create_vn_ars($one, \%ars);

    my $vmtemplatetxt = $self->get_vmtemplate($config, $oneversion);
    my $vmtemplate = $self->remove_or_create_vm_template($one, $fqdn, $createvmtemplate, $vmtemplatetxt, $permissions);
}

=item aii_install

Based on Quattor template this method:

=over

=item Stops current running VM.

=item Instantiates the new VM.

=back

=cut

sub aii_install
{
    my ($self, $config, $path) = @_;
    my (%opts, $vmtemplate);

    my $tree = $config->getElement($path)->getTree();

    my $instantiatevm = $tree->{vm};
    my $msg = '';
    $msg .= " instantiate $instantiatevm" if defined($instantiatevm);
    my $onhold = $tree->{onhold};
    $msg .= " onhold $onhold" if defined($onhold);
    $self->verbose("Start VM flags:$msg") if $msg;
    my $permissions = $self->get_permissions($config);

    my $fqdn = $self->get_fqdn($config);

    # Set one endpoint RPC connector
    my $one = $self->read_one_aii_conf($config);
    if (!$one) {
        $self->error("No ONE instance returned");
        return 0;
    }

    # Check RPC endpoint and OpenNebula version
    my $oneversion = $self->is_supported_one_version($one);
    return 0 if !$oneversion;

    $self->stop_and_remove_one_vms($one, $fqdn);

    my @vmtpl = $one->get_templates(qr{^$fqdn$});

    if (@vmtpl) {
        $vmtemplate = $vmtpl[0];
        $self->verbose("Found VM template from ONE database: ", $vmtemplate->name);
    } else {
        $self->error("VM template is not available to instantiate VM: $fqdn");
        return 0;
    }

    if ($instantiatevm) {
        $self->debug(1, "Instantiate vm with name $fqdn with template ", $vmtemplate->name);

        # Check that image is in READY state.
        my @myimages = $one->get_images(qr{^${fqdn}\_vd[a-z]$});
        $opts{max_iter} = $MAXITER;
        foreach my $t (@myimages) {
            # If something wrong happens set a timeout
            my $imagestate = $t->wait_for_state("READY", %opts);

            if ($imagestate) {
                $self->info("VM Image $fqdn status: READY, OK");
            } else {
                $self->error("TIMEOUT! VM image $fqdn status: ", $t->state);
                return 0;
            };
        }
        my $vmid = $vmtemplate->instantiate(name => $fqdn, onhold => $onhold);
        if (defined($vmid) && $vmid =~ m/^\d+$/) {
            $self->info("VM $fqdn was created successfully with ID: $vmid");
            if ($permissions) {
                my $newvm = $self->get_resource_instance($one, "vm", $fqdn);
                $self->change_permissions($one, "vm", $newvm, $permissions) if $newvm;
            };
        } else {
            $self->error("Unable to instantiate VM $fqdn: $vmid");
        }
    }
}

=item aii_remove

Performs VM remove wich depending on the booleans.

=over

=item Stops running VM.

=item Removes VM template.

=item Removes VM image for each C<$harddisks>.

=item Removes vnet C<ARs>.

=back

=cut

sub aii_remove
{
    my ($self, $config, $path) = @_;
    my $tree = $config->getElement($path)->getTree();
    my $stopvm = $tree->{vm};
    my $msg = '';
    $msg .= " stop $stopvm" if defined($stopvm);
    my $rmimage = $tree->{image};
    $msg .= " image $rmimage" if defined($rmimage);
    my $rmvmtemplate = $tree->{template};
    $msg .= " template $rmvmtemplate" if defined($rmvmtemplate);
    $self->verbose("Remove VM flags:$msg") if $msg;
    my $fqdn = $self->get_fqdn($config);

    # Set one endpoint RPC connector
    my $one = $self->read_one_aii_conf($config);
    if (!$one) {
        $self->error("No ONE instance returned");
        return 0;
    }

    # Check RPC endpoint and OpenNebula version
    my $oneversion = $self->is_supported_one_version($one);
    return 0 if !$oneversion;

    if ($stopvm) {
        $self->stop_and_remove_one_vms($one, $fqdn);
    }

    my $vmtemplatetxt = $self->get_vmtemplate($config, $oneversion);
    if ($vmtemplatetxt && $rmvmtemplate) {
        $self->remove_or_create_vm_template($one, $fqdn, 1, $vmtemplatetxt, undef, $rmvmtemplate);
    }

    my %images = $self->get_images($config);
    if (%images && $rmimage) {
        $self->remove_or_create_vm_images($one, undef, \%images, undef, $rmimage);
    }

    my %ars = $self->get_vnetars($config);
    if (%ars) {
        $self->remove_and_create_vn_ars($one, \%ars, $rmvmtemplate);
    }
}


=pod

=back

=cut

1;
