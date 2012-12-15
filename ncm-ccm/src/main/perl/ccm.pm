# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::ccm;

use strict;
use NCM::Component;
use base qw(NCM::Component);
use vars qw(@ISA $EC);
use CAF::Process;
use CAF::FileWriter;
use LC::Exception;

our $EC=LC::Exception::Context->new->will_store_all;


sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $t = $config->getElement("/software/components/ccm")->getTree();

    my $fh = CAF::FileWriter->new($t->{config_file}, log => $self);
    delete($t->{active});
    delete($t->{dispatch});
    delete($t->{dependencies});
    delete($t->{config_file});

    while (my ($k, $v) = each(%$t)) {
	print $fh "$k $v\n";
    }

    # Check that ccm-fetch can work with the new file.
    my $errs = "";
    my $test = CAF::Process->new([qw(/usr/sbin/ccm-fetch -config /dev/fd/0)],
				 log => $self, stdin => "$fh",
				 stderr => \my $errs);
    $test->execute();
    if ($? != 0) {
        $self->error("failed to ccm-fetch with new config: $errs");
	$fh->cancel();
    }

    $fh->close();
    return 1;
}

1;
