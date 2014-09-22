# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::opennebula;

use strict;
use warnings;
use NCM::Component;
use base qw(NCM::Component);
use vars qw(@ISA $EC);
use LC::Exception;
use Net::OpenNebula;
use Data::Dumper;

# TODO use constant from CAF::Render
use constant TEMPLATEPATH => "/usr/share/templates/quattor";

our $EC=LC::Exception::Context->new->will_store_all;

sub make_one 
{
    my ($self, $rpc) = @_;

    if (! $rpc->{password} ) {
        $self->error("No RPC ONE password set!");
        return;
    }

    $self->verbose("Connecting to host $rpc->{host}:$rpc->{port} as user $rpc->{user} (with password)");

    my $one = Net::OpenNebula->new(
        url      => "http://$rpc->{host}:$rpc->{port}/RPC2",
        user     => $rpc->{user},
        password => $rpc->{password},
        log => $self,
        fail_on_rpc_fail => 0,
    );
    return $one;
}

# TODO replace by CAF::Render
# Detect and process ONE templates
sub process_template 
{
    my ($self, $config, $type_name) = @_;
    my $res;
    
    my $type_rel = "metaconfig/opennebula/$type_name.tt";
    my $tpl = Template->new(INCLUDE_PATH => TEMPLATEPATH);
    if (! $tpl->process($type_rel, { $type_name => $config }, \$res)) {
        $self->error("TT processing of $type_rel failed: ",$tpl->error());
        return;
    }
    return $res;
}

# Create/update ONE resources
# based on resource type
sub create_or_update_something
{
    my ($self, $one, $type, $data) = @_;
    
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
    my $cmethod = "create_$type";

    my $used = $self->detect_used_resource($one, $type, $name);
    if (!$used) {
        $self->info("Creating new $name $type resource.");
        $new = $one->$cmethod($template);
    } elsif ($used == -1) {
        # resource is already there and we can modify it
        $new = $self->update_something($one, $type, $name, $template);
    }
    return $new;
}

sub remove_something
{
    my ($self, $one, $type, $resources) = @_;
    my $method = "get_${type}s";
    my @existres = $one->$method();
    my @namelist = $self->create_resource_names_list($one, $type, $resources);
    my %rnames = map { $_ => 1 } @namelist;

    foreach my $oldresource (@existres) {
        # Remove the resource only if the QUATTOR flag is set
        my $quattor = $self->check_quattor_tag($oldresource);

        if ($quattor and !$oldresource->used() and !exists($rnames{$oldresource->name})) {
            $self->info("Removing old resource: ", $oldresource->name);
            $oldresource->delete();
        } else {
            $self->error("QUATTOR flag not found or the resource is still used. ",
                        "We can't remove this resource: ", $oldresource->name);
        };
    }
    return;
}

sub update_something
{
    my ($self, $one, $type, $name, $template) = @_;
    my $method = "get_${type}s";
    my $update;
    my @existres = $one->$method(qr{^${name}$});
    foreach my $t (@existres) {
        # $merge=1, we don't replace, just merge the new templ
        $self->info("Updating old $type Quattor resource with a new template: ", $name);
        $self->debug(1, "New $name template : $template");
        $update = $t->update($template, 1);
    }
    return $update;
}

# Detects if the resource
# is already there and if quattor flag is present
# return undef: resource not used yet
# return 1: resource already used without Quattor flag
# return -1: resource already used with Quattor flag set
sub detect_used_resource
{
    my ($self, $one, $type, $name) = @_;
    my $quattor;
    my $gmethod = "get_${type}s";
    my @existres = $one->$gmethod(qr{^$name$});
    if (scalar @existres > 0) {
        $quattor = $self->check_quattor_tag(@existres[0]);
    }
    if (@existres and !$quattor) {
        $self->verbose("Name: $name is already used by a $type resource. ",
                    "The Quattor flag is not set. ",
                    "We can't modify this resource.");
        return 1;
    } elsif (@existres and $quattor) {
        $self->verbose("Name : $name is already used by a $type resource. ",
                    "Quattor flag is set. ",
                    "We can modify and update this resource.");
        return -1;
    } else {
        $self->verbose("Name: $name is not used by $type resource yet.");
        return;
    }
}

