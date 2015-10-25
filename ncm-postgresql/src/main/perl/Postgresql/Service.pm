# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Postgresql::Service;

use strict;
use warnings;

# This is just very convenient,
# and makes sense since there's only one service
use overload ('""' => '_stringify');

use CAF::Service qw(@FLAVOURS __make_method);
use parent qw(CAF::Service Exporter);

our @EXPORT_OK = qw($POSTGRESQL);

use Readonly;
Readonly my $SERVICENAME => 'SERVICENAME';
Readonly our $POSTGRESQL => 'postgresql';

Readonly my $SYSV_INITD => "/etc/init.d";

Readonly my $SYSTEMD_LIB_SYSTEM => "/usr/lib/systemd/system";
Readonly my $SYSTEMD_ETC_SYSTEM => "/etc/systemd/system";

sub _initialize {
    my ($self, %opts) = @_;

    $self->{$SERVICENAME} = delete $opts{name} || $POSTGRESQL;

    return $self->SUPER::_initialize([$self->{$SERVICENAME}], %opts);
}

# The SERVICENAME
sub _stringify
{
    my $self = shift;
    return $self->{$SERVICENAME};
}

# TODO: status should check "only" postmaster process like the old code did?
# TODO: what to do with exitcode?

foreach my $method (qw(status initdb)) {
    foreach my $flavour (@FLAVOURS) {
        no strict 'refs';
        *{"${method}_${flavour}"} = __make_method($method, $flavour);
        use strict 'refs';
    }
};

# TODO: generic enough for CAF::Service?
# check initstate, do X or Y, and verify if expected endstate
# result is based on status, not on the return value of the X or Y method
#   init: expected initial state 0 or 1
#   ok / notok: run method named ok when initial state == init, method named notok otherwise
#     if ok or notok is undef: log verbose and return state == init
#   end: expected end state 0 or 1, return succes if state == end after method; fail and log error otherwise
#
# init seems not needed, but is relevant when ok or notok or btoh are undef
#    for undef ok, it means, all is as expected, nothing to do here
#    not undef notok, it means if not even in this state, giving up
sub _wrap_in_status
{
    my ($self, $init, $ok, $notok, $end) = @_;

    my $state = $self->status() ? 1 : 0; # force to 0 /1

    my $res = ($state == $init) ? 1 : 0; # force to 0 /1

    my $msg = "$self->{$SERVICENAME} status $state (expected initial $init)";

    my $method;
    if ($res && $ok) {
        $method = $ok;
    } elsif ((! $res) && $notok) {
        $method = $notok;
    } else {
        $self->verbose("$msg, not doing anything, return $res.");
        return $res;
    }

    $self->verbose("$msg, going to run $method.");
    my $ec = $self->$method();
    $self->verbose("$self->{$SERVICENAME} ran $method (ec $ec).");

    # stop failed because still running
    $state = $self->status() ? 1 : 0; # force to 0 /1
    $self->verbose("$self->{$SERVICENAME} end status $state.");
    if ($state == $end) {
        return 1;
    } else {
        my $endlogic = $end ? 'not ' : '';
        $self->error("$self->{$SERVICENAME} ${endlogic}running.");
        return 0;
    };
}

# status_start: _warp_in_status, do nothing if already running
# expected result: running
sub status_start
{
    my ($self) = @_;
    return $self->_wrap_in_status(1, undef, 'start', 1);
}

# status_stop: stop + _wrap_in_status, do nothing if not running
# expected result: not running
sub status_stop
{
    my ($self) = @_;
    return $self->_wrap_in_status(0, undef, 'stop', 0);
}

# status_reload: _wrap_in_status, reload if running, start if not
# expected result: running
sub status_reload
{
    my ($self) = @_;
    return $self->_wrap_in_status(1, 'reload', 'start', 1);
}

# status_reload: _wrap_in_status, restart if running, start if not
# expected result: running
sub status_restart
{
    my ($self) = @_;
    return $self->_wrap_in_status(1, 'restart', 'start', 1);
}

# initdb_start: run initdb, followed by start, return combined exitcodes
sub initdb_start
{
    my ($self) = @_;

    my $initdb = $self->initdb();
    my $start = $self->start();

    my $res = $initdb && $start;
    $self->verbose("initdb_start: exitcodes initdb $initdb start $start result $res");
    return $res;
}

# status_initdb: _wrap_in_status, initdb+start if not running, restart otherwise
# expected result: running
sub status_initdb
{
    my ($self) = @_;
    return $self->_wrap_in_status(0, 'initdb_start', 'restart', 1);
}

# Return filenames for default and name service
sub installation_files_linux_sysv
{
    my ($self, $default) = @_;
    return ("$SYSV_INITD/$default", "$SYSV_INITD/".$self->{$SERVICENAME});
}

# Return filenames for default and name service
sub installation_files_linux_systemd
{
    my ($self, $default) = @_;
    my $loc = ($self->{$SERVICENAME} eq $default) ? $SYSTEMD_LIB_SYSTEM : $SYSTEMD_ETC_SYSTEM;
    return ("$SYSTEMD_LIB_SYSTEM/$default.service", "$loc/".$self->{$SERVICENAME}.".service");
}

1;
