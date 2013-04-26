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

use Encode;
use CAF::Process;
use CAF::FileEditor;
use CAF::FileWriter;
use LC::File;

use File::Basename;
use File::Copy;
use File::Path 'rmtree';
use Cwd;

use constant TMP_DOWNLOAD => '/tmp/ncm-gpfs-download';
use constant GPFSBIN => '/usr/lpp/mmfs/bin';
use constant GPFSCONFIGDIR => '/var/mmfs';
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

    my ($self, $config) = @_;

    my ($tmpfh, $tree, $contents);

    my $startcwd = create_tmpdir($self);
    return 1 if ($startcwd eq "1");

    # Save the date.
    my $date = localtime();

    my $useyum = 1; # default on

    my $cfgtr = $config->getElement("$mypath/cfg")->getTree;

    $useyum = $cfgtr->{useyum} if (exists($cfgtr->{useyum}));

    ## base rpms
    ## remove existing gpfs rpms if certain is not found
    ## - then install gpfs abse rpms from optional location
    ## -- location should be kept secret
    ## how to retrigger spma afterwards?
    my $baseinstalled = GPFSCONFIGDIR . "/.quattorbaseinstalled";
    my $basiccfg = GPFSCONFIGDIR . "/.quattorbasiccfg";
    if (! -f $baseinstalled) {
        remove_existing_rpms($self, $config, $useyum) || return 1;
        install_base_rpms($self, $config) || return 1;
        ## update?
        ## no!
        ## - stop here
        ## - next run should trigger spma which will
        ##   update to the correct rpms

        ## write the $baseinstalled file
        ## - set the date
        $tmpfh = CAF::FileWriter->open($baseinstalled,
                                       backup => ".old",
                                       log => $self,
                                      );
        print $tmpfh $date;
        $tmpfh->close();
    }

    ## get gpfs config file if not found
    if (! -f $basiccfg) {
        get_cfg($self, $config, $cfgtr) || return 1;

        ## write the $basiccfg file
        ## - set the date

        $tmpfh = CAF::FileWriter->open($basiccfg,
                                       backup => ".old",
                                       log => $self,
                                      );
        print $tmpfh $date;
        $tmpfh->close();
    }

    return 1 if (cleanup_tmpdir($self, $startcwd));
}

sub create_tmpdir {
    my $self = shift;
    # create download dir
    if (-e TMP_DOWNLOAD) {
        if (! rmtree([TMP_DOWNLOAD])) {
            $self->error("Failed to remove existing tmp download dir ",
                         TMP_DOWNLOAD.": $!");
            return 1;
        }
    }
    if (! mkdir(TMP_DOWNLOAD)) {
        $self->error("Failed to create tmp download dir ",
                     TMP_DOWNLOAD.": $!");
        return 1;
    }
    if (! chmod(0700, TMP_DOWNLOAD)) {
        $self->error("Failed to chmod 0700 tmp download dir ",
                     TMP_DOWNLOAD.": $!");
        return 1;
    }

    my $startcwd=getcwd;
    chomp($startcwd);
    # Untaint it
    if ($startcwd =~ qr|^([-+@\w./]+)$|) {
        $startcwd = $1;
    } else {
        $self->error("Couldn't untaint \$startcwd: [$startcwd]");
        return 1;
    }
    if (! chdir(TMP_DOWNLOAD)) {
        $self->error("Failed to change to directory ".TMP_DOWNLOAD);
        return 1;
    }
    return $startcwd;
}

sub cleanup_tmpdir {
    my $self = shift;
    my $startcwd = shift;
    # cleanup
    if (! chdir($startcwd)) {
        $self->error("Failed to change back to directory $startcwd.");
        return 1;
    }
    if (! rmtree([TMP_DOWNLOAD])) {
        $self->error("Failed to remove tmp download dir ".TMP_DOWNLOAD.": $!");
        return 1;
    };
    return 0;
}

