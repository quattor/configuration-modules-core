# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::pvss - NCM pvss configuration and patching component
#
################################################################################


package NCM::Component::pvss;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use NCM::Check;
use Config::IniFiles;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use LC::File qw(copy remove move);
use LC::Check;

#few declarations
my (@patches, @nodes);
#define path
my $base = "/software/components/pvss";

sub Configure {
    my($self,$config) = @_;
    unless($config->elementExists($base)){
        return $self->error("pvss component is not defined");
    }
    my $rooturl=$config->getValue($base."/rooturl");
    my $pvsspath=$config->getValue($base."/pvsspath");
    $self->debug(4,"rooturl : $rooturl");
    $self->debug(4,"pvsspath : $pvsspath");
    
    #
    #copy licence file
    #
    if($config->elementExists($base."/licencefilename")){
        my @entries;
        my $licencefilename=$config->getValue($base."/licencefilename");
        $licencefilename=$rooturl."licences/".$licencefilename;
        my $shieldfile = $pvsspath."shield";
        my $cmd = "wget $licencefilename -O $shieldfile.tmp";
        $self->debug(2,"should do : $cmd");
        system($cmd);
        if ((stat("$shieldfile.tmp"))[7] > 0) {
          if (system("diff $shieldfile.tmp $shieldfile") >>8 == 0) {
            $self->debug(1,"Licence did not changed");
          } else {
            system("mv $shieldfile.tmp $shieldfile");
            $self->debug(1,"Licence file copied");
          }
        } elsif (!-e "$pvsspath/hw.txt") {
        
          my $hostname = `hostname`;
          chop $hostname;
          $self->debug(1,"Licence file empty : sending hardware code by mail");
          open TMP_FILE , ">", "$pvsspath/hw.txt";
          print TMP_FILE "Machine ".$hostname." does not have a PVSS licence. Here are the infos needed to ask for one.\n\nHardware code :\n";
          print TMP_FILE `LD_LIBRARY_PATH=$pvsspath/bin $pvsspath/bin/PVSStoolGetHw`;
          print TMP_FILE "\n\n----------------------------------\nuname -a :\n";
          print TMP_FILE `uname -a`;
          print TMP_FILE "\n\n";
          close TMP_FILE;
          my $mail_address;
          if ($config->elementExists($base."/mail_address")){
            $mail_address = $config->getValue($base."/mail_address");
          } else {
            $mail_address = "root";
          }
          `mail -s "No PVSS licence for host $hostname" $mail_address < $pvsspath/hw.txt`;
        } else {
            $self->debug(1,"Licence file empty : hardware code already sent by mail");
        }
    }
    
    #
    # apply patches if not already done
    #
    if($config->elementExists($base."/patches")){
        my $element = $config->getElement($base."/patches");
        while ($element->hasNextElement()) {
                my $p = $element->getNextElement();
                my $cn = $p->getName();
                my $patchName = $config->getValue($base."/patches/".$cn."/patchfilename");
                my $patchPresenceName = $config->getValue($base."/patches/".$cn."/patchpresencefilename");
                $self->debug(2,"filename: $patchName \t presencefilename: $patchPresenceName");
                if (! -f $pvsspath.$patchPresenceName) {
                        my $cmd = "cd $pvsspath; wget ".$rooturl."patches/$patchName; unzip -o $patchName; touch $patchPresenceName;rm $patchName";
                        $self->debug(2,"should do : $cmd");
                        system($cmd);
                } else {
                  $self->debug(2,"Patch already installed");
                }
        }
    }
    else{
        $self->debug(2,"No patch to apply");
    }
    
    #
    # Add checkMemory = 0 in section data of pvss config file if needed
    #
    my $configChanged = 0;
    if($config->elementExists($base."/datacheckmemoryhack") && ($config->getValue($base."/datacheckmemoryhack") eq "true")){
        my $cfg = new Config::IniFiles( -file => $pvsspath."/config/config" );
        if (!$cfg->SectionExists("data")) {
            $cfg->AddSection("data");
            $configChanged = 1;
        }
        if (defined($cfg->val("data", "checkMemory"))) {
            my $oldVal = $cfg->val("data", "checkMemory");
            if ($config->getValue($base."/datacheckmemoryhack") eq "true") {
                $cfg->setval("data", "checkMemory","0");
                if ($oldVal ne "0") {
                        $configChanged = 1;
                }
            } else {
                $cfg->setval("data", "checkMemory","1");
                if ($oldVal eq "0") {
                        $configChanged = 1;
                }
            }
        } else {
            $cfg->newval("data", "checkMemory","0");
            $configChanged = 1;
        }
        if ($configChanged) {
                $cfg->RewriteConfig();
                $self->debug(1,"Changed PVSS config (checkMemory = 0)");
        }
    }
    
    #
    # reset /tmp folder sticky bit if needed
    #
    if($config->elementExists($base."/stickybithack") && ($config->getValue($base."/stickybithack") eq "true")){
        LC::Check::mode("0777","/tmp");
        $self->debug(1,"resetted /tmp folder sticky bit");
    }
    
    #
    # make log folder world writable if needed
    #
    if($config->elementExists($base."/logfolderhack") && ($config->getValue($base."/logfolderhack") eq "true")){
        LC::Check::mode("0777",$pvsspath."log");
        $self->debug(1,"made log folder world writable");
    }
    
    #
    # Configure projects
    #
    if($config->elementExists($base."/projects")){
        my $element = $config->getElement($base."/projects");
        while ($element->hasNextElement()) {
            my $p = $element->getNextElement();
            my $cn = $p->getName();
            $self->debug(2,"project nb: $cn");
            my $projectuser='';
            my $projectname = $config->getValue($base."/projects/".$cn."/projectname");
            my $projectpath = $config->getValue($base."/projects/".$cn."/projectpath");
            $self->debug(2,"Configuring project: $projectname \t User: $projectuser");
            `mkdir -p /etc/pvss.d`;
            my $cfgfile = "/etc/pvss.d/".$projectname;
            stat $cfgfile or do {
              # create empty file only if map does not yet exist
              local(*TMPH);
              open TMPH,">$cfgfile" and close TMPH;
            };
            LC::Check::status("$cfgfile", owner=> "root", group=>"root", mode=>0644);
            NCM::Check::lines( $cfgfile,
              linere => "PVSS_II=.*",
              goodre => "PVSS_II=$projectpath",
              good   => "PVSS_II=$projectpath",
              keep   => "first",
              add    => "last" );
            if($config->elementExists($base."/projects/".$cn."/projectuser")){
                $projectuser = $config->getValue($base."/projects/".$cn."/projectuser");
                NCM::Check::lines( $cfgfile,
                linere => "PVSS_USER=.*",
                goodre => "PVSS_USER=$projectuser",
                good   => "PVSS_USER=$projectuser",
                keep   => "first",
                add    => "last" );
            } else {
                my %opt2;
                $opt2{source} = $cfgfile;
                $opt2{code} = sub {
                                        my($contents) = @_;
                                        my(@lines, $line, $lines);
                                        #
                                        # split contents
                                        #
                                        @lines = ();
                                        $contents = "" unless defined($contents);
                                        foreach $line (split(/\n/, $contents)) {
                                            if ($line !~ /PVSS_USER=.*/) {
                                                push(@lines, $line);
                                            }                                                 
                                        }
                                        $lines = join('\n', @lines);
                                        return($lines);
                                    };
                return(LC::Check::file($cfgfile, %opt2));
            }
        }
    }
}

