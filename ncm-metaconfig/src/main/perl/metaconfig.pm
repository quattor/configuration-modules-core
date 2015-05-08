# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;

use base qw(NCM::Component);

use LC::Exception;
use EDG::WP4::CCM::TextRender;
use CAF::Service;
use EDG::WP4::CCM::Element qw(unescape);
use Readonly;

Readonly::Scalar my $PATH => '/software/components/${project.artifactId}';

# Has to correspond to what is allowed in the schema
Readonly::Hash my %ALLOWED_ACTIONS => { restart => 1, reload => 1, stop_sleep_start => 1 };

our $EC=LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

# Given metaconfigservice C<$srv> for C<$file> and hash-reference C<$actions>,
# prepare the actions to be taken for this service/file.
# Does not return anything.
sub prepare_action
{
    my ($self, $srv, $file, $actions) = @_;

    # Not using a hash here to detect and support
    # any overlap with legacy daemon-restart config
    my @daemon_action;

    my $msg = "for file $file";

    if ($srv->{daemons}) {
        while (my ($daemon, $action) = each %{$srv->{daemons}}) {
            push(@daemon_action, $daemon, $action);
        }
    }

    if ($srv->{daemon}) {
        $self->verbose("Deprecated daemon(s) restart via daemon field $msg.");
        foreach my $daemon (@{$srv->{daemon}}) {
            if ($srv->{daemons}->{$daemon}) {
                $self->verbose('Daemon $daemon also defined in daemons field $msg. Adding restart action anyway.');
            }
            push(@daemon_action, $daemon, 'restart');
        }
    }

    my @acts;
    while(my ($daemon,$action) = splice(@daemon_action,0,2)) {
        if(exists($ALLOWED_ACTIONS{$action})) {
            $actions->{$action} ||= {};
            $actions->{$action}->{$daemon} = 1;
            push(@acts, "$daemon:$action");
        } else {
            $self->error("Not a CAF::Service allowed action ",
                         "$action for daemon $daemon $msg ",
                         "in profile (component/schema mismatch?).");
        }
    }

    if (@acts) {
        $self->verbose("Scheduled daemon/action ".join(', ',@acts)." $msg.");
    } else {
        $self->verbose("No daemon/action scheduled $msg.");
    }
}

# Take the action for all daemons as defined in hash-reference C<$actions>.
# Does not return anything.
sub process_actions
{
    my ($self, $actions) = @_;
    while (my ($action, $ds) = each(%$actions)) {
        my $srv = CAF::Service->new([keys(%$ds)], log => $self);
        # CAF::Service does all the logging we need
        $srv->$action();
    }
}

# Generate C<$file>, configuring C<$srv> using CAF::TextRender with
# contents C<$contents> (if C<$contents>  is not defined,
# C<$srv->{contents}> is used).
# Also tracks the actions that need to be taken via the
# C<$actions> hash-reference.
# Returns undef in case of rendering failure, 1 otherwise.
sub handle_service
{
    my ($self, $file, $srv, $contents, $actions) = @_;

    $contents = $srv->{contents} if (! defined($contents));

    my $trd = EDG::WP4::CCM::TextRender->new($srv->{module},
                                             $contents,
                                             log => $self,
                                             eol => 0,
                                             );

    my %opts  = (log => $self,
                 mode => $srv->{mode},
                 owner => scalar(getpwnam($srv->{owner})),
                 group => scalar(getgrnam($srv->{group})));
    $opts{backup} = $srv->{backup} if exists($srv->{backup});

    $opts{header} = "$srv->{preamble}\n" if $srv->{preamble};

    # This in combination with eol=0 is what the original code does
    # TODO: switch to eol=1 and remove this footer?
    $opts{footer} = "\n";

    my $fh = $trd->filewriter($file, %opts);

    if (!defined($fh)) {
        $self->error("Failed to render $file (".$trd->{fail}."). Skipping");
        return;
    }

    $self->prepare_action($srv, $file, $actions) if ($fh->close());

    return 1;
}


sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement($PATH)->getTree();

    my $actions = {};

    while (my ($f, $srvc) = each(%{$t->{services}})) {
        my $cont_el = $config->getElement("$PATH/services/$f/contents");
        $self->handle_service(unescape($f), $srvc, $cont_el, $actions);
    }

    $self->process_actions($actions);

    return 1;
}

1; # Required for perl module!
