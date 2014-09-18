# ${license-info}
# ${developer-info}
# ${author-info}
# Software subject to following license(s):
#   Apache 2 License (http://www.opensource.org/licenses/apache2.0)
#   Copyright (c) Responsible Organization
#

# #
# Current developer(s):
#   Alvaro Simon Garcia <Alvaro.SimonGarcia@UGent.be>
#

# 


package NCM::Component::opennebula;

use strict;
use warnings;
use NCM::Component;
use base qw(NCM::Component);
use vars qw(@ISA $EC);
use LC::Exception;
use Net::OpenNebula;

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
            $self->error("TT processing of $type_rel failed:", 
                                          $tpl->error());
            return;
    }
    return $res;
}

# Create ONE resources
# based on resource type
sub create_something
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
        $self->error("Template NAME not found.");
        return;
    }
    my $cmethod = "create_$type";

    my @rname = $self->detect_used_resource($one, $type, $name);
    if (!@rname) {
        $self->info("Creating new $name $type resource.");
        $new = $one->$cmethod($template);
    }
    return $new;
}

# Detects if the resource
# is already there
sub detect_used_resource
{
    my ($self, $one, $type, $name) = @_;
    my $gmethod = "get_${type}s";
    my @existres = $one->$gmethod(qr{^$name$});
    if (@existres) {
	$self->error("Name: $name is already used by a $type resource. We can't create the same resource twice.");
	return @existres;
    } else {
	$self->verbose("Name: $name is not used by $type resource yet.");
        return;
    }
}

# Create resource name
# array list
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

# Remove/add ONE resources
# based on resource type
sub manage_something
{
    my ($self, $one, $type, $resources) = @_;
    my ($remove, @namelist);

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
    my $method = "get_${type}s";
    my @existres = $one->$method(qr{^.*$});
    my @namelist = $self->create_resource_names_list($one, $type, $resources);
    my %rnames = map { $_ => 1 } @namelist;
    foreach my $oldresource (@existres) {
        # Remove the resource only if the QUATTOR flag is set
        # and they are not being used
        if ($type eq "datastore" and !$oldresource->{extended_data}->{IMAGES}->[0]->{ID}->[0]) {
            $remove = 1;
        } 
        if ($type eq "vnet" and !$oldresource->{extended_data}->{TOTAL_LEASES}->[0]) {
            $remove = 1;
        }
        if ($oldresource->{extended_data}->{TEMPLATE}->[0]->{QUATTOR}->[0] and $remove and !exists($rnames{$oldresource->name})) {
            $self->info("Removing old resource: ", $oldresource->name);
            $oldresource->delete();
        } else {
            $self->error("QUATTOR flag not found or the resource is still used. We can't remove this resource: ", $oldresource->name);
        };
    }

    if (scalar @$resources > 0) {
        $self->info("Creating new ${type}/s: ", scalar @$resources);
    }
    foreach my $newresource (@$resources) {
        my $new = $self->create_something($one, $type, $newresource);
    }
}

# Function to add/remove Xen or KVM hyp hosts
sub manage_hosts
{
    my ($self, $one, $type, $hosts) = @_;
    my $new;
    $self->info("Removing old $type hosts.");
    my @existhost = $one->get_hosts(qr{^.*$});
    my %newhosts = map { $_ => 1 } @$hosts;
    foreach my $t (@existhost) {
        # Remove the host only if there are no VMs running on it
        if ($t->{extended_data}->{HOST_SHARE}->[0]->{RUNNING_VMS}->[0] or exists($newhosts{$t->name})) {
            $self->error("We can't remove this $type host. There are still running VMs or is a Quattor host: ", $t->name);
        } else {
            $self->info("Removing $type host: ", $t->name);
            $t->delete();
        }
    }

    foreach my $host (@$hosts) {
        my %host_options = (
            'name'    => $host, 
            'im_mad'  => $type, 
            'vmm_mad' => $type, 
            'vnm_mad' => "dummy"
        );
        my @rname = $self->detect_used_resource($one, "host", $host);
        if (!@rname) {
            $self->info("Creating new $type host $host.");
            $new = $one->create_host(%host_options);
        }
    }
}

# Function to add/remove regular users
# only if the user has the Quattor flag set
sub manage_users
{
    my ($self, $one, $users) = @_;
    my ($new, @userlist);

    foreach my $user (@$users) {
        if ($user->{user} && $user->{password}) {
            # TODO: Create users with QUATTOR flag set
            # we have to update the user after its creation
            my @rname = $self->detect_used_resource($one, "user", $user->{user});
            push(@userlist, $user->{user});
            if (!@rname) {
                $self->info("Creating new user: ", $user->{user});
                $new = $one->create_user($user->{user}, $user->{password}, "core");
            }
        }
        else {
            $self->error("No user name or password info available.");
        }
    }

    my @exitsuser = $one->get_users(qr{^.*$});
    my %newusers = map { $_ => 1 } @userlist;

    foreach my $t (@exitsuser) {
        # Remove the user only if the QUATTOR flag is set
        if ($t->{extended_data}->{TEMPLATE}->[0]->{QUATTOR}->[0] and !exists($newusers{$t->name})) {
            $self->info("Removing old regular user: ", $t->name);
            $t->delete();
        } else {
            $self->error("QUATTOR flag not found or this user was already included by Quattor. We can't remove it: ", $t->name);
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
