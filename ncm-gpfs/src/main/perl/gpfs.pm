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
use File::Copy;
use Cwd;

use constant TMP_DOWNLOAD => '/tmp/ncm-gpfs-download';
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

    # create download dir
    if(-e TMP_DOWNLOAD) {
        if(! unlink(TMP_DOWNLOAD) ){
            $self->error("Failed to remove existing tmp download dir ".TMP_DOWNLOAD);
            return 1;
        }
    }
    if(! mkdir(TMP_DOWNLOAD)) {
        $self->error("Failed to create tmp download dir ".TMP_DOWNLOAD);
        return 1;
    }
    if(! chmod(0700,TMP_DOWNLOAD)) {
        $self->error("Failed to chmod 0700 tmp download dir ".TMP_DOWNLOAD);
        return 1;
    }

    my ($result,$tree,$contents);

    # Save the date.
    my $date = localtime();

    my $useyum = 1; # default on
    my $cfgtr;

    if ($config->elementExists("$mypath/cfg")) {
        $cfgtr = $config->getElement("$mypath/cfg")->getTree;
    } else {
        $self->error("base path $mypath/cfg not found.");
        return 1;
    };

    $useyum = $cfgtr{useyum} if (exists($cfgtr{useyum}));

    ## base rpms
    ## remove existing gpfs rpms if certain is not found
    ## - then install gpfs abse rpms from optional location
    ## -- location should be kept secret
    ## how to retrigger spma afterwards?
    my $baseinstalled = GPFSCONFIGDIR . "/.quattorbaseinstalled";
    my $basiccfg = GPFSCONFIGDIR . "/.quattorbasiccfg";
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

        if ($useyum) {
            runyum('distro-sync');
        }

    } else {
        ## get gpfs config file if not found
        if ( ! -f $basiccfg) {
            get_cfg($cfgtr) || return 1;

            ## write the $basiccfg file
            ## - set the date
            $result = LC::Check::file( $basiccfg,
                                  backup => ".old",
                                  contents => encode_utf8($date),
                                );
            if ($result) {
                $self->info("$basiccfg set");
            } else {
                $self->error("$basiccfg failed");
                return 1;
            }
        }
    };

    # cleanup
    if(! unlink(TMP_DOWNLOAD) ){
        $self->error("Failed to remove tmp download dir ".TMP_DOWNLOAD);
        return 1;
    }


    sub runrpm {
        my $tr = shift;
        my @opts=@_;

        my @proxy;
        if ($tr && $tr->{'useproxy'}) {
            ## check if spma proxy is set and then use it
            my $spmapath="/software/components/spma";
            my $spmatr = $config->getElement($spmapath)->getTree;
            if ($spmatr->{'proxy'}) {
                push(@proxy,'--httpproxy',$spmatr->{'proxyhost'}) if ($spmatr->{'proxyhost'});
                push(@proxy,'--httpport',$spmatr->{'proxyport'}) if ($spmatr->{'proxyport'});
            } else {
                $self->error("No SPMA proxy set in $spmapath/proxy: ".$spmatr->{'proxy'});
            };
        }

        my $rpmcmd = "/bin/rpm";
        if (! -f $rpmcmd) {
            $self->error("Rpm cmd $rpmcmd not found.");
            return;
        };

        unshift(@opts,$rpmcmd,"-v",@proxy);

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

    sub runyum {
        my $tr = shift;
        my @opts=@_;

        my $yumcmd = "/usr/bin/yum";
        if (! -f $yumcmd) {
            $self->error("Yum cmd $yumcmd not found.");
            return;
        };

        unshift(@opts,$yumcmd,"-y");

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
        my $tr = shift;
        my @opts=@_;

        my $curlcmd = "/usr/bin/curl";
        if (! -f $curlcmd) {
            $self->error("Curl cmd $curlcmd not found.");
            return;
        };

        my @certscurl;

        if ($tr && $tr->{'useccmcertwithcurl'}) {
            ## use ccm certificates with curl?
            ## - does not work yet. curl cert is key_cert in one file
            ## -- like sindes_getcert client_cert_key
            my $ccmpath="/software/components/ccm";
            my $ccmtr = $config->getElement($ccmpath)->getTree;
            if ($ccmtr->{'cert_file'}) {
                push(@certscurl,'--cert',$ccmtr->{'key_file'}) if ($ccmtr->{'key_file'});
                push(@certscurl,'--cacert',$ccmtr->{'ca_file'}) if ($ccmtr->{'ca_file'});
            } else {
                $self->error("No CCM cert file set in $ccmpath/cert_file: ".$ccmtr->{'cert_file'});
            };
        }

        if ($tr && $tr->{'usesindesgetcertcertwithcurl'}) {
            ## use sindesgetcert certificates with curl?
            my $sgpath="/software/components/sindes_getcert";
            my $sgtr = $config->getElement($sgpath)->getTree;
            if ($sgtr->{'client_cert_key'}) {
               push(@certscurl,'--cert',$sgtr->{'cert_dir'}."/".$sgtr->{'client_cert_key'}) if ($sgtr->{'client_cert_key'});
               push(@certscurl,'--cacert',$sgtr->{'cert_dir'}."/".$sgtr->{'ca_cert'}) if ($sgtr->{'ca_cert'});
            } else {
               $self->error("No sindes_getcert cert file set in $sgpath/client_cert_key: ".$sgtr->{'client_cert_key'});
            };
        }


        unshift(@opts,$curlcmd,'-s','-f',@certscurl);


        my $cwd=getcwd;
        chomp($cwd);
        # Untaint it
        if ( $cwd =~ qr|^([-+@\w./]+)$| ) {
            $cwd = $1;
        } else {
            $self->error("Couldn't untaint \$cwd: [$cwd]") && return ;
        }
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
        my $tr;
        my $allrpms = runrpm($tr,"-q","-a","gpfs.*","--qf","%{NAME} %{NAME}-%{VERSION}-%{RELEASE}\\n");
        return if (!$allrpms);

        my @removerpms;
        for my $found (split('\n',$allrpms)) {
            my @res=split(' ',$found);
            my $foundname=$res[0];
            my $foundfullname=$res[1];

            if (grep { $foundname =~ m/$_/ } GPFSRPMS) {
                push(@removerpms, $foundfullname);
            } else {
                $self->error("Not removing unknown found rpm that matched gpfs.*: $found (full: $foundfullname). \n");
                $ret = 0;
            };
        };

        stopgpfs(1);
        if (scalar @removerpms) {
            if ($useyum) {
                # for dependencies
                runyum($tr,"remove",@removerpms) || return;
            } else {
                runrpm($tr,"-e",@removerpms) || return;
            };
        } else {
            $self->info("No rpms to be removed.")
        }

        return $ret;
    };

    sub install_base_rpms {
        my $ret = 1;
        if ($config->elementExists("$mypath/base")) {
            my $tr = $config->getElement("$mypath/base")->getTree;

            my @rpms;
            my @downloadrpms;
            foreach my $rpm (@{$tr->{'rpms'}}) {
                my $fullrpm = $tr->{'baseurl'}."/".$rpm;
                $fullrpm =~ s/\/\/$rpm/\/$rpm/;

                if ($tr->{'usecurl'}) {
                    push(@downloadrpms,"-O",$fullrpm);
                    push(@rpms,$rpm);
                } else {
                    push(@rpms,$rpm);
                };
                $self->debug(2,"Added base rpm $rpm.")
            }

            my $tmp=TMP_DOWNLOAD;
            if (scalar @downloadrpms) {
                runcurl($tmp,$tr,@downloadrpms) || return ;
            };

            ##  gpfs complains about libstdc++.so.5, but it's not needed
            runrpm($tr,"-U","--nodeps",@rpms) || return;

            ## cleanup downloaded rpms
            for my $rpm (@rpms) {
                $rpm = basename($rpm);
                if (-f "$tmp/$rpm") {
                    if(unlink("$tmp/$rpm")) {
                        $self->debug(3,"File $tmp/$rpm deleted successfully.");
                    } else {
                        $self->error("File $tmp/$rpm was not deleted.");
                        $ret=0;
                    }
                }
            }

        } else {
            $self->error("base path $mypath/base not found.");
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

    sub get_cfg {
        my $tr = shift;
        my $ret = 1;
        my $url = $tr->{'url'};
        my $tmp=TMP_DOWNLOAD;
        runcurl($tmp,$tr,"-O",$url) || return 0;
        # sanity check
        my $tmpcfg = $tmp."/".basename($url);

        my $subn = $tr->{'subnet'};
        my $hostname =  $config->getValue("/system/network/hostname");
        $subn =~ s/\./\\./g;
        my $regexp = "^MEMBER_NODE.*$hostname\.$subn";

        my $fulltxt='';
        my $txt='';
        if(open(FH,$tmpcfg)) {
            while (<FH>) {
                $fulltxt .= $_;
                ## there should be only one...
                if (m/$regexp/) {
                    if (length($txt) > 0) {
                        $self->error('Ignoring another node match for regexp $regexp found: $_.');
                    } else {
                        $txt .= $_
                    };
                };
            }
            close(FH);

            ## check fulltxt content (curl -f should not generate any 404-html pages or such, but you never know)
            if (! $fulltxt ~= m/^%%.*VERSION_LINE/) {
                $self->error('Invalid config file found');
                return 1;
            }

            # write config
            my $result = LC::Check::file( GPFSCONFIG,
                                  backup => ".old",
                                  contents => encode_utf8($fulltxt),
                                );
            if ($result) {
                $self->info(GPFSCONFIG." set");
            } else {
                $self->error(GPFSCONFIG." failed");
                return 1;
            }

            # write nodeconfig
            my $result = LC::Check::file( GPFSNODECONFIG,
                                  backup => ".old",
                                  contents => encode_utf8($txt),
                                );
            if ($result) {
                $self->info(GPFSNODECONFIG." set");
            } else {
                $self->error(GPFSNODECONFIG." failed");
                return 1;
            }

        } else {
             $self->error("Can't open $tmpcfg for reading.");
             return 0;
        };
    };

}


# Required for end of module
1;