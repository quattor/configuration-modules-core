#${PMpre} NCM::Component::OpenStack::Service${PMpost}

use CAF::Object qw(SUCCESS);
use CAF::Process 17.8.1;
use parent qw(CAF::Object Exporter);
use Module::Load;
use Readonly;

our @EXPORT_OK = qw(get_flavour get_service run_service);

Readonly my $HOSTNAME => "/system/network/hostname";
Readonly my $DOMAINNAME => "/system/network/domainname";
Readonly my $DEFAULT_PREFIX => "/software/components/openstack";


=head2 Functions

=over

=item get_flavour

Determine the name of the flavour based on type and tree and log/reporter instance
(eg name=keystone for type=identity)

=cut

sub get_flavour
{
    my ($type, $tree, $log) = @_;

    my $flavour;
    my @flavours = sort keys %{$tree->{$type}};
    if ($type eq 'openrc') {
        # Not an actual openstack service
        $flavour = $type;
    } elsif (scalar @flavours == 1) {
        $flavour = $flavours[0];
    } elsif (!@flavours) {
        $log->error("No flavour for type $type found");
    } else {
        $log->error("More than one flavour for type $type found: ".join(', ', @flavours));
    }
    return $flavour;
}

=item get_fqdn

Get C<fqdn> of the host using host profile C<config> instance.

=cut

sub get_fqdn
{
    my ($config) = @_;

    my $hostname = $config->getElement($HOSTNAME)->getValue;
    my $domainname = $config->getElement($DOMAINNAME)->getValue;

    return "$hostname.$domainname";
}


=item get_service

Service factory: loads custom subclasses when one exists
Same args as _initialize

=cut

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

=item run_service

Convenience function around get_service, includes basic reporting

=cut

sub run_service
{
    my $srv = get_service(@_);
    my $msg = "run OpenStack service $srv->{type} flavour $srv->{flavour}";
    $srv->{log}->verbose("Going to $msg");
    my $res = $srv->run();
    my $method = $res ? 'verbose' : 'error';
    $srv->{log}->$method(($res ? "Successfully " : "Failed to " ).$msg);
    return $res;
}

=pod

=back

=head2 Methods

=over

=item _initialize

Arguments:

=over

=item type: eg identity

=item config: full profile config instance

=item log: reporter instance

=item prefix: the component prefix (for subclassing)

=item client: Net::OpenStack::Client instance

=back

=cut

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

    $self->_set_elpath();

    # eg required for textrender
    $self->{element} = $self->{config}->getElement($self->{elpath});
    # convenience
    $self->{tree} = $self->{element}->getTree();
    # reset the element for future eg getTree
    $self->{element}->reset();

    # config filename
    $self->{filename} = "/etc/$self->{flavour}/$self->{flavour}.conf";

    # default TT file
    $self->{tt} = "common";

    # manage command
    $self->{manage} = "/usr/bin/$self->{flavour}-manage";

    # database version parameter
    $self->{db_version} = "db_version";

    # database sync parameter
    $self->{db_sync} = "db_sync";

    # Service user
    $self->{user} = $self->{flavour};

    # Daemons to restart
    $self->{daemons} = [];

    $self->_attrs();

    return SUCCESS;
}

=item _set_elpath

Return main element path

=cut

sub _set_elpath
{
    my $self = shift;
    $self->{elpath} = "$self->{prefix}/$self->{type}/$self->{flavour}";
}

=item _attrs

Add/set/modify more attributes
Conviennce method for inheritance
instead of using SUPER
    my $res = $self->SUPER::method(@_);

=cut

sub _attrs {};

=item _render

Returns CCM::TextRedner instance

=cut

sub _render
{
    my ($self) = @_;

    my $tr = EDG::WP4::CCM::TextRender->new(
        $self->{tt},
        $self->{element},
        relpath => 'openstack',
        log => $self,
        );
    if (!$tr) {
        $self->error("TT processing of $self->{tt} failed for $self->{type}/$self->{flavour}: $tr->{fail}");
        return;
    }

    return $tr;
}