sub runrpm {
    my $self = shift;
    my $config = shift;
    my $tr = shift;
    my @opts=@_;

    my @proxy;
    if ($tr && $tr->{'useproxy'}) {
        ## check if spma proxy is set and then use it
        my $spmapath="/software/components/spma";
        my $spmatr = $config->getElement($spmapath)->getTree;
        if ($spmatr->{'proxy'}) {
            push(@proxy, '--httpproxy', $spmatr->{'proxyhost'})
                if ($spmatr->{'proxyhost'});
            push(@proxy, '--httpport', $spmatr->{'proxyport'})
                if ($spmatr->{'proxyport'});
        } else {
            $self->error("No SPMA proxy set in $spmapath/proxy: ",
                         $spmatr->{'proxy'});
        };
    }

    my $rpmcmd = "/bin/rpm";

    my $proc = CAF::Process->new([$rpmcmd, "-v", @proxy, @opts],
                                 log => $self);
    my $output = $proc->output();

    if ($?) {
        $self->error("Error running ", join(" ", @{$proc->{COMMAND}}),
                     " output: $output");
        return;
    }

    return $output  || 1;
};

sub runyum {
    my $self = shift;
    my $tr = shift;
    my @opts=@_;

    my $yumcmd = "/usr/bin/yum";

    my $proc = CAF::Process->new([$yumcmd, "-y", @opts], log => $self);
    my $output = $proc->output();

    if ($?) {
        $self->error("Error running ", join(" ", @{$proc->{COMMAND}}),
                     " output: $output");
        return;
    }
    return $output  || 1;
};

sub runcurl {
    my $self = shift;
    my $config = shift;
    my $tmppath = shift;
    my $tr = shift;
    my @opts=@_;

    my $curlcmd = "/usr/bin/curl";

    my @certscurl;

    if ($tr && $tr->{'useccmcertwithcurl'}) {
        ## use ccm certificates with curl?
        ## - does not work yet. curl cert is key_cert in one file
        ## -- like sindes_getcert client_cert_key
        my $ccmpath="/software/components/ccm";
        my $ccmtr = $config->getElement($ccmpath)->getTree;
        if ($ccmtr->{'cert_file'}) {
            push(@certscurl, '--cert', $ccmtr->{'key_file'})
                 if ($ccmtr->{'key_file'});
            push(@certscurl, '--cacert', $ccmtr->{'ca_file'})
                 if ($ccmtr->{'ca_file'});
        } else {
            $self->error("No CCM cert file set in $ccmpath/cert_file: ",
                         $ccmtr->{'cert_file'});
        };
    }

    if ($tr && $tr->{'usesindesgetcertcertwithcurl'}) {
        ## use sindesgetcert certificates with curl?
        my $sgpath="/software/components/sindes_getcert";
        my $sgtr = $config->getElement($sgpath)->getTree;
        if ($sgtr->{'client_cert_key'}) {
           push(@certscurl, '--cert',
                $sgtr->{'cert_dir'}."/".$sgtr->{'client_cert_key'})
                if ($sgtr->{'client_cert_key'});
           push(@certscurl, '--cacert',
                $sgtr->{'cert_dir'}."/".$sgtr->{'ca_cert'})
                if ($sgtr->{'ca_cert'});
        } else {
           $self->error("No sindes_getcert cert file set in ",
                        "$sgpath/client_cert_key: ".$sgtr->{'client_cert_key'});
        };
    }

    my $proc = CAF::Process->new([$curlcmd, "-s", "-f", @certscurl, @opts],
                                 log => $self);
    my $output = $proc->output();

    if ($?) {
        $self->error("Error running ", join(" ", @{$proc->{COMMAND}}),
                     " output: $output");
        return;
    }

    return $output || 1;
};


sub remove_existing_rpms {
    my $self = shift;
    my $config = shift;
    my $useyum = shift;
    my $ret = 1;
    my $tr;
    my $allrpms = runrpm($self, $config, $tr, "-q", "-a", "gpfs.*",
                         "--qf", "%{NAME} %{NAME}-%{VERSION}-%{RELEASE}\\n");
    return if (!$allrpms);

    my @removerpms;
    foreach my $found (split('\n', $allrpms)) {
        my @res=split(' ', $found);
        my $foundname=$res[0];
        my $foundfullname=$res[1];

        if (grep { $foundname =~ m/$_/ } GPFSRPMS) {
            push(@removerpms, $foundfullname);
        } else {
            $self->error("Not removing unknown found rpm that matched gpfs.*:",
                         " $found (full: $foundfullname). \n");
            $ret = 0;
        };
    };

    stopgpfs($self, 1);
    if (scalar @removerpms) {
        if ($useyum) {
            # for dependencies
            runyum($self, $tr, "remove", @removerpms) || return;
        } else {
            runrpm($self, $config, $tr, "-e", @removerpms) || return;
        };
    } else {
        $self->info("No rpms to be removed.")
    }

    return $ret;
};

