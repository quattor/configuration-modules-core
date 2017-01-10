# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::opennebula;

=head1 NAME

ncm-${project.artifactId}: Configuration module for OpenNebula

=head1 DESCRIPTION

ncm-opennebula provides support for OpenNebula configuration for:

=over

=item server: setup OpenNebula server and hypervisors

=item AII: add VM management support with OpenNebula

=back

=head2 server

Features that are implemented at this moment:

=over

=item * oned service configuration

=item * Sunstone service configuration

=item * OneFlow service configuration

=item * Adding/removing VNETs

=item * Adding/removing datastores (only Ceph and shared datastores for the moment)

=item * Adding/removing hypervirsors

=item * Adding/removing OpenNebula regular users

=item * Adding/removing OpenNebula groups

=item * Assign OpenNebula users to primary groups

=item * Updates OpenNebula C<< *_auth >> files

=item * Updates VMM kvmrc config file

=item * Cloud resource labels (OpenNebula >= 5.x)

=back

OpenNebula installation is 100% automated. Therefore:

=over

=item * All the new OpenNebula templates created by the component will include a QUATTOR flag.

=item * The component only will modify/remove resources with the QUATTOR flag set, otherwise the resource is ignored.

=item * If the component finds any issue during hypervisor host configuration then the node is included within OpenNebula infrastructure but as disabled host.

=back

=head3 INITIAL CREATION

=over

=item The schema details are annotated in the schema file.

=item Example pan files are included in the examples folder and also in the test folders.

=back

To set up the initial cluster, some steps should be taken:

=over

=item 1. First install the required Ruby gems in your OpenNebula server.
You can use OpenNebula installgems addon : L<https://github.com/OpenNebula/addon-installgems>.

=item 2. The OpenNebula server(s) should have passwordless ssh access as oneadmin user to all the hypervisor hosts of the cluster.
 e.g. by distributing the public key(s) of the OpenNebula host over the cluster.

=item 3. Start OpenNebula services: C<< # for i in '' -econe -gate -novnc -occi -sunstone; do service opennebula$i stop; done >>

=item 4. Run the component a first time.

=item 5. The new oneadmin password will be available from C<< /var/lib/one/.one/one_auth >> file.
The old auth files are stored with .quattor.backup extension.

=item 6. It is also possible to change sunstone service password, just include
'serveradmin' user and passwd within opennebula/users tree.
In that case the component also updates the C<< sunstone_auth >> file.

=back

=head3 RESOURCES

=head4 /software/components/${project.artifactId}

The configuration information for the component.  Each field should
be described in this section.

=over 4

=item * ssh_multiplex : boolean

Set ssh multiplex options

=item * cfg_group : string

In some cases (such a Sunstone standalone conf with apache), some ONE conf files should be accessible by a different group (as apache).
This variable sets the group name to change these files permissions.

=item * host_hyp : string

Set host hypervisor type

=over 5

=item * kvm

Set KVM hypervisor

=item * xen

Set XEN hypervisor

=back

=item * host_ovs : boolean (optional)

Includes the Open vSwitch network drives in your hypervisors. (OVS must be installed in each host)
Open vSwitch replaces Linux bridges, Linux bridges must be disabled.
More info: L<http://docs.opennebula.org/4.14/administration/networking/openvswitch.html>

=item * tm_system_ds : string (optional)

Set system datastore TM_MAD value (shared by default). Valid values:

=over 5

=item * shared

The storage area for the system datastore is a shared directory across the hosts.

=item * vmfs

A specialized version of the shared one to use the vmfs file system.

=item * ssh

Uses a local storage area from each host for the system datastore.

=back

=back

=head2 AII

This document describes AII's OpenNebula hook.

=head3 SYNOPSIS

This AII hook generates the required resources and templates to instantiate/create/remove VMs within an OpenNebula infrastructure.

=head3 RESOURCES

=head4 AII setup

