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

# Given metaconfigservice C<$srv> and C<CAF::FileWriter> instance C<$fh>, 
# check if a daemon needs to be restarted. 
sub needs_restarting
{
    my ($self, $fh, $srv) = @_;

    return $fh->close() && $srv->{daemon} && scalar(@{$srv->{daemon}});
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
        $self->error("Failed to render $file. Skipping");
        return;
    }

    if ($self->needs_restarting($fh, $srv)) {
        foreach my $d (@{$srv->{daemon}}) {
            $self->{daemons}->{$d} = 1;
        }
    }
    return 1;
}


sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement($PATH)->getTree();

    while (my ($f, $c) = each(%{$t->{services}})) {
        $self->handle_service(unescape($f), $c);
    }

    # Restart any daemons whose configurations we have changed.
    if ($self->{daemons}) {
        my $srv = CAF::Service->new([keys(%{$self->{daemons}})], log => $self);
        $srv->restart();
    }
    return 1;
}

1; # Required for perl module!
