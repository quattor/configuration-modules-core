use strict;
use warnings;

package NCM::Component::spma::yumdnf;

use NCM::Component::spma::yum;
push our @ISA , qw(NCM::Component::spma::yum);

use constant YUM_CONF_FILE => "/etc/dnf/dnf.conf";

use constant REPOQUERY_FORMAT => qw(--nevra);

use constant REPO_DEPS => qw(repoquery -C --requires --resolve --qf %{NAME};%{ARCH});
# in dnf, whatrequires is passed as value to repoquery command
use constant REPO_WHATREQS => qw(repoquery -C --recursive --qf %{NAME}\n%{NAME};%{ARCH} --whatrequires);

use constant REPO_INCLUDE => 0;

# Completes any pending transactions
sub _do_complete_transaction
{
    my ($self) = @_;

    # Could be implmented using e.g. dnf remove $(dnf repoquery --duplicated --latest-limit=-1 -q)
    #   not sure it does what you think it does
    $self->debug(2, "Skipping complete_transaction, no DNF equivalent implemented");
    return 1;
}



1;

