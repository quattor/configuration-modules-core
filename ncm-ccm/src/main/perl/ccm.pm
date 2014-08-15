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

use File::Temp;
use EDG::WP4::CCM::Fetch qw(NOQUATTOR NOQUATTOR_FORCE);

our $EC=LC::Exception::Context->new->will_store_all;

use constant TEST_COMMAND => qw(/usr/sbin/ccm-fetch -cfgfile /proc/self/fd/0);

sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $t = $config->getElement("/software/components/ccm")->getTree();

    my $fh = CAF::FileWriter->new($t->{configFile}, log => $self);
    delete($t->{active});
    delete($t->{dispatch});
    delete($t->{dependencies});
    delete($t->{configFile});
    delete($t->{version});

    while (my ($k, $v) = each(%$t)) {
        print $fh "$k $v\n";
    }

    # Check that ccm-fetch can work with the new file.
    # In presence of NOQUATTOR file, 
    # test using --force-quattor (to bypass the NOQUATTOR lock) 
    # and new temporary directory as cache_root (commandline precedes configfile)
    # (cache_root dir in configfile can be tested for write permissions?)
      
    my $cmd = [TEST_COMMAND];
    my $tmpcache;
    if (-f NOQUATTOR) {
        # is the cache_root set in the config file?
        # TODO (new) cache_root needs to be initialised or next ncm-ncd will fail [fail when new cache_root is set withh NOQUATTOR?]
        #   ccm.conf value is ncm-ncd default
        # TODO how to test the cache_root? setup CacheManager instance with 
        # what is the goal of ccm.pm? end result ccm.conf should be default for ncm-ncd ?
        if ("$fh" =~ m/^\s*cache_root\s*=\s*(\S+)\s*$/m) {
            my $cfg_cache_root = $1;
            if ( -w $cfg_cache_root) {
                $self->debug(1, "NOQUATTOR: cache_root set in new confifg file to $cfg_cache_root and is writeable");
            } else {
                $self->error("NOQUATTOR: cache_root set in new confifg file to $cfg_cache_root and is not writeable");
                $fh->cancel();
                $fh->close();
                return 1;
            }
        }

        # make new tempdir (should be previously none-existing and empty)
        # is removed when out of scope
        $tmpcache =  File::Temp->newdir();

        # will contain sensitive data if ccm-fetch test is succesful
        if(! chmod(0700, $tmpcache) ){
            $self->error("NOQUATTOR : Failed to chown 0700 $tmpcache, won't test ccm-fetch: $!");
            $fh->cancel();
            $fh->close();
            return 1;
        };
        $self->verbose("NOQUATTOR: test ccm-fetch in temporary cache_root $tmpcache");
        push(@$cmd, '--'.NOQUATTOR_FORCE, "--cache_root=$tmpcache");        
    }
    my $errs = "";
    my $test = CAF::Process->new($cmd,
                                 log => $self, 
                                 stdin => "$fh",
                                 stderr => \$errs);
    $test->execute();
    if ($? != 0) {
        $self->error("failed to ccm-fetch with new config: $errs");
        $fh->cancel();
    }

    $fh->close();
    return 1;
}

1;
