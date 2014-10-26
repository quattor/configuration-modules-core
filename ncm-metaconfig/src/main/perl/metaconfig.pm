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

# Has to correspond to what is allowed in the schema
Readonly::Hash my %ALLOWED_ACTIONS => { restart => 1, reload => 1, stop_sleep_start => 1 };

our $EC=LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

# Keep track of all actions to be taken in a hash
# key = action; value = array ref to with all actions
my %actions = ();

# Convenience method to retrieve actions (mainly for unittests)
# Returns a reference to the actions hash
sub get_actions
{
    my $self = shift;
    return \%actions;
}

# Convenience method to reset actions (mainly for unittests)
sub reset_actions
{
    my $self = shift;
    %actions = ();
}

# Add action for daemon
sub add_action
{
    my ($self, $daemon, $action) = @_;
    
    $actions{$action} = () if (! $actions{$action});
    if (! grep {$_ eq $daemon} @{$actions{$action}}) {
        $self->debug(1, "Adding daemon $daemon action with action $action");
        push(@{$actions{$action}}, $daemon);
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
    while (my ($action, $ds) = each %actions) {
        my $msg = "action $action for daemons ".join(',', @$ds);
        my $srv = CAF::Service->new($ds, log => $self);
        if(exists($ALLOWED_ACTIONS{$action})) {
            $self->verbose("Taking $msg");                
            $srv->$action();
        } else {
            $self->error("No CAF::Service allowed action $action; no $msg");                
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

    $self->reset_actions();
    
    while (my ($f, $c) = each(%{$t->{services}})) {
        $self->handle_service(unescape($f), $c);
    }

    $self->process_actions();

    return 1;
}

1; # Required for perl module!
