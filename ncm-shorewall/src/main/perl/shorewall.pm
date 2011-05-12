# ${license-info}
# ${developer-info}
# ${author-info}

#
# shorewall - NCM Shorewall configuration component
#
# Configure the ntp time daemon
#
################################################################################

package NCM::Component::shorewall;

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


my $compname = "NCM-shorewall";
my $mypath = '/software/components/shorewall';

use constant SHOREWALLCFGDIR => "/etc/shorewall/";

## shorewall v4 config

use constant ZONES => qw( zone
                          type
                          options
                          inoptions
                          outoptions  
                         );

use constant INTERFACES => qw(zone
                              interface
                              broadcast
                              options    
                              );

use constant RULES => qw(action
                         src
                         dst
                         proto
                         dstport
                         srcport
                         origdst
                         rate
                         user
                         mark
                         connlimit
                         time
                         );

use constant SHOREWALL_BOOLEAN => qw (startup_enabled
                                      );
use constant SHOREWALL_STRING => qw(ip_forwading
                                    );

##########################################################################
sub Configure {
##########################################################################

    our ($self,$config)=@_;

    my ($result,$tree,$contents,$type);
    
    my %reload;
    
    # Save the date.
    my $date = localtime();

    sub rollback {
        my $relref = shift;
        ## all entries with non-zero value have to be rolled back. 
        ## also the ones with -1!
        foreach my $typ (keys %$relref) {
            if (%$relref->{$typ}) {
                my $cfgfile=SHOREWALLCFGDIR.$typ;
                $cfgfile .=".conf" if ($typ eq "shorewall"); 
                ## move file to .failed
                my $src=$cfgfile;
                my $dst="$cfgfile.failed";
                if (LC::File::move($src,$dst)) {
                    $self->debug(2,"Moved $src to $dst");
                } else {
                    $self->error("Failed to move $src to $dst");
                }
                ## if .old exists, move that to 
                my $src="$cfgfile.old";
                my $dst=$cfgfile;
                if (-e $src && LC::File::move($src,$dst)) {
                    $self->debug(2,"Moved $src to $dst");
                } else {
                    $self->error("Failed to move $src to $dst");
                }
            } else {
                $self->debug(2,"Not rolling back $typ.");
            }
        };
    };

    
    sub writecfg {
        my $typ = shift;
        my $contents = shift;
        my $refreload = shift;
        my $changed = 0;
        my $cfgfile=SHOREWALLCFGDIR.$typ;
        $cfgfile .=".conf" if ($typ eq "shorewall"); 
        if ( -e $cfgfile && (LC::File::file_contents($cfgfile) eq $contents)) {
            $self->debug(2,"Nothing changed for $typ.")
        } else {
            ## write cfgfile
            $changed = 1;
            $result = LC::Check::file( $cfgfile,
                               backup => ".old",
                               contents => encode_utf8($contents),
                              );
            if ($result) {
                $self->log("$cfgfile updated");
            } else {
                $self->error("$cfgfile update failed");
                $changed=-1;
            }
        }
        %$refreload->{$typ}=$changed;
        if ($changed < 0) {
            rollback($refreload);
        }        
        return $changed;                
    }



    sub tostring {
        my $ref=shift;

        if (ref($ref) eq "ARRAY") {
            return join(",",@$ref);
        } elsif (ref($ref) eq "SCALAR") {
        } elsif (ref($ref) eq "HASH") {
        } else {
            ## not a ref, just string
            return $ref;
        }
    };


    
    #### BEGIN ZONES
    $type="zones";
    $tree=$config->getElement("$mypath/$type")->getTree;
    $contents="##\n## $type config created by shorewall\n##\n";
    foreach my $tr (@$tree) {
        foreach my $kw (ZONES) {
            my $val = "-";
            $val = tostring(%$tr->{$kw}) if (exists(%$tr->{$kw}));
            $val.=":".tostring(%$tr->{'parent'}) if (($kw eq "zone") && exists(%$tr->{'parent'}));  
            $contents.="$val\t";
        }
        $contents.="\n";
    }
    return 1 if (writecfg($type,$contents,\%reload) < 0);
    #### END ZONES

    #### BEGIN INTERFACES
    $type="interfaces";
    $tree=$config->getElement("$mypath/$type")->getTree;
    $contents="##\n## $type config created by shorewall\n##\n";
    foreach my $tr (@$tree) {
        foreach my $kw (INTERFACES) {
            my $val = "-";
            $val = tostring(%$tr->{$kw}) if (exists(%$tr->{$kw}));
            $val.=":".tostring(%$tr->{'port'}) if (($kw eq "interface") && exists(%$tr->{'port'}));
            $contents.="$val\t";
        }
        $contents.="\n";
    }
    return 1 if (writecfg($type,$contents,\%reload) < 0);
    #### END INTERFACES

    
    #### BEGIN RULES
    $type="rules";
    $tree=$config->getElement("$mypath/$type")->getTree;
    $contents="##\n## $type config created by shorewall\n##\n";
    foreach my $tr (@$tree) {
        foreach my $kw (RULES) {
            my $val = "-";
            if (exists(%$tr->{$kw})) {
                if (($kw eq "src") || ($kw eq "dst")) {
                    my $tmp=%$tr->{$kw};
                    $val = $tmp->{'zone'};
                    $val .= ":".tostring($tmp->{'interface'}) if (exists($tmp->{'interface'}));
                    $val .= ":".tostring($tmp->{'address'}) if (exists($tmp->{'address'}));
                } else {
                    $val = tostring(%$tr->{$kw});
                }
            };
            $val = uc($val) if ($kw eq "action");
            $val .= ":".tostring(%$tr->{'group'}) if ($kw eq "user" && exists(%$tr->{'group'}));
            $contents.="$val\t";
        }
        $contents.="\n";
    }
    return 1 if (writecfg($type,$contents,\%reload) < 0);
    #### END RULES

    #### BEGIN CONFIG
    $type="shorewall";
    $tree=$config->getElement("$mypath/$type")->getTree;
    my $head="##\n## $type config created by shorewall\n##\n";
    $contents=LC::File::file_contents(SHOREWALLCFGDIR.$type.".conf");
    $contents = $head.$contents if (! $contents =~ m/$head/);
    foreach my $kw (SHOREWALL_BOOLEAN) {
        my $ukw=uc($kw);
        if (exists(%$tree->{$kw})) {
            my $new="No";
            $new = "Yes" if (%$tree->{$kw});
            my $reg="^".$ukw.".*\$";
            $contents =~ s/$reg/$ukw=$new/m
        };
    }
    foreach my $kw (SHOREWALL_STRING) {
        my $ukw=uc($kw);
        if (exists(%$tree->{$kw})) {
            my $new=%$tree->{$kw};
            my $reg="^".$ukw.".*\$";
            $contents =~ s/$reg/$ukw=$new/m
        };
    }
    return 1 if (writecfg($type,$contents,\%reload) < 0);
    #### END CONFIG


    #### restart/reload/test/rollback
    sub restartreload {
        my $restart = shift;
        if($restart) {
            $self->info("Going to restart.");
            CAF::Process->new([qw(/etc/init.d/shorewall stop)],
                log => $self)->run();
            CAF::Process->new([qw(/etc/init.d/shorewall start)],
                log => $self)->run();
        } else {
            $self->info("Going to reload.");
            CAF::Process->new([qw(/etc/init.d/shorewall reload)],
                log => $self)->run();
        }
    };


    sub testfail {
        my $fail=1;
        ## sometimes it's possible that routing is a bit behind, so set this variable to some larger value
        my $sleep_time = 15;
        sleep($sleep_time);
        
        CAF::Process->new([qw(/usr/sbin/ccm-fetch)],
                    log => $self)->run();
        my $exitcode=$?;
        if ($? == 0) {
            $self->debug(2,"ccm-fetch OK");
            $fail = 0;
        } else {
            $self->error("ccm-fetch FAILED");
        }
        return $fail;
    }


    my $r=0;
    foreach $type (keys %reload){
        $r=$reload{$type} || $r;
    }

    if ($r) {
        restartreload($reload{'shorewall'});
        if ($r && testfail()) {
            $self->error("New config fails test. Going to revert to old config.");
            ## roll back
            rollback(\%reload);        
            ## restart
            restartreload($reload{'shorewall'});
            ## retest
            if (testfail()) {
                $self->error("Restoring old config still fails test.");
            }
        }    
    } else {
        $self->debug(2,"Nothing to restart/reload.");
    }
    
}


# Required for end of module
1;  