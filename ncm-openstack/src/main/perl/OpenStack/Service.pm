#${PMpre} NCM::Component::OpenStack::Service${PMpost}

use CAF::Object qw(SUCCESS);
use parent qw(CAF::Object Exporter);
use Module::Load;
use Readonly;

our @EXPORT_OK = qw(get_flavour get_service);

Readonly my $HOSTNAME => "/system/network/hostname";
Readonly my $DOMAINNAME => "/system/network/domainname";
Readonly my $DEFAULT_PREFIX => "/software/components/openstack";

# Determine the name of the flavour based on type and tree and log/reporter instance
# (eg name=keystone for type=identity)
sub get_flavour
{
    my ($type, $tree, $log) = @_;

    my $flavour;
    my @flavours = sort keys %{$tree->{$type}};
    if (scalar @flavours == 1) {
        $flavour = $flavours[0];
    } elsif (!@flavours) {
        $log->error("No flavour for type $type found");
    } else {
        $log->error("More than one flavour for type $type found: ".join(', ', @flavours));
    }
    return $flavour;
}

# Get C<fqdn> of the host.
sub get_fqdn
{
    my ($config) = @_;

    my $hostname = $config->getElement($HOSTNAME)->getValue;
    my $domainname = $config->getElement($DOMAINNAME)->getValue;

    return "$hostname.$domainname";
}


# Service factory: loads custom subclasses when one exists
# Same args as _initialize
sub get_service
{
    my ($type, $config, $log, $prefix, $client) = @_;

    my $tree = $config->getTree($prefix || $DEFAULT_PREFIX);
    my $flavour = get_flavour($type, $tree, $log) or return;

    # try to find custom package
    # if not, return regular Service instance
    my $clprefix = "NCM::Component::OpenStack::";
    my $class = "${clprefix}".ucfirst($flavour);
    my $msg = "custom class $class found for type $type flavour $flavour";
    local $@;
    eval {
        load $class;
    };
    if ($@) {
        $class = "${clprefix}Service";
        if ($@ !~ m/^can.*locate.*in.*INC/i) {
            # if you can't locate the module, it's probably ok no to mention it
            # but anything else (eg syntax error) should be reported
            $msg .= " (module load failed: $@)"
        }
        $log->verbose("No $msg, using class $class.");
    } else {
        $log->verbose(ucfirst($msg));
    }

    return $class->new(@_);
}


# type: eg identity
# config: full profile config instance
# log: reporter instance
# prefix: the component prefix (for subclassing)
# client: Net::OpenStack::Client instance
sub _initialize
{
    my ($self, $type, $config, $log, $prefix, $client) = @_;

    $self->{type} = $type;
    $self->{config} = $config;
    $self->{log} = $log;
    $self->{prefix} = $prefix || $DEFAULT_PREFIX;
    $self->{client} = $client;

    $self->{comptree} = $config->getTree($self->{prefix});

    $self->{fqdn} = get_fqdn($config);

    $self->{flavour} = get_flavour($type, $self->{comptree}, $self) or return;

    # eg required for textrender
    $self->{element} = $self->{config}->getElement("$self->{prefix}/$self->{type}/$self->{flavour}");
    # convenience
    $self->{tree} = $self->{element}->getTree();
    # reset the element for future eg getTree
    $self->{element}->reset();

    return SUCCESS;
}


1;
