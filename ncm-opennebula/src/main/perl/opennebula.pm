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
    if (! $tpl->process($tt_rel, $config, \$res)) {
            $self->error("TT processing of $tt_rel failed:", 
                                          $tpl->error());
            $main::this_app->error("TT processing of $tt_rel failed:",$tpl->error());
            return;
    }
    return $res;
}

# Create ONE resources
sub create_something
{
    my ($self, $one, $data, $tt) = @_;
    
    my $template = $self->process_template($data, $tt);
    my $name;
    if (!$template) {
        $main::this_app->error("No template data found for $tt!");
        return;
    }
    if ($template =~ m/^NAME\s+=\s+(?:"|')(.*?)(?:"|')\s*$/m) {
        $name = $1;
    } else {
        $self->error("Template NAME not found!");
        $main::this_app->error("Template NAME not found!");
        return;
    }
    my $method = "create_$tt";
    my $new = $one->$method($template);
}

sub manage_something
{
    my ($self, $one, $resources, $type) = @_;

    if (!$resources) {
        $main::this_app->error("No $type resources found!");
    } else {
        $main::this_app->info("Found new $type resources...");
    }

    if (($type eq "kvm") or ($type eq "xen")) {
        $self->manage_hosts($one, $resources, $type);
        return;
    }

    $main::this_app->info("Removing old ${type}/s...");
    my $method = "get_${type}s";
    my @existres = $one->$method(qr{^.*$});
    foreach my $oldresource (@existres) {
        $oldresource->delete();
    }

    $main::this_app->info("Creating new ${type}/s...");
    foreach my $newresource (@$resources) {
        $self->create_something($one, $newresource, $type);
    }
}


sub manage_hosts
{
    my ($self, $one, @hosts, $type) = @_;

    $self->info("Removing old hosts...");
    $main::this_app->info("Removing old hosts...");

    my @existhost = $one->get_hosts(qr{^.*$});
    foreach my $t (@existhost) {
        $t->delete();
    }

    $self->info("Creating new hosts...");
    $main::this_app->info("Creating new hosts...");
    foreach my $host (@hosts) {
        my %host_options = (
            'name'    => $host, 
            'im_mad'  => $type, 
            'vmm_mad' => $type, 
            'vnm_mad' => "dummy"
        );
        $one->create_host(%host_options);
    }
}

# Configure basic ONE resources
sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/opennebula";
    my $tree = $config->getElement($base)->getTree();

    $self->error("error");
    # Connect to ONE RPC
    my $one = $self->make_one($tree->{rpc});
    if (! $one ) {
        $self->error("No ONE instance created.");
        $main::this_app->error("No ONE instance created.");
        return 0;
    };

    # Add/remove VNETs
    $self->manage_something($one, $tree->{vnets}, "vnet");

    # Add/remove datastores
    $self->manage_something($one, $tree->{datastores}, "datastore");

    # Add/remove KVM hosts
    my $hypervisor = "kvm";
    $self->manage_something($one, $tree->{hosts}, $hypervisor);

    # Add/remove regular users
    #$self->manage_something($one, $tree->{users}, "user");

    return 1;
}

1;
