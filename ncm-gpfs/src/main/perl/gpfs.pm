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
        remove_existing_rpms() || return 1;
        install_base_rpms() || return 1;
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

        my $output = CAF::Process->new(\@opts, log => $self)->output();
        my $cmd=join(" ",@opts);

        if ($?) {
            $self->error("Error running '$cmd' output: $output");
            return;
        } else {
            $self->debug(2,"Ran '$cmd' succesfully.")
        }
        return $output  || 1;
    };

    sub runcurl {
        my $tmppath = shift;
        my @opts=@_;
    
        my $curlcmd = "/usr/bin/curl";
        if (! -f $curlcmd) {
            $self->error("Curl cmd $curlcmd not found.");
            return;
        };
    
        unshift(@opts,$curlcmd,'-s');
        

        my $cwd=`pwd`;
        chomp($cwd);
        chdir($tmppath) || $self->error("Failed to change to directory $tmppath.") && return;
        my $output = CAF::Process->new(\@opts, log => $self)->output();
        chdir($cwd) || $self->error("Failed to change back to directory $cwd.") && return;

        my $cmd=join(" ",@opts);

        if ($?) {
            $self->error("Error running '$cmd' output: $output");
            return;
        } else {
            $self->debug(2,"Ran '$cmd' succesfully.")
        }
        return $output || 1;
    };


    sub remove_existing_rpms {
        my $ret = 1;
        my $allrpms = runrpm("-q","-a","gpfs.*","--qf","%{NAME}\\n");
        return if (!$allrpms);
            
        my @removerpms;
        for my $found (split('\n',$allrpms)) {
            if (grep { $found =~ m/$_/ } GPFSRPMS) {
                push(@removerpms, $found);
            } else {
                $self->error("Not removing unknown found rpm that matched gpfs.*: $found. \n");
                $ret = 0;
                
            }; 
        };  
    
        stopgpfs(1);
        if (scalar @removerpms) {
            runrpm("-e",@removerpms) || return;
        } else {
            $self->info("No rpms to be removed.")
        }
        
        return $ret;
    };

    sub install_base_rpms {
        my $ret = 1;
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
                ## - does not work yet. curl cert is key_cert in one file 
                ## -- like sindes_getcert client_cert_key
                my $ccmpath="/software/components/ccm";
                my $ccmtr = $config->getElement($ccmpath)->getTree;
                if (${%$ccmtr}{'cert_file'}) {
                    push(@certscurl,'--cert',${%$ccmtr}{'key_file'}) if (${%$ccmtr}{'key_file'});
                    push(@certscurl,'--cacert',${%$ccmtr}{'ca_file'}) if (${%$ccmtr}{'ca_file'});
                } else {
                    $self->error("No CCM cert file set in $ccmpath/cert_file: ".${%$ccmtr}{'cert_file'});
                };
            }

            if (${%$tr}{'usesindesgetcertcertwithcurl'}) {
                ## use sindesgetcert certificates with curl?
                my $sgpath="/software/components/sindes_getcert";
                my $sgtr = $config->getElement($sgpath)->getTree;
                if (${%$sgtr}{'cert_file'}) {
                    push(@certscurl,'--cert',${%$sgtr}{'cert_dir'}."/".${%$sgtr}{'client_cert_key'}) if (${%$ccmtr}{'client_cert_key'});
                    push(@certscurl,'--cacert',${%$sgtr}{'cert_dir'}."/".${%$sgtr}{'ca_cert'}) if (${%$ccmtr}{'ca_cert'});
                } else {
                    $self->error("No sindes_getcert cert file set in $sgpath/client_cert_key: ".${%$sgtr}{'client_cert_key'});
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
                runcurl($tmp,@certscurl,@downloadrpms) || return ;
            };         
            
            runrpm("-U",@proxy,@rpms) || return;
            
            ## cleanup downloaded rpms
            for my $rpm (@downloadrpms) {
                if (unlink("$tmp/$rpm") == 0) {
                    $self->debug(3,"File $tmp/$rpm deleted successfully.");
                } else {
                    $self->error("File $tmp/$rpm was not deleted.");
                    $ret=0;
                }
            }
                
        } else {
            $self->error("base path $base/base not found.");
            $ret=0;
        };
        return $ret;
    };

    sub rungpfs {
        my $noerroronmissing = shift;
        my @cmds=@_;
    
        my $cmdexe = GPFSBIN."/".shift(@cmds);
        if (! -f $cmdexe) {
            if ($noerroronmissing) {
                $self->info("GPFS cmd $cmdexe not found.");
            } else {
                $self->error("GPFS cmd $cmdexe not found.");
            };
            return;
        };
    
        unshift(@cmds,$cmdexe);

        my $output = CAF::Process->new(\@cmds, log => $self)->output();
        my $cmd=join(" ",@cmds);

        if ($?) {
            $self->error("Error running '$cmd' output: $output");
            return;
        } else {
            $self->debug(2,"Ran '$cmd' succesfully.")
        }
        return $output || 1;
    };

    sub stopgpfs {
        my $neom = shift || 0;
        ## local shutdown
        return rungpfs($neom,"mmshutdown");
    };

    sub startgpfs {
        my $neom = shift || 0;
        ## local startup
        return rungpfs($neom,"mmstartup");
    };

}


# Required for end of module
1;  