Set OpenNebula endpoints RPC connector /etc/aii/opennebula.conf

It must include at least one RPC endpoint and password.

To set an https endpoint for example you can use:
 url=https://host.example.com:2633

By default ONE AII uses oneadmin user and port 2633.

It is also possible to set a different endpoint for each VM domain or use a fqdn pattern
as example:

    [rpc]
    password=
    url=https://localhost/RPC2

    [example.com]
    password=
    user=

    [myhosts]
    pattern=myhos\d+.example.com
    password=
    url=http://example.com:2633/RPC2

=head4 configure

Generates VM images, generates/updates VM templates and AR Virtual Networks. 
Modify your machine template to:

=over 4

=item * Rename hdx/sdx device disks by vdx to use virtio module

=item * Create or include a new pan file to:

=over 5

=item * Include 'metaconfig/opennebula/schema'

=item * Set the OpenNebula opennebula/datastore name for each vdx

=item * Set the VNETs opennebula/vnet (bridges) required by each VM network interface

=item * (Optional) Set /system/opennebula/ignoremac tree to avoid to include MAC values within AR/VM templates

=item * (Optional) Set /system/opennebula/graphics to export VM graphical display (VNC is used by default)

=item * (Optional) Set /system/opennebula/labels list to include OpenNebula search labels

=item * (Optional) Set /system/opennebula/pci list values to enable PCI Passthrough

=over 6

=item * PCI Passthrough section is also generated based on hardware/cards/<card_type>/<interface>/pci values

=back

=item * (Optional) Set /system/opennebula/diskcache to select the cache mechanism for your disks. (by default is set to none)

=item * (Optional) Set OPENNEBULA_AII_REPLACE_MAC and MAC_PREFIX variables to replace VM MACs to use OpenNebula style

=back

=item * enable acpid service

=back

The next paths are relative to /system/aii/hooks/configure

=over 4

=item * image : boolean

Create VM images. Note: VM images are not updated, if you want to resize or modify an available image from scratch use remove hook first.

=item * template : boolean

Create VM template.

=back

=head4 install

Instantiates the required VM. 
The next paths are relative to /system/aii/hooks/install

=over 4

=item * vm : boolean

The new VM is instantiated after resources creation

=item * onhold : boolean

The VM is instantiated but onhold status instead of running

=back

=head4 remove

Removes the VM resources (template/images/network). 
All these paths are relative to /system/aii/hooks/remove

=over 4

=item * vm : boolean

Stop running VM

=item * image : boolean

Remove image/s

=item * template : boolean

Remove VM templates

=back

=head1 DEPENDENCIES

The component was tested with OpenNebula version 4.1x and 5.x

Following package dependencies should be installed to run the component:

=over

=item * aii-ks

=item * perl-Config-Tiny

=item * perl-LC

=item * perl-CAF

=item * perl-Set-Scalar

=item * perl-Net-OpenNebula >= 0.2.2 !

=back

=head1 METHODS

=cut

use strict;
use warnings;
use version;
use base qw(NCM::Component);
use NCM::Component;
use NCM::Component::OpenNebula::commands;
use NCM::Component::OpenNebula::Host;
use NCM::Component::OpenNebula::Server;
use NCM::Component::OpenNebula::Account;
use NCM::Component::OpenNebula::Network;
use NCM::Component::OpenNebula::VM;
use NCM::Component::OpenNebula::Image;
use vars qw(@ISA $EC);
use LC::Exception;
use CAF::TextRender;
use CAF::FileReader;
use CAF::Service;
use Set::Scalar;
use Config::Tiny;
use Net::OpenNebula 0.309.0;
use Data::Dumper;
use Readonly;
use 5.10.1;

