# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::spma;
#
# a few standard statements, mandatory for all components
#
use strict;
use warnings;
use NCM::Component;
our $EC=LC::Exception::Context->new->will_store_all;
our @ISA = qw(NCM::Component);
our $NoActionSupported = 1;

use constant CMP_TREE => "/software/components/spma";

sub Configure
{
    my ($self, $config) = @_;
    return $self->call_entry_point("Configure", $config);
}

sub Unconfigure
{
    my ($self, $config) = @_;
    return $self->call_entry_point("Unconfigure", $config);
}

sub call_entry_point
{
    my ($self, $entry_point, $config) = @_;
    my $t = $config->getElement(CMP_TREE)->getTree();

    my $packager;
    if (defined($t->{packager})) {
        $packager = $t->{packager};
        if ($packager =~ m/^(\w+)$/ && $1 eq $t->{packager}) {
            $packager = $1;
        } else {
            $self->error("Packager name contains illegal characters: " .
                         $t->{packager});
            return undef;
        }
    } else {
        $packager = 'yum';
    }

    my $submod = "NCM::Component::spma::$packager";
    eval "use $submod";
    if ($@) {
        $self->error("Failed to load $submod: $@");
        return undef;
    }

    my $NoAction = $self->{NoAction};
    bless($self, "$submod");
    $self->{NoAction} = $NoAction;
    return $self->$entry_point($config);
}

1; # required for Perl modules
