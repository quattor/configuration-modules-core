#${PMcomponent}

=pod

=head1 NAME

The I<ccm> component manages the configuration file
for CCM.

=head1 DESCRIPTION

The I<ccm> component manages the configuration file for the CCM
daemon.  This is usually the /etc/ccm.conf file. See the ccm-fetch
manpage for more details.

=cut

use parent qw(NCM::Component CAF::Path);

use CAF::Process;
use CAF::FileWriter;
use CAF::FileReader;
use LC::Exception;

use File::Temp qw(tempdir);
use File::Path qw(rmtree);

use EDG::WP4::CCM::Fetch qw(NOQUATTOR);

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use constant TEST_COMMAND => qw(/usr/sbin/ccm-fetch --cfgfile);
use constant TEMPDIR_TEMPLATE => "/tmp/ncm-ccm-XXXXX";

# simple private method to test NOQUATTOR (allows mocking)
sub _is_noquattor
{
    return -f NOQUATTOR;
}

sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $t = $config->getTree($self->prefix());

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

    foreach my $key (sort keys %$t) {
        my $v = $t->{$key};
        my $value = ref($v) eq 'ARRAY' ? join(',', @$v) : $v;
        print $fh "$key $value\n" if length($value);
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
            stderr => \$errs
        );

        my $tmppath = tempdir(TEMPDIR_TEMPLATE);
        # Set strict permissions (can't have e.g. cache_path set to something else)
        if (! chmod(0700, $tmppath)) {
            $self->error("Failed to chmod 0700 tmpdir $tmppath: $!");
            $fh->cancel();
        } else {
            my $tmpfn = "$tmppath/$filename";
            $self->verbose("Creating tmp configfile $tmpfn for testing.");
            my $tmpfh = CAF::FileWriter->new($tmpfn);
            print $tmpfh "$fh";
            $tmpfh->close();

            $test->pushargs($tmpfn);

            $test->execute();
            if ($? != 0) {
                $self->error("failed to ccm-fetch with new config: $errs");
                $fh->cancel();
            }

            if(rmtree($tmppath)) {
                $self->verbose("Cleaning up tmpdir $tmppath");
            } else {
                $self->warn("Failed to cleanup tmpdir $tmppath: $!");
            }
        }
    }

    $fh->close();
    return 1;
}

1;