Readonly my $CORE_AUTH_DRIVER => "core";
Readonly my $MINIMAL_ONE_VERSION => version->new("4.8.0");
Readonly our $ONED_CONF_FILE => "/etc/one/oned.conf";
Readonly our $SUNSTONE_CONF_FILE => "/etc/one/sunstone-server.conf";
Readonly our $ONEFLOW_CONF_FILE => "/etc/one/oneflow-server.conf";
Readonly our $SERVERADMIN_USER => "serveradmin";
Readonly our $ONEADMIN_USER => "oneadmin";
Readonly my $AII_OPENNEBULA_CONFIG => "/etc/aii/opennebula.conf";
Readonly my $HOSTNAME => "/system/network/hostname";
Readonly my $DOMAINNAME => "/system/network/domainname";
Readonly my $MAXITER => 20;
Readonly my $TIMEOUT => 30;
Readonly my $ONE_DEFAULT_URL => 'http://localhost:2633/RPC2';
Readonly my $ONE_DEFAULT_PORT => 2633;
Readonly my $BOOT_V4 => [qw(network hd)];
Readonly my $BOOT_V5 => [qw(nic0 disk0)];

# Required by process_template to detect 
# if it should return a text template or
# CAF::FileWriter instance
Readonly::Array my @FILEWRITER_TEMPLATES => qw(oned one_auth kvmrc sunstone remoteconf_ceph oneflow);


our $EC=LC::Exception::Context->new->will_store_all;

=head2 make_one

Sets C<OpenNebula> C<RPC> endpoint info to connect to ONE API.

=cut

sub make_one 
{
    my ($self, $rpc) = @_;

    if (! $rpc->{password} ) {
        $self->error("No RPC ONE password set!");
        return;
    }

    $self->verbose("Connecting to host $rpc->{host}:$rpc->{port} as user $rpc->{user} (with password)");

    $rpc->{url} = $rpc->{url} || "http://$rpc->{host}:$rpc->{port}/RPC2";

    my $one = Net::OpenNebula->new(
        url      => $rpc->{url},
        user     => $rpc->{user},
        password => $rpc->{password},
        log => $self,
        fail_on_rpc_fail => 0,
    );
    return $one;
}

=head2 process_template

Detect and process ONE templates.
It could return a C<CAF::TextRender> instance or a plain text template for ONE C<RPC>.

=cut

sub process_template
{
    my ($self, $config, $type_name, $secret) = @_;

    my $type_rel = "$type_name.tt";
    my $tpl = CAF::TextRender->new(
        $type_name,
        { $type_name => $config },
        relpath => 'opennebula',
        log => $secret ? undef : $self,
        );
    if (!$tpl) {
        $self->error("TT processing of $type_rel failed: $tpl->{fail}");
        return;
    }

    if (grep { $type_name eq $_ } @FILEWRITER_TEMPLATES) {
        return $tpl;
    } else {
        return "$tpl";
    };
}

# FROM AII
# Detect and process ONE templates
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

    # TBD process_template refactoring
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

=head2 create_or_update_something

Creates/updates ONE resources based on resource type.

=cut

