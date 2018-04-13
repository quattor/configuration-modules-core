#${PMpre} NCM::Component::OpenStack::Service${PMpost}

use CAF::Object qw(SUCCESS);
use CAF::Process 17.8.1;
use EDG::WP4::CCM::TextRender;
use parent qw(CAF::Object Exporter);
use Module::Load;
use Readonly;

our @EXPORT_OK = qw(get_flavour get_service run_service);

Readonly my $HOSTNAME => "/system/network/hostname";
Readonly my $DOMAINNAME => "/system/network/domainname";
Readonly my $DEFAULT_PREFIX => "/software/components/openstack";
Readonly my $VIRSH_COMMAND => "/usr/bin/virsh";

# This map is used when multiple flavour candidates are found in the tree
# (i.e. regular configuartion data) and the fallback filter for
# the quattor subtree (from the custom openstack_quattor type) would not detect it
# This should match the openstack_oneof condition in the schema
Readonly my %TYPE_FLAVOUR_CANDIDATES => {
    identity => [qw(keystone)],
};

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
        $log->error("No flavour candidates for type $type found");
    } elsif (exists($TYPE_FLAVOUR_CANDIDATES{$type})) {
        # First try if there is a type map
        my %testhash = (map {$_ => 1} @{$TYPE_FLAVOUR_CANDIDATES{$type}});
        my @tflavours = grep {$testhash{$_}} @flavours;
        if (scalar @tflavours == 1) {
            $flavour = $tflavours[0];
        } else {
            $log->error("None or more than one type flavour for type $type found: flavours ".join(', ', @flavours));
        }
    } else {
        # Second, reduce the list by filtering for subtree with the quattor attribute
        #   from the custom openstack_quattor type
        my @qflavours = grep {exists($tree->{$type}->{$_}->{quattor})} @flavours;
        if (scalar @qflavours == 1) {
            $flavour = $qflavours[0];
        } else {
            $log->error("More than one flavour for type $type found: ".join(', ', @flavours));
        }
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

=item _init_attrs

Arguments:

=over

=item type: eg identity

=item config: full profile config instance

=item log: reporter instance

=item prefix: the component prefix (for subclassing)

=item client: Net::OpenStack::Client instance

=back

=cut

sub _init_attrs
{
    my ($self, $type, $config, $log, $prefix) = @_;

    $self->{type} = $type;
    $self->{config} = $config;
    $self->{log} = $log;
    $self->{prefix} = $prefix || $DEFAULT_PREFIX;

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

    $self->{hypervisor} = exists($self->{comptree}->{hypervisor});

    # manage command
    # when the attribute is false, populate_service_database is not run
    $self->{manage} = $self->{hypervisor} ? undef : "/usr/bin/$self->{flavour}-manage";

    # database version parameter
    $self->{db_version} = ["db_version"];

    # database sync parameter
    $self->{db_sync} = ["db_sync"];

    # Service user
    $self->{user} = $self->{flavour};
}

=item _initialize

Initialisation using C<_init_attrs>, C<_attrs> and C<_daemons>.

=cut

sub _initialize
{
    my $self = shift;

    $self->_init_attrs(@_);

    # 2nd-to-last method to allow to set custom attrs
    $self->_attrs();

    # generate the daemons
    $self->_daemons();

    return SUCCESS;
}

=item _daemons

Method to customise the C<daemons> attribute during C<_initialize>.

=cut

sub _daemons
{
    my ($self) = @_;

    $self->{daemons} = [] if !exists($self->{daemons});
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

=item _get_json_tree

Return the getTree result on C<path>, in JSON data format.
(Relative paths are relative to the prefix).

=cut

sub _get_json_tree
{
    my ($self, $path) = @_;

    $path = "$self->{prefix}/$path" if $path !~ m/^\//;

    # The data format conversion is taken from CCM::TextRender _make_predefined_options
    return $self->{config}->getTree(
        $path,
        undef, # depth
        convert_boolean => [$EDG::WP4::CCM::TextRender::ELEMENT_CONVERT{json_boolean}],
        );
}

=item _render

Returns CCM::TextRedner instance

=cut

sub _render
{
    my ($self, $element) = @_;

    my $tr = EDG::WP4::CCM::TextRender->new(
        $self->{tt},
        $element,
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

=item _write_config_file

Write the config file with name C<filename> and C<element> instance.

=cut

sub _write_config_file
{
    my ($self, $filename, $element) = @_;

    my $tr = $self->_render($element) or return;

    my $opts = $self->_file_opts();

    my $fh = $tr->filewriter($filename, %$opts);
    if (defined $fh) {
        return $fh->close();
    } else {
        $self->error("Something went wrong with $filename for $self->{type}/$self->{flavour}: $tr->{fail}");
        return;
    }
}

=item _write_config_files

Write multiple config files based on entries in the C<tree> attribute.
Filename is based on mapping in the C<filename> attribute;
a mapping which daemon(s) to start when the file is modified can
be provided via the C<daemon_map> attribute.

=cut

sub _write_config_files
{
    my ($self) = @_;

    my $changed = 0;
    my $daemon_map = $self->{daemon_map} || {};

    foreach my $ntype (sort keys %{$self->{tree}}) {
        # TT file is always common
        my $element = $self->{config}->getElement("$self->{elpath}/$ntype");
        my $filename = $self->{filename}->{$ntype};
        if ($filename) {
            $changed += $self->_write_config_file($filename, $element) ? 1 : 0;

            # And add the required daemons to the list
            push(@{$self->{daemons}}, @{$daemon_map->{$ntype} || []});
        } else {
            $self->error("No filename in map for type $ntype for $self->{type}/$self->{flavour}");
        }
    }
    return $changed;
}

=item write_config_file

Write the config files (when C<filenames> attribute is a hashref) or single file otherwise.

=cut

sub write_config_file
{
    my ($self) = @_;

    my $filename = $self->{filename};
    if (ref($filename) eq 'HASH') {
        return $self->_write_config_files();
    } else {
        return $self->_write_config_file($filename, $self->{element});
    }
}

=item _read_ceph_keyring

Read Ceph pool key file from C<keyring>.

=cut

sub _read_ceph_key
{
    my ($self, $keyring) = @_;

    my $fh = CAF::FileReader->new($keyring, log => $self);
    my $msg = "valid Ceph key in keyring $keyring";
    if ("$fh" =~ m/^key=(.*)/m ) {
        my $key = $1;
        # do not report the key
        $self->verbose("Found a $msg");
        return $key;
    } else {
        $self->error("No $msg found");
        return;
    };
}

=item _libvirt_ceph_secret

Set the libvirt C<secret> file and
couple the C<uuid> to the Ceph key from the C<keyring>.

=cut

# TODO: secret file is generate dform UUID and metaconfig. Do this also from ncm-openstack

sub _libvirt_ceph_secret
{
    my ($self, $secret, $keyring, $uuid) = @_;

    my $cmd = [$VIRSH_COMMAND, "secret-define", "--file", $secret];
    $self->_do($cmd, "Set virsh Ceph secret file", sensitive => 0, user => 'root')
        or return;

    my $key = $self->_read_ceph_key($keyring);
    $cmd = [$VIRSH_COMMAND, "secret-set-value", "--secret", $uuid, "--base64", $key];
    $self->_do($cmd, "Set virsh Ceph pool key", sensitive => 1, user => 'root')
        or return;

    return SUCCESS;
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

=item pre_populate_service_database

Run before the default service database is poulated
(it is not run when database was already present).

Must return 1 on success;

=cut

sub pre_populate_service_database {return 1;}

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
    if ($self->_do([$self->{manage}, @{$self->{db_version}}], 'determine database version', test => 1)) {
        $self->verbose("Found existing db_version");
        return 1 if ($self->{flavour} eq "rabbitmq");
    } else {
        $self->verbose("Database not yet available for service $self->{flavour}");
    };

    # Always populate/sync the databases
    $self->pre_populate_service_database();
    if ($self->_do([$self->{manage}, @{$self->{db_sync}}], 'populate database')) {
        return $self->post_populate_service_database();
    } else {
        # Failure
        return;
    };
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

=item run_client

Configure the service (typically using REST client).
Must return 1 on success.

=cut

sub run_client {return 1};

=item run

Do things (in following order):

=over

=item flavour configuration

=over

=item write_config_file

=item populate_service_database (or return)

=item pre_restart (or return)

=item restart_daemons (if config file changed)

=back

=item service configuration

=over

=item run_client

=back

=back

=cut

sub run
{
    my ($self) = @_;

    my $changed = $self->write_config_file();

    $self->populate_service_database() or return if $self->{manage};

    $self->pre_restart() or return;

    $self->restart_daemons() if $changed;

    $self->run_client() or return;

    return 1;
}


=pod

=back

=cut

1;
