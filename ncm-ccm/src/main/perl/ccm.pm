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

use EDG::WP4::CCM::Fetch qw(NOQUATTOR);

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use constant TEST_COMMAND => qw(/usr/sbin/ccm-fetch -cfgfile /proc/self/fd/0);

# simple private method to test NOQUATTOR (allows mocking)
sub _is_noquattor
{
    return -f NOQUATTOR;
}

sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $t = $config->getElement("/software/components/ccm")->getTree();

    my $filename = $t->{configFile};

    my $current_config_content;
    if (_is_noquattor()) {
        # In presence of NOQUATTOR file, the new config is compared with current contents.
        # We have to read the current content early for unittesting with mocked CAF::File*
        my $curfh = CAF::FileReader->new($filename, log => $self);
        $current_config_content = "$curfh";
    };

    my $fh = CAF::FileWriter->new($filename, log => $self);

    delete($t->{active});
    delete($t->{dispatch});
    delete($t->{dependencies});
    delete($t->{configFile});
    delete($t->{version});

    while (my ($k, $v) = each(%$t)) {
        my $value = ref($v) eq 'ARRAY' ? join(',', @$v) : $v;
        print $fh "$k $value\n" if length($value);
    }

    if (_is_noquattor()) {
        # If there's no change, return without testing the current config.
        # If something changed in the content, an error is logged.
        #
        # In any case, no new config is written (incl. any changes to the file 
        # permisisons or ownership) and no profile fetched (e.g. for testing).

        $fh->cancel();

        my $msg_noquattor = NOQUATTOR." set, and";
        my $msg = "changes are pending to the CCM configfile $filename";
        if ("$fh" eq $current_config_content) {
            $self->info("$msg_noquattor no $msg.");
        } else {
            $self->error("$msg_noquattor $msg.");
        }
    } else {
        # Check that ccm-fetch can work with the new file.
        my $errs = "";
        my $test = CAF::Process->new(
            [TEST_COMMAND],
            log    => $self,
            stdin  => "$fh",
            stderr => \$errs
        );
        $test->execute();
        if ($? != 0) {
            $self->error("failed to ccm-fetch with new config: $errs");
            $fh->cancel();
        }
    }
    
    $fh->close();
    return 1;
}

1;