sub install_base_rpms {
    my $self = shift;
    my $config = shift;
    my $ret = 1;
    if ($config->elementExists("$mypath/base")) {
        my $tr = $config->getElement("$mypath/base")->getTree;

        my @rpms;
        my @downloadrpms;
        foreach my $rpm (@{$tr->{'rpms'}}) {
            my $fullrpm = $tr->{'baseurl'}."/".$rpm;
            $fullrpm =~ s/\/\/$rpm/\/$rpm/;

            if ($tr->{'usecurl'}) {
                push(@downloadrpms, "-O", $fullrpm);
                push(@rpms, $rpm);
            } else {
                push(@rpms, $rpm);
            };
            $self->debug(2, "Added base rpm $rpm.")
        }

        my $tmp=TMP_DOWNLOAD;
        if (scalar @downloadrpms) {
            runcurl($self, $config, $tmp, $tr, @downloadrpms) || return ;
        };

        ##  gpfs complains about libstdc++.so.5, but it's not needed
        runrpm($self, $config, $tr, "-U", "--nodeps", @rpms) || return;

        ## cleanup downloaded rpms
        for my $rpm (@rpms) {
            $rpm = basename($rpm);
            if (-f "$tmp/$rpm") {
                if (unlink("$tmp/$rpm")) {
                    $self->debug(3, "File $tmp/$rpm deleted successfully.");
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
    my $self = shift;
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

    unshift(@cmds, $cmdexe);

    my $output = CAF::Process->new(\@cmds, log => $self)->output();
    my $cmd=join(" ", @cmds);

    if ($?) {
        $self->error("Error running '$cmd' output: $output");
        return;
    }
    return $output || 1;
};

sub stopgpfs {
    my $self = shift;
    my $neom = shift || 0;
    ## local shutdown
    return rungpfs($self, $neom, "mmshutdown");
};

sub startgpfs {
    my $self = shift;
    my $neom = shift || 0;
    ## local startup
    return rungpfs($self, $neom, "mmstartup");
};

sub get_cfg {
    my $self = shift;
    my $config = shift;
    my $tr = shift;
    my $ret = 1;
    my $url = $tr->{'url'};
    my $tmp=TMP_DOWNLOAD;
    my $output = runcurl($self, $config, $tmp, $tr, $url);
    return 0 if (! $output);

    # sanity check
    my $tmpcfg = $tmp."/".basename($url);

    my $subn = $tr->{'subnet'};
    my $hostname =  $config->getValue("/system/network/hostname");
    $subn =~ s/\./\\./g;
    my $regexp = "MEMBER_NODE.*$hostname\.$subn";

    my $gpfsconfigfh=CAF::FileWriter->open(GPFSCONFIG,
                                           backup => ".old",
                                           log => $self);
    my $gpfsnodeconfigfh=CAF::FileWriter->open(GPFSNODECONFIG,
                                               backup => ".old",
                                               log => $self);
    foreach (split /^/, $output) {
        print $gpfsconfigfh $_;

        # there should be only one...
        if (m/$regexp/) {
            if (length("$gpfsnodeconfigfh") > 0) {
                $self->error('Ignoring another node match for ',
                             'regexp $regexp found: $_.');
            } else {
                print $gpfsnodeconfigfh $_;
            };
        };
    }

    # check fulltxt content (curl -f should not generate any
    #   404-html pages or such, but you never know)
    if ("$gpfsconfigfh" !~ m/^%%.*VERSION_LINE/) {
        $self->error('Invalid config file found');
        $gpfsconfigfh->cancel();
        $gpfsnodeconfigfh->cancel();
        return 1;
    }
    $gpfsconfigfh->close();
    $gpfsnodeconfigfh->close();
};

# Required for end of module
1;