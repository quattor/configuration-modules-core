# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::opennebula;

use strict;
use NCM::Component;
use base qw(NCM::Component);
use vars qw(@ISA $EC);
use LC::Exception;
# OpenNebula Quattor component requires Net::OpenNebula module
# available from github: https://github.com/stdweird/p5-net-opennebula
use Net::OpenNebula;

use constant TEMPLATEPATH => "/usr/share/templates/quattor";

our $EC=LC::Exception::Context->new->will_store_all;

# Function to connect to ONE RPC endpoint
# to admin and manage OpenNebula resources 
# it requires a valid ONE admin user/pass 
# onadmin is used by default
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

# Detect and process ONE templates
sub process_template 
{
    my ($self, $config, $tt_name) = @_;
    my $res;
    
    my $tt_rel = "metaconfig/opennebula/$tt_name.tt";
    my $tpl = Template->new(INCLUDE_PATH => TEMPLATEPATH);
    if (! $tpl->process($tt_rel, { $tt_name => $config }, \$res)) {
            $self->error("TT processing of $tt_rel failed:", 
                                          $tpl->error());
            return;
    }
    return $res;
}

# Create ONE resources
# based on resource type
sub create_something
{
    my ($self, $one, $tt, $data) = @_;
    
    my $template = $self->process_template($data, $tt);
    my $name;
    if (!$template) {
        $self->error("No template data found for $tt.");
        return;
    }
    if ($template =~ m/^NAME\s+=\s+(?:"|')(.*?)(?:"|')\s*$/m) {
        $name = $1;
        $self->verbose("Found template NAME: $name within $tt resource.");
    } else {
        $self->error("Template NAME not found.");
        return;
    }
    my $method = "create_$tt";
    $self->info("Creating new $name $tt resource.");
    my $new = $one->$method($template);
    return $new;
}

# Remove/add ONE resources
# based on resource type
sub manage_something
{
    my ($self, $one, $type, $resources) = @_;

    if (!$resources) {
        $self->error("No $type resources found.");
    } else {
        $self->info("Found new $type resources.");
    }

    if (($type eq "kvm") or ($type eq "xen")) {
        $self->manage_hosts($one, $type, $resources);
        return;
    }

    if ($type eq "user") {
        $self->manage_users($one, $resources);
        return;
    }

    $self->info("Removing old ${type}/s");
    my $method = "get_${type}s";
    my @existres = $one->$method(qr{^.*$});
    foreach my $oldresource (@existres) {
        $oldresource->delete();
    }

    $self->info("Creating new ${type}/s");
    foreach my $newresource (@$resources) {
        my $new = $self->create_something($one, $type, $newresource);
    }
}

# Function to add/remove Xen or KVM hyp hosts
sub manage_hosts
{
    my ($self, $one, $type, $hosts) = @_;

    $self->info("Removing old $type hosts.");
    my @existhost = $one->get_hosts(qr{^.*$});
    foreach my $t (@existhost) {
        $self->verbose("Removing $type host: ", $t->name);
        $t->delete();
    }

    foreach my $host (@$hosts) {
        my %host_options = (
            'name'    => $host, 
            'im_mad'  => $type, 
            'vmm_mad' => $type, 
            'vnm_mad' => "dummy"
        );
        $self->verbose("Creating new $type host $host.");
        my $new = $one->create_host(%host_options);
    }
}

# Function to add/remove regular users
# only if the user has the Quattor flag set
sub manage_users
{
    my ($self, $one, $users) = @_;

    my @exitsuser = $one->get_users(qr{^.*$});
    foreach my $t (@exitsuser) {
        # Remove the user only if the QUATTOR flag is set
        if ($t->{extended_data}->{TEMPLATE}->[0]->{QUATTOR}->[0]) {
            $self->info("Removing old regular user: ", $t->name);
            $t->delete();
        } else {
            $self->error("QUATTOR flag not found. We can't remove this user: ", $t->name);
        }
    }

    foreach my $user (@$users) {
        if ($user->{user} && $user->{password}) {
            # TODO: Create users with QUATTOR flag set
            # we have to update the user after its creation
            $self->info("Creating new user: ", $user->{user});
            my $new = $one->create_user($user->{user}, $user->{password}, "core");
        }
        else {
            $self->error("No user name or password info available.");
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
