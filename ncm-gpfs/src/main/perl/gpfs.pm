# ${license-info}
# ${developer-info}
# ${author-info}

#
# gpfs - NCM GPFS component
#
# Configure the ntp time daemon
#
################################################################################

package NCM::Component::gpfs;

#
# a few standard statements, mandatory for all components
#

use strict;
use LC::Check;
use NCM::Check;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use CAF::Process;
use CAF::FileEditor;
use LC::File;

use File::Basename;
use Encode qw(encode_utf8);

use constant GPFSBIN => '/usr/lpp/mmfs/bin';
use constant GPFSCONFIGDIR => '/var/mmfs/';
use constant GPFSCONFIG => '/var/mmfs/gen/mmsdrfs';
use constant GPFSNODECONFIG => '/var/mmfs/gen/mmfsNodeData';
use constant GPFSRPMS => qw(
                            ^gpfs.base$
                            ^gpfs.docs$
                            ^gpfs.gpl$
                            ^gpfs.gplbin-\d\S+$
                            ^gpfs.gui$
                            ^gpfs.msg.en_US$
                           );

my $compname = "NCM-gpfs";
my $mypath = '/software/components/gpfs';


##########################################################################
sub Configure {
##########################################################################

    our ($self,$config)=@_;

    our $base;
    my ($result,$tree,$contents);
    
    # Save the date.
    my $date = localtime();
    
    $base="$mypath";  

    ## base rpms
    ## remove existing gpfs rpms if certain is not found
    ## - then install gpfs abse rpms from optional location
    ## -- location should be kept secret
    ## how to retrigger spma afterwards?
    my $baseinstalled = GPFSCONFIGDIR . "/.quattorbaseinstalled";
    if ( ! -f $baseinstalled) {
        remove_existing_rpms();
        install_base_rpms();
        ## update? 
        ## no! 
        ## - stop here 
        ## - next run should trigger spma which will update to the correct rpms
        
        ## write the $baseinstalled file
        ## - set the date
        $result = LC::Check::file( $baseinstalled,
                                  backup => ".old",
                                  contents => encode_utf8($date),
                                );
        if ($result) {
            $self->info("$baseinstalled set");
        } else {
            $self->error("$baseinstalled failed");
            return 1;
        }
        
    } else {;
        ## write sort of quorum mechanism to get GFPS config
        ## try from list of servers, n/2+1 needs to agree, only that version is ok 

        ## get and modify single server machine file
    };


    sub runrpm {
        my @opts=@_;
    
        my $rpmcmd = "/bin/rpm";
        if (! -f $rpmcmd) {
            $self->error("Rpm cmd $rpmcmd not found.");
            return;
        };
    
        unshift(@opts,$rpmcmd,"-v");

        my $output = CAF::Process->new(@opts, log => $self)->output();
        my $cmd=join(" ",@opts);

        if ($?) {
            $self->error("Error running '$cmd' output: $output");
            return;
        } else {
            $self->debug(2,"Ran '$cmd' succesfully.")
        }
        return $output;
    };

    sub runcurl {
        my @opts=@_;
    
        my $curlcmd = "/usr/bin/rpm";
        if (! -f $rpmcmd) {
            $self->error("Curl cmd $curlcmd not found.");
            return;
        };
    
        unshift(@opts,$curlcmd);

        my $output = CAF::Process->new(@opts, log => $self)->output();
        my $cmd=join(" ",@opts);

        if ($?) {
            $self->error("Error running '$cmd' output: $output");
            return;
        } else {
            $self->debug(2,"Ran '$cmd' succesfully.")
        }
        return $output;
    };


    sub remove_existing_rpms {
        my $allrpms = runrpm("-q","-a","gpfs.*","--qf","%{NAME}\\n");
    
        my @removerpms;
        for my $found (split('\n',$allrpms)) {
            if (grep { $found =~ m/$_/ } GPFSRPMS) {
                push(@removerpms, $found);
            } else {
                $self->error("Not removing unknown found rpm that matched gpfs.*: $found. \n")
            }; 
        };  
    
        stopgpfs(0);
        if (scalar @removerpms) {
            runrpm("-e",@removerpms);
        } else {
            $self->info("No rpms to be removed.")
        }
    };

    sub install_base_rpms {
        if ($config->elementExists("$base/base")) {
            my $tr = $config->getElement("$base/base")->getTree;
    
            my @proxy;
            if (${%$tr}{'useproxy'}) {
                ## check if spma proxy is set and then use it
                my $spmapath="/software/components/spma";
                my $spmatr = $config->getElement($spmapath)->getTree;
                if (${%$spmatr}{'proxy'}) {
                    push(@proxy,'--httpproxy',${%$spmatr}{'proxyhost'}) if (${%$spmatr}{'proxyhost'});
                    push(@proxy,'--httpport',${%$spmatr}{'proxyport'}) if (${%$spmatr}{'proxyport'});
                } else {
                    $self->error("No SPMA proxy set in $spmapath/proxy: ".${%$spmatr}{'proxy'});
                };
            }
            
            my @certscurl;
            if (${%$tr}{'useccmcertwithcurl'}) {
                ## use ccm certificates with curl?
                my $ccmpath="/software/components/ccm";
                my $ccmtr = $config->getElement($ccmpath)->getTree;
                if (${%$ccmtr}{'cert_file'}) {
                    push(@certscurl,'--cert',${%$ccmtr}{'cert_file'}) if (${%$ccmtr}{'cert_file'});
                    push(@certscurl,'--cacert',${%$ccmtr}{'ca_file'}) if (${%$ccmtr}{'ca_file'});
                } else {
                    $self->error("No CCM cert file set in $ccmpath/cert_file: ".${%$ccmtr}{'cert_file'});
                };
            }

            my @rpms;
            my @downloadrpms;
            foreach my $rpm (@{${%$tr}{'rpms'}}) {
                my $fullrpm = ${%$tr}{'baseurl'}."/".$rpm;
                
                if (${%$tr}{'usecurl'}) {
                    push(@downloadrpms,"-O",$fullrpm);
                    push(@rpms,$rpm);
                } else {
                    push(@rpms,$rpm);
                };
                $self->debug(2,"Added base rpm $rpm.")
            }

            my $tmp="/tmp";
            if (scalar @downloadrpms) {
                runcurl($tmp,@sindescurl,@downloadrpms);
            };         
            
            runrpm("-U",@proxy,@rpms);
            
            ## cleanup downloaded rpms
            for my $rpm (@downloadrpms) {
                if (unlink("$tmp/$rpm") == 0) {
                    $self->debug(3,"File $tmp/$rpm deleted successfully.");
                } else {
                    $self->error("File $tmp/$rpm was not deleted.");
                }
            }
                
        } else {
            $self->error("base path $base/base not found.");
        };
    };

    sub rungpfs {
        my $erroronmissing = shift;
        my @cmds=@_;
    
        my $cmdexe = GPFSBIN."/".shift(@cmds);
        if (! -f $cmdexe) {
            if ($erroronmissing) {
                $self->error("GPFS cmd $cmdexe not found.");
            } else {
                $self->info("GPFS cmd $cmdexe not found.");
            };
            return;
        };
    
        unshift(@cmds,$cmdexe);

        my $output = CAF::Process->new(@cmds, log => $self)->output();
        my $cmd=join(" ",@cmds);

        if ($?) {
            $self->error("Error running '$cmd' output: $output");
            return;
        } else {
            $self->debug(2,"Ran '$cmd' succesfully.")
        }
        return $output;
    };

    sub stopgpfs {
        my $eom = shift || 1;
        ## local shutdown
        rungpfs($eom,"mmshutdown");
    };

    sub startgpfs {
        my $eom = shift || 1;
        ## local startup
        rungpfs($eom,"mmstartup");
    };

}


# Required for end of module
1;  