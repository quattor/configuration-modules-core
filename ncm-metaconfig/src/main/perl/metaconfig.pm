# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;

use base qw(NCM::Component);

use LC::Exception;
use CAF::TextRender;
use CAF::Service;
use EDG::WP4::CCM::Element qw(unescape);
use Readonly;

Readonly::Scalar my $PATH => '/software/components/${project.artifactId}';

our $EC=LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

# Add action for daemon
sub add_action
{
    my ($self, $daemon, $action) = @_;
    
    $self->{_actions}->{$action} = () if (! $self->{_actions}->{$action});
    if (! grep {$_ eq $daemon} @{$self->{_actions}->{$action}}) {
        $self->debug(1, "Adding daemon $daemon action with action $action");
        push(@{$self->{_actions}->{$action}}, $daemon);
    }
}

# Given metaconfigservice C<$srv> and C<CAF::FileWriter> instance C<$fh>, 
# prepare the actions to be taken for the service service
sub prepare_action
{
    my ($self, $srv) = @_;

    $self->verbose('File changed, looking for daemons and actions');
    if ($srv->{daemons}) {
        while (my ($daemon, $action) = each %{$srv->{daemons}}) {
            $self->add_action($daemon, $action);
        }
    }

    if ($srv->{daemon}) {
        $self->verbose("Deprecated daemon(s) restart via daemon field.");
        foreach my $daemon (@{$srv->{daemon}}) {
            if ($srv->{daemons}->{$daemon}) {
                $self->verbose('Daemon $daemon also defined in daemons field. Adding restart action anyway.');
            }
            $self->add_action($daemon, 'restart');
        }
    }
}

# Restart any daemons whose configurations we have changed.
sub process_actions
{
    my $self = shift;
    while (my ($action, $ds) = each %{$self->{_actions}}) {
        my $msg = "action $action for daemons ".join(',', @$ds);
        my $srv = CAF::Service->new($ds, log => $self);
        my $method = $srv->can($action);
        if($method) {
            $self->verbose("Taking $msg");                
            $method->($srv);
        } else {
            $self->error("No CAF::Service method $action; no $msg");                
        }
    }
   
}

# Generate $file, configuring $srv using CAF::TextRender.
sub handle_service
{
    my ($self, $file, $srv) = @_;

    my $trd = CAF::TextRender->new($srv->{module},
                                   $srv->{contents},
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

    $self->prepare_action($srv) if ($fh->close());

    return 1;
}


sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement($PATH)->getTree();

    while (my ($f, $c) = each(%{$t->{services}})) {
        $self->handle_service(unescape($f), $c);
    }

    $self->process_actions() if ($self->{_actions});

    return 1;
}

1; # Required for perl module!
