# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::opennebula;

use strict;
use NCM::Component;
use base qw(NCM::Component);
use vars qw(@ISA $EC);
use LC::Exception;
use Net::OpenNebula;

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

sub new
{
    my $class = shift;
    return bless {}, $class;
}

# Detect and process ONE templates
sub process_template 
{
    my ($self, $config, $tt_name) = @_;
    my $res;
    
    my $tt_rel = "metaconfig/opennebula/$tt_name.tt";
    #my $tree = $config->getElement('/')->getTree();
    my $tpl = Template->new(INCLUDE_PATH => TEMPLATEPATH);
    #if (! $tpl->process($tt_rel, $tree, \$res)) {
    if (! $tpl->process($tt_rel, { $tt_name => $config }, \$res)) {
            $self->error("TT processing of $tt_rel failed:", 
                                          $tpl->error());
            return;
    }
    return $res;
}

# Create ONE resources
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
        $self->verbose("Found template NAME:$name $tt resource.");
    } else {
        $self->error("Template NAME not found.");
        return;
    }
    my $method = "create_$tt";
    my $new = $one->$method($template);
    $self->info("It was created a new $name $tt resource.");
}

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
        $self->create_something($one, $type, $newresource);
    }
}


sub manage_hosts
{
    my ($self, $one, $type, $hosts) = @_;

    $self->info("Removing old $type hosts.");
    my @existhost = $one->get_hosts(qr{^.*$});
    foreach my $t (@existhost) {
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
        $one->create_host(%host_options);
    }
}

sub manage_users
{
    my ($self, $one, $users) = @_;

    $self->info("Removing old regular users.");
    my @exitsuser = $one->get_users(qr{^.*$});
    foreach my $t (@exitsuser) {
        $t->delete();
    }

    foreach my $user (@$users) {
        if ($user->{user} && $user->{password}) {
            $self->info("Creating new user: ", $user->{user});
            $one->create_user($user->{user}, $user->{password}, "core");
        }
        else {
            $self->error("No user or password info available.");
        }
    }

}

# DEBUG only (can't get the output in unittests otherwise)
sub error { shift; $main::this_app->error(@_); };
sub debug { shift; $main::this_app->debug(@_); };
sub info { shift; $main::this_app->info(@_); };
sub verbose { shift; $main::this_app->verbose(@_); };

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