=item _file_opts

Return hashref with filewriter options for C<service>
(incl owned by that service user)

=cut

sub _file_opts
{
    my ($self) = @_;

    my %opts = (
        mode => "0640",
        backup => ".quattor.backup",
        owner => $self->{user},
        group => $self->{user},
        log => $self,
        sensitive => $self->{sensitive} ? 1 : 0,
    );

    return \%opts;
}

=item write_config_file

Write the config file

=cut

sub write_config_file
{
    my ($self) = @_;

    my $tr = $self->_render or return;

    my $opts = $self->_file_opts();

    my $fh = $tr->filewriter($self->{filename}, %$opts);

    if (defined $fh) {
        return $fh->close();
    } else {
        $self->error("Something went wrong with $self->{filename}: $tr->{fail}");
        return;
    }
}

=item _do

Convenience wrapper around CAF::Process

Options

=over

=item user: option passed to C<CAF::Process>

=item sensitive: option passed to C<CAF::Process>

=item test: the command is a test, no error will be reported on failure

=back

=cut

sub _do
{
    my ($self, $cmd, $msg, %opts) = @_;

    foreach my $opt (qw(user sensitive)) {
        $opts{$opt} = $self->{$opt} if ! exists $opts{$opt};
    }
    my $proc = CAF::Process->new(
        $cmd,
        log => $self,
        %opts
        );
    my $output = $proc->output();
    # normally empty
    chomp($output);

    my $ok = $? ? 0 : 1;
    my $report = ($opts{test} || $ok) ? 'verbose' : 'error';

    my $fmsg = "$msg for type $self->{type} flavour $self->{flavour}";
    $fmsg .= ($self->{user} ? " with user $self->{user}" : "");
    $fmsg .= " output: $output" if ($output && !$self->{sensitive});

    $self->$report($ok ? ucfirst($fmsg) : "Failed to $fmsg");

    return $ok;
}

=item populate_service_database

Run the database sync command (incl bootstrap when empty)
if db version cannot be found.

Must return 1 on success.

=cut

sub populate_service_database
{
    my ($self) = @_;
    # db_version is slow when not initialised
    # (lots of retries before it gives up; can take up to 90s)
    if ($self->_do([$self->{manage}, $self->{db_version}], 'determine database version', test => 1)) {
        $self->verbose("Found existing db_version, no db_sync will be applied");
        return 1;
    } else {
        if ($self->_do([$self->{manage}, $self->{db_sync}], 'populate database')) {
            return $self->post_populate_service_database();
        } else {
            # Failure
            return;
        };
    }
};

=item post_populate_service_database

Run after the service database is poulated
(it is not run when database was already present).

Must return 1 on success;

=cut

sub post_populate_service_database {return 1;}

=item restart_daemons

Restarts system service(s) after any configuration
change for OpenStack C<service> service.

=cut

sub restart_daemons
{
    my ($self) = @_;

    my @daemons = @{$self->{daemons} || []};
    if (@daemons) {
        my $srv = CAF::Service->new(\@daemons, log => $self);

        $self->verbose("Restarting daemons for $self->{type} flavour $self->{flavour}: ".join(', ', @daemons));
        # This will report verbose or with error the commands run
        $srv->restart();
    }
}

=item pre_restart

Run before possible restart of services
Must return 1 on success

=cut

sub pre_restart {return 1};

=item run

Do things (in following order):

=over

=item write_config_file

=item populate_service_database (or return)

=item pre_restart (or return)

=item restart_daemons (if config file changed)

=back

=cut

sub run
{
    my ($self) = @_;

    my $changed = $self->write_config_file();

    $self->populate_service_database() or return if($self->{manage});

    $self->pre_restart() or return;

    $self->restart_daemons() if $changed;

    return 1;
}


=pod

=back

=cut

1;