sub create_resource_names_list
{
    my ($self, $one, $type, $resources) = @_;
    my ($name,@namelist, $template);

    foreach my $newresource (@$resources) {
        $template = $self->process_template($newresource, $type);
        if ($template =~ m/^NAME\s+=\s+(?:"|')(.*?)(?:"|')\s*$/m) {
            $name = $1;
            push(@namelist, $name);
        }
    }
    return @namelist;
}

sub check_quattor_tag
{
    my ($self, $resource) = @_;
    if ($resource->{extended_data}->{TEMPLATE}->[0]->{QUATTOR}->[0]) {
        return 1;
    } else {
        return;
    }
}

# Remove/add ONE resources
# based on resource type
sub manage_something
{
    my ($self, $one, $type, $resources) = @_;

    if (!$resources) {
        $self->error("No $type resources found.");
        return;
    } else {
        $self->verbose("Managing $type resources.");
    }

    if (($type eq "kvm") or ($type eq "xen")) {
        $self->manage_hosts($one, $type, $resources);
        return;
    } elsif ($type eq "user") {
        $self->manage_users($one, $resources);
        return;
    }

    $self->verbose("Check to remove ${type}s");
    $self->remove_something($one, $type, $resources);

    if (scalar @$resources > 0) {
        $self->info("Creating new ${type}/s: ", scalar @$resources);
    }
    foreach my $newresource (@$resources) {
        my $new = $self->create_or_update_something($one, $type, $newresource);
    }
}

# Function to add/remove Xen or KVM hyp hosts
sub manage_hosts
{
    my ($self, $one, $type, $hosts) = @_;
    my $new;
    my @existhost = $one->get_hosts();
    my %newhosts = map { $_ => 1 } @$hosts;
    my @rmhosts;
    foreach my $t (@existhost) {
        # Remove the host only if there are no VMs running on it
        if (exists($newhosts{$t->name})) {
            $self->debug("We can't remove this $type host. Is required by Quattor: ", $t->name);
        } elsif ($t->used()) {
            $self->debug("We can't remove this $type host. There are still running VMs: ", $t->name);
        } else {
            push(@rmhosts, $t->name);
            $t->delete();
        }
    }

    if (scalar @rmhosts > 0) {
        $self->info("Removed $type hosts: ", @rmhosts);
    }

    foreach my $host (@$hosts) {
        my %host_options = (
            'name'    => $host, 
            'im_mad'  => $type, 
            'vmm_mad' => $type, 
            'vnm_mad' => "dummy"
        );
        my $used = $self->detect_used_resource($one, "host", $host);
        if (!$used) {
            $self->info("Creating new $type host $host.");
            $new = $one->create_host(%host_options);
        }
    }
}

# Function to add/remove/update regular users
# only if the user has the Quattor flag set
sub manage_users
{
    my ($self, $one, $users) = @_;
    my ($new, $template, @rmusers, @userlist);

    foreach my $user (@$users) {
        if ($user->{user}) {
            push(@userlist, $user->{user});
        }
    }

    my @exitsuser = $one->get_users();
    my %newusers = map { $_ => 1 } @userlist;

    foreach my $t (@exitsuser) {
        # Remove the user only if the QUATTOR flag is set
        my $quattor = $self->check_quattor_tag($t);
        if (exists($newusers{$t->name})) {
            $self->verbose("User required by Quattor. We can't remove it: ", $t->name);
        } elsif (!$quattor) {
            $self->warn("User Quattor flag is not set. We can't remove it: ", $t->name);
        } else {
            push(@rmusers, $t->name);
            $t->delete();
        }
    }

    if (scalar @rmusers > 0) {
        $self->info("Removed users: ", @rmusers);
    }

    foreach my $user (@$users) {
        if ($user->{user} && $user->{password}) {
            $template = $self->process_template($user, "user");
            my $used = $self->detect_used_resource($one, "user", $user->{user});
            if (!$used) {
                $self->info("Creating new user: ", $user->{user});
                $one->create_user($user->{user}, $user->{password}, "core");
                # Add Quattor flag
                $new = $self->update_something($one, "user", $user->{user}, $template);
            } elsif ($used == -1) {
                # User is already there and we can modify it
                $self->info("Updating user with a new template: ", $user->{user});
                $new = $self->update_something($one, "user", $user->{user}, $template);
            }
        } else {
            $self->error("No user name or password info available:", $user->{user});
        }
    }
}

# Configure basic ONE resources
sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/opennebula";
    my $tree = $config->getElement($base)->getTree();

    # Connect to ONE RPC
    my $one = $self->make_one($tree->{rpc});
    if (! $one ) {
        $self->error("No ONE instance created.");
        return 0;
    };

    # Add/remove VNETs
    $self->manage_something($one, "vnet", $tree->{vnets});

    # Add/remove datastores
    $self->manage_something($one, "datastore", $tree->{datastores});

    # Add/remove KVM hosts
    my $hypervisor = "kvm";
    $self->manage_something($one, $hypervisor, $tree->{hosts});

    # Add/remove regular users
    $self->manage_something($one, "user", $tree->{users});

    return 1;
}

1;
