
use version;
use NCM::Component::OpenNebula::commands;
use CAF::Service;
use CAF::FileReader;
use Readonly;

Readonly our $OPENNEBULA_VERSION_FILE => "/var/lib/one/remotes/VERSION";
Readonly our $ONED_DATASTORE_MAD => "-t 15 -d dummy,fs,lvm,ceph,dev,iscsi_libvirt,vcenter -s shared,ssh,ceph,fs_lvm";
Readonly our $ONEADMIN_AUTH_FILE => "/var/lib/one/.one/one_auth";
Readonly our $SERVERADMIN_AUTH_DIR => "/var/lib/one/.one/";
Readonly our $ONEADMINUSR => (getpwnam("oneadmin"))[2];
Readonly our $ONEADMINGRP => (getpwnam("oneadmin"))[3];

Readonly::Array our @SERVERADMIN_AUTH_FILE => qw(sunstone_auth oneflow_auth
                                                 onegate_auth occi_auth ec2_auth);

=head1 NAME

NCM::Component::OpenNebula::Server adds C<OpenNebula> service configuration 
support to L<NCM::Component::OpenNebula>.

=head2 Public methods

=over


=item restart_opennebula_service

Restarts C<OpenNebula> service after any
configuration change.
=cut

sub restart_opennebula_service {
    my ($self, $service) = @_;
    my $srv;
    if ($service eq "oned") {
        $srv = CAF::Service->new(['opennebula'], log => $self);
    } elsif ($service eq "sunstone") {
        $srv = CAF::Service->new(['opennebula-sunstone'], log => $self);
    } elsif ($service eq "oneflow") {
        $srv = CAF::Service->new(['opennebula-flow'], log => $self);
    } elsif ($service eq "kvmrc") {
        $self->info("Updated $service file. onehost sync is required.");
        $self->sync_opennebula_hyps();
    }
    $srv->restart() if defined($srv);
}

=item detect_opennebula_version

Detects C<OpenNebula> version through opennebula-server probe files,
the value gathered from the file must be untaint.

=cut

sub detect_opennebula_version
{
    my ($self) = @_;

    my $fh = CAF::FileReader->new($OPENNEBULA_VERSION_FILE, log => $self);
    if (! "$fh") {
        $self->error("Not found OpenNebula version file: $OPENNEBULA_VERSION_FILE");
        return;
    };

    my $version;
    my $msg = '';
    # untaint value
    if ("$fh" =~ m/^(\d+\.\d+(?:\.\d+)?$)/m ) {
        local $@;
        eval {
            $version = version->new($1);
        };
        $msg = "$@";
    } else {
        $msg = "No match for version regexp";
    }

    if ($version) {
        $self->verbose("OpenNebula $OPENNEBULA_VERSION_FILE file has version $version.");
        return $version;
    } else {
        $self->error("No valid version available from $OPENNEBULA_VERSION_FILE file. $msg");
        return;
    };
}

=item change_opennebula_passwd

Sets a new C<OpenNebula> service password.

=cut

sub change_opennebula_passwd
{
    my ($self, $user, $passwd) = @_;
    my ($output, $cmd);

    if ($user eq $SERVERADMIN_USER) {
        $cmd = [$user, join(' ', '--driver server_cipher', $passwd)];
    } else {
        $cmd = [$user, $passwd];
    };
    $output = $self->run_oneuser_as_oneadmin_with_ssh($cmd, "localhost", 1);
    if (!$output) {
        $self->error("Quattor unable to modify current $user passwd.");
        return;
    } else {
        $self->info("$user passwd was set correctly.");
    }
    $self->set_one_auth_file($user, $passwd);
    return 1;
}

=item set_one_service_conf

Sets C<OpenNebula> configuration files used by
the deamons, if the configuration file is changed the
service must be restarted afterwards.

=cut

sub set_one_service_conf
{
    my ($self, $data, $service, $config_file, $cfggrp) = @_;
    my %opts;
    my $cfgv = $self->detect_opennebula_version;
    if ($cfgv >= version->new("5.0.0") and $service eq 'oned') {
        $self->verbose("Found OpenNebula >= 5.0 configuration flag");
        $data->{datastore_mad}->{arguments} = $ONED_DATASTORE_MAD;
    };
    my $oned_templ = $self->process_template($data, $service);
    %opts = $self->set_file_opts();
    return if ! %opts;
    $opts{group} = $cfggrp if ($cfggrp);
    my $fh = $oned_templ->filewriter($config_file, %opts);
    my $status = $self->is_conf_file_modified($fh, $config_file, $service, $oned_templ);

    return $status;
}

=item is_conf_file_modified

Checks C<OpenNebula> configuration file status.

=cut

sub is_conf_file_modified
{
    my ($self, $fh, $file, $service, $data) = @_;

    if (!defined($fh)) {
        if (defined($service) && defined($data)) {
            $self->error("Failed to render $service file: $file (".$data->{fail}."). Skipping");
        } else {
            $self->error("Problem rendering $file");
        }
        $fh->cancel();
        $fh->close();
        return;
    }
    if ($fh->close()) {
        $self->restart_opennebula_service($service) if (defined($service));
    }
    return 1;
}

=item set_one_auth_file

Sets the authentication files used by
C<oneadmin> client tools.

=cut

sub set_one_auth_file
{
    my ($self, $user, $data, $cfggrp) = @_;
    my ($fh, $auth_file, %opts);

    my $passwd = {$user => $data};
    my $trd = $self->process_template($passwd, "one_auth", 1);
    %opts = $self->set_file_opts(1);
    return if ! %opts;
    $opts{group} = $cfggrp if ($cfggrp);

    if ($user eq $ONEADMIN_USER) {
        $self->verbose("Writing $user auth file: $ONEADMIN_AUTH_FILE");
        $fh = $trd->filewriter($ONEADMIN_AUTH_FILE, %opts);
        $self->is_conf_file_modified($fh, $ONEADMIN_AUTH_FILE);
    } elsif ($user eq $SERVERADMIN_USER) {
        foreach my $service (@SERVERADMIN_AUTH_FILE) {
            $auth_file = $SERVERADMIN_AUTH_DIR . $service;
            $self->verbose("Writing $user auth file: $auth_file");
            $fh = $trd->filewriter($auth_file, %opts);
            $self->is_conf_file_modified($fh, $auth_file);
        }
    } else {
        $self->error("Unsupported user: $user");
    }
}

=item set_file_opts

Sets filewriter options.

=cut

sub set_file_opts
{
    my ($self, $secret) = @_;
    my %opts;
    if ($ONEADMINUSR and $ONEADMINGRP) {
        if (!$secret) {
            %opts = (log => $self);
        }
        %opts = (mode => 0640,
                 backup => ".quattor.backup",
                 owner => $ONEADMINUSR,
                 group => $ONEADMINGRP);
        $self->verbose("Found oneadmin user id ($ONEADMINUSR) and group id ($ONEADMINGRP).");
        return %opts;
    } else {
        $self->error("User or group oneadmin does not exist.");
        return;
    }
}


=pod

=back

=cut

1;
