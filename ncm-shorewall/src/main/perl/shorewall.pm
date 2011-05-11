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

##########################################################################
sub Configure {
##########################################################################

    our ($self,$config)=@_;

    my ($result,$tree,$contents,$type);
    
    my %reload;
    
    # Save the date.
    my $date = localtime();

    sub writecfg {
        my $typ = shift;
        my $contents = shift;
        my $refreload = shift;
        my $changed = 0;
        my $cfgfile=SHOREWALLCFGDIR.$typ;
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
                return -1;
            }
        }
        %$refreload->{$typ}=$changed;
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

    #### add ccm-fetch test. in case of failure, roll back cfg.

}


# Required for end of module
1;  