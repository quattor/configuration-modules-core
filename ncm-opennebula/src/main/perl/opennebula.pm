#${PMpre} NCM::Component::${project.artifactId}${PMpost}

=head1 NAME

ncm-${project.artifactId}: Configuration module for OpenNebula

=head1 DESCRIPTION

ncm-opennebula provides support for OpenNebula configuration for:

=over

=item server: setup OpenNebula server and hosts

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

=item * Adding/removing hosts

=item * Adding/removing OpenNebula regular users

=item * Adding/removing OpenNebula groups

=item * Assign OpenNebula users to primary groups

=item * Updates OpenNebula C<< *_auth >> files

=item * Updates VMM kvmrc config file

=item * Updates VNM OpenNebulaNetwork config file

=item * Cloud resource labels (OpenNebula >= 5.x)

=back

OpenNebula installation is 100% automated. Therefore:

=over

=item * All the new OpenNebula templates created by the component will include a QUATTOR flag.

=item * The component only will modify/remove resources with the QUATTOR flag set, otherwise the resource is ignored.

=item * If the component finds any issue during host configuration then the node is set as disabled.

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

=item 2. The OpenNebula server(s) should have passwordless ssh access as oneadmin user to all the host hosts of the cluster.
 e.g. by distributing the public key(s) of the OpenNebula host over the cluster.

=item 3. Start OpenNebula services: C<< # for i in '' -econe -gate -novnc -occi -sunstone; do service opennebula$i stop; done >>

=item 4. Run the component a first time.

=item 5. The new oneadmin password will be available from C<< /var/lib/one/.one/one_auth >> file.
The old auth files are stored with .quattor.backup extension.

=item 6. It is also possible to change sunstone service password, just include
'serveradmin' user and passwd within opennebula/users tree.
In that case the component also updates the C<< sunstone_auth >> file.

=back

=head1 METHODS

=cut

use parent qw(NCM::Component
              NCM::Component::OpenNebula::AII
              NCM::Component::OpenNebula::Commands
              NCM::Component::OpenNebula::Host
              NCM::Component::OpenNebula::Ceph
              NCM::Component::OpenNebula::Server
              NCM::Component::OpenNebula::Account
              NCM::Component::OpenNebula::Network
              NCM::Component::OpenNebula::VM
              NCM::Component::OpenNebula::Image
              );
use NCM::Component::OpenNebula::Server qw($SERVERADMIN_USER);

use CAF::TextRender;
use CAF::FileReader;
use CAF::Service;
use Set::Scalar;
use Config::Tiny;
use Net::OpenNebula 0.311.0;
use Data::Dumper;
use Readonly;
use 5.10.1;

Readonly our $ONED_CONF_FILE => "/etc/one/oned.conf";
Readonly our $SUNSTONE_CONF_FILE => "/etc/one/sunstone-server.conf";
Readonly our $ONEFLOW_CONF_FILE => "/etc/one/oneflow-server.conf";

# Required by process_template to detect 
# if it should return a text template or
# CAF::FileWriter instance
Readonly::Array my @FILEWRITER_TEMPLATES => qw(oned one_auth kvmrc vnm_conf sunstone remoteconf_ceph oneflow);


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

    # if $rpc->{url} does not exist that means we are using the localhost RPC
    $rpc->{url} = $rpc->{url} || "http://$rpc->{host}:$rpc->{port}/RPC2";

    $self->verbose("Connecting to host $rpc->{url} as user $rpc->{user} (with password)");

    my %opts = (
        url      => $rpc->{url},
        user     => $rpc->{user},
        password => $rpc->{password},
        log => $self,
        fail_on_rpc_fail => 0,
    );

    $opts{ca} = $rpc->{ca} if $rpc->{ca};

    my $one = Net::OpenNebula->new(%opts);
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
    # Change resource permissions
    if ($new and defined($data->{$name}->{permissions})) {
        $self->change_permissions($one, $type, $new, $data->{$name}->{permissions});
    };
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
        $self->info("Updating old $type QUATTOR resource with a new template: ", $name);
        $self->debug(1, "New $name template : $template");
        $update = $t->update($template, 1);
        $update = $t if defined($update);
        if ($type eq "vnet" && defined($data->{$name}->{ar})) {
            $self->update_vn_ar($one, $name, $template, $t, $data);
        }
    }
    return $update;
}


=head2 detect_used_resource

Detects if the resource is already there and if QUATTOR flag is present.

=over

=item Returns undef: resource not used yet.

=item Returns 1: resource already used without QUATTOR flag.

=item Returns -1: resource already used with QUATTOR flag set

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
                        "The QUATTOR flag is not set. ",
                        "We can't modify this resource.");
            return 1;
        } elsif ($quattor == 1) {
            $self->verbose("Name : $name is already used by a $type resource. ",
                        "QUATTOR flag is set. ",
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

=head2 Configure

Configure basic OpenNebula server resources.

=cut

sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix);

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

1;