sub create_or_update_something
{
    my ($self, $one, $type, $data, %protected) = @_;
    
    my $template = $self->process_template($data, $type);
    my ($name, $new);
    if (!$template) {
        $self->error("No template data found for $type.");
        return;
    }
    if ($template =~ m/^NAME\s+=\s+(?:"|')(.*?)(?:"|')\s*$/m) {
        $name = $1;
        $self->verbose("Found template NAME: $name within $type resource.");
    } else {
        $self->error("Template NAME tag not found within $type resource: $template");
        return;
    }
    if (exists($protected{$name})) {
        $self->info("This resource $type is protected and can not be created/updated: $name");
        return;
    }
    my $cmethod = "create_$type";

    my $used = $self->detect_used_resource($one, $type, $name);
    if (!$used) {
        $self->info("Creating new $name $type resource.");
        $new = $one->$cmethod("$template");
    } elsif ($used == -1) {
        # resource is already there and we can modify it
        $new = $self->update_something($one, $type, $name, $template, $data);
    }
    return $new;
}

=head2 remove_something

Removes C<OpenNebula> resources.

=cut

sub remove_something
{
    my ($self, $one, $type, $resources, %protected) = @_;
    my $method = "get_${type}s";
    my @existres = $one->$method();
    my @namelist = $self->create_resource_names_list($resources);
    my %rnames = map { $_ => 1 } @namelist;

    foreach my $oldresource (@existres) {
        # Remove the resource only if the QUATTOR flag is set
        my $quattor = $self->check_quattor_tag($oldresource);
        if (exists($protected{$oldresource->name})) {
            $self->info("This resource $type is protected and can not be removed: ", $oldresource->name);
        } elsif ($quattor and !$oldresource->used() and !exists($rnames{$oldresource->name})) {
            $self->info("Removing old $type resource: ", $oldresource->name);
            my $id = $oldresource->delete();
            if (!$id) {
                $self->error("Unable to remove old $type resource: ", $oldresource->name);
            }
        } else {
            $self->debug(1, "QUATTOR flag not found or the resource is still used. ",
                        "We can't remove this $type resource: ", $oldresource->name);
        };
    }
    return;
}



=head2 update_something

Updates C<OpenNebula> resource templates.

=cut

sub update_something
{
    my ($self, $one, $type, $name, $template, $data) = @_;
    my $method = "get_${type}s";
    my $update;
    my @existres = $one->$method(qr{^$name$});
    foreach my $t (@existres) {
        # $merge=1, we don't replace, just merge the new templ
        $self->info("Updating old $type Quattor resource with a new template: ", $name);
        $self->debug(1, "New $name template : $template");
        $update = $t->update($template, 1);
        if ($type eq "vnet" && defined($data->{$name}->{ar})) {
            $self->update_vn_ar($one, $name, $template, $t, $data);
        }
    }
    return $update;
}


=head2 detect_used_resource

Detects if the resource is already there and if quattor flag is present.

=over

=item Returns undef: resource not used yet.

=item Returns 1: resource already used without Quattor flag.

=item Returns -1: resource already used with Quattor flag set

=back

=cut

sub detect_used_resource
{
    my ($self, $one, $type, $name) = @_;
    my $quattor;
    my $gmethod = "get_${type}s";
    my @existres = $one->$gmethod(qr{^$name$});
    if (@existres) {
        $quattor = $self->check_quattor_tag($existres[0]);
        if (!$quattor) {
            $self->verbose("Name: $name is already used by a $type resource. ",
                        "The Quattor flag is not set. ",
                        "We can't modify this resource.");
            return 1;
        } elsif ($quattor == 1) {
            $self->verbose("Name : $name is already used by a $type resource. ",
                        "Quattor flag is set. ",
                        "We can modify and update this resource.");
            return -1;
        }
    } else {
        $self->verbose("Name: $name is not used by $type resource yet.");
        return;
    }
}

sub create_resource_names_list
{
    my ($self, $resources) = @_;
    my @namelist;

    foreach my $resourcename (sort keys %{$resources}) {
        push(@namelist, $resourcename);
    };
    return @namelist;
}

sub check_quattor_tag
{
    my ($self, $resource, $user) = @_;

    if ($user and $resource->{data}->{TEMPLATE}->[0]->{QUATTOR}->[0]) {
        return 1;
    }
    elsif (!$user and $resource->{extended_data}->{TEMPLATE}->[0]->{QUATTOR}->[0]) {
        return 1;
    } else {
        return;
    }
}

# Remove/add ONE resources
# based on resource type
sub manage_something
{
    my ($self, $one, $type, $resources, $untouchables) = @_;
    my %protected = map { $_ => 1 } @$untouchables;
    if (!$resources) {
        $self->info("No $type resources found.");
        return;
    } else {
        $self->verbose("Managing $type resources.");
    }

    if (($type eq "kvm") or ($type eq "xen")) {
        $self->manage_hosts($one, $type, $resources, %protected);
        return;
    } elsif (($type eq "user") or ($type eq "group")) {
        $self->manage_users_groups($one, $type, $resources, %protected);
        return;
    }

    $self->verbose("Check to remove ${type}s");
    $self->remove_something($one, $type, $resources, %protected);

    $self->info("Creating new ${type}s: ", join(', ', keys %{$resources}));
    foreach my $newresource (sort keys %{$resources}) {
        my %temp;
        $temp{$newresource}->{$newresource} = $resources->{$newresource};
        my $new = $self->create_or_update_something($one, $type, $temp{$newresource}, %protected);
    };
}


# Return resource ids
sub get_resource_id
{
    my ($self, $one, $type, $name) = @_;
    my $getmethod = "get_${type}s";

    my @existres = $one->$getmethod(qr{^$name$});
    foreach my $resource (@existres) {
        $self->verbose("Detected $type id: ", $resource->id);
        return $resource->id;
    }
    return;
}

=head2 is_supported_one_version

Checks ONE and detects ONE version.
Returns false if ONE version is not supported.

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

    my $res= $oneversion >= $MINIMAL_ONE_VERSION;
    if ($res) {
        $self->verbose("Version $oneversion is ok.");
        return $oneversion;
    } else {
        $self->error("Quattor requires ONE v$MINIMAL_ONE_VERSION or higher (found $oneversion).");
    }
    return;
}


=head2 Configure

Configure basic OpenNebula server resources.

=cut

sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/opennebula";
    my $tree = $config->getElement($base)->getTree();

    my $cfggrp = $self->set_config_group($tree);
    # Set oned.conf
    if (exists $tree->{oned}) {
        $self->set_one_service_conf($tree->{oned}, "oned", $ONED_CONF_FILE);
    }

    # Set Sunstone server
    if (exists $tree->{sunstone}) {
        $self->set_one_service_conf($tree->{sunstone}, "sunstone", $SUNSTONE_CONF_FILE, $cfggrp);
        if (exists $tree->{users}) {
            my $users = $tree->{users};
            foreach my $user (sort keys %{$users}) {
                if ($user eq $SERVERADMIN_USER && exists $users->{$user}->{password}) {
                    $self->set_one_auth_file($user, $users->{$user}->{password}, $cfggrp);
                }
            }
        }
    }

    # Set OneFlow server
    if (exists $tree->{oneflow}) {
        $self->set_one_service_conf($tree->{oneflow}, "oneflow", $ONEFLOW_CONF_FILE);
    };

    # Set OpenNebula server
    if (exists $tree->{rpc}) {
        return $self->set_one_server($tree);
    }

    return 1;
}

=head2 read_one_aii_conf

Reads a config file in C<.ini> style with a minimal RPC endpoint setup.
Returns an OpenNebula instance afterwards.

=cut

sub read_one_aii_conf
{
    my ($self, $data) = @_;

    my $rpc = "rpc";

    if (! -f $AII_OPENNEBULA_CONFIG) {
        $self->error("No configfile $AII_OPENNEBULA_CONFIG.");
        return;
    }

    my $config = Config::Tiny->new;
    my $domainname = $data->getElement ($DOMAINNAME)->getValue;
    my $hostname = $data->getElement ($HOSTNAME)->getValue;
    my $fqdn = "${hostname}.${domainname}";

    $config = Config::Tiny->read($AII_OPENNEBULA_CONFIG);
    foreach my $section (sort keys %{$config}) {
        $self->verbose("Found RPC section: $section");
        my $pattern = $config->{$section}->{pattern};
        if ($pattern and $fqdn =~ /^$pattern$/ and $rpc eq 'rpc') {
            $rpc = $section;
            $self->info("Match pattern in RPC section: [$rpc]");
            last;
        };
    };
    if (exists($config->{$domainname}) and $rpc eq 'rpc') {
        $rpc = $domainname;
        $self->info ("Detected configfile RPC section: [$rpc]");
    };
    $config->{$rpc}->{port} //= $ONE_DEFAULT_PORT;
    my $port = $config->{$rpc}->{port};
    my $host = $config->{$rpc}->{host};
    $config->{$rpc}->{url} //= $ONE_DEFAULT_URL;
    $config->{$rpc}->{user} //= $ONEADMIN_USER;

    # Keep backwards compatibility
    if ($host) {
        $self->warn("RPC old host section detected: $host. ",
                              "Please use metaconfig to generate a proper OpenNebula aii configuration.",
                              "ONE aii will replace the RPC url by the assigned host at this point.");
        $config->{$rpc}->{url} = "http://$host:$port/RPC2";
    };

    if (! $config->{$rpc}->{password} ) {
        $self->error("No password set in configfile $AII_OPENNEBULA_CONFIG. Section [$rpc]");
        return;
    };

    my $one = $self->make_one($config->{$rpc});
    return $one;

}

# Return fqdn of the node
sub get_fqdn
{
    my ($self,$config) = @_;
    my $hostname = $config->getElement ($HOSTNAME)->getValue;
    my $domainname = $config->getElement ($DOMAINNAME)->getValue;
    return "${hostname}.${domainname}";
}

sub new
{
    my $class = shift;
    return bless {}, $class;
}

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

# Check if the service is removed
# before our TIMEOUT
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
    if ($@) {
        die unless $@ eq "alarm\n";
        $self->error("VM image deletion: $name. TIMEOUT");
    }
}



=head2 is_one_resource_available

Detects if the resource is already there:

=over

=item Returns undef: resource not used yet.

=item Returns 1: resource already used.

=back

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

=head2 aii_post_reboot

Performs Quattor C<post_reboot>.
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

=head2 aii_configure

Based on Quattor template this method:

=over

=item Stops running VM if necessary.

=item Creates/updates VM templates.

=item Creates new VM image for each C<$harddisks>.

=item Creates new C<VNET> C<ARs> if required.

=back

=cut

sub aii_configure
{
    my ($self, $config, $path) = @_;
    my $tree = $config->getElement($path)->getTree();
    my $createimage = $tree->{image};
    $self->info("Create VM image flag is set to: $createimage");
    my $createvmtemplate = $tree->{template};
    $self->info("Create VM template flag is set to: $createvmtemplate");
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

=head2 aii_install

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
    $self->info("Instantiate VM flag is set to: $instantiatevm");
    my $onhold = $tree->{onhold};
    $self->info("Start VM onhold flag is set to: $onhold");
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
        $self->info("Found VM template from ONE database: ", $vmtemplate->name);
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
                $self->info("VM Image status: READY ,OK");
            } else {
                $self->error("TIMEOUT! VM image status: ", $t->state);
                return 0;
            };
        }
        my $vmid = $vmtemplate->instantiate(name => $fqdn, onhold => $onhold);
        if (defined($vmid) && $vmid =~ m/^\d+$/) {
            $self->info("VM ${fqdn} was created successfully with ID: ${vmid}");
            if ($permissions) {
                my $newvm = $self->get_resource_instance($one, "vm", $fqdn);
                $self->change_permissions($one, "vm", $newvm, $permissions) if $newvm;
            };
        } else {
            $self->error("Unable to instantiate VM ${fqdn}: ${vmid}");
        }
    }
}

=head2 aii_remove

=over

=item Performs VM remove wich depending on the booleans.

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
    $self->info("Stop VM flag is set to: $stopvm");
    my $rmimage = $tree->{image};
    $self->info("Remove image flag is set to: $rmimage");
    my $rmvmtemplate = $tree->{template};
    $self->info("Remove VM templates flag is set to: $rmvmtemplate");
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
        $self->stop_and_remove_one_vms($one,$fqdn);
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

1;
