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

use constant SHOREWALLCFGDIR = "/etc/shorewall/";

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

    our $base;
    my ($result,$tree,$contents,$type);
    
    my $reload =0;
    
    # Save the date.
    my $date = localtime();

    sub writecfg {
        my $typ = shift;
        my $contents = shift;
        my $changed = 0;
        my $cfgfile=SHOREWALLCFGDIR+$type;
        if ( -e $cfgfile && (LC::File::file_contents($cfgfile) eq $contents)) {
            $self->debug(2,"Nothing changed.")
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
        return $changed;                
    }
    
    #### BEGIN ZONES
    $type="zones";
    $tree=$config->etElement("$base/$type")->getTree;
    $contents="## Created by shorewall at $date\n##\n";
    foreach $tr (@$tree) {
        foreach my $kw (ZONES) {
            my $val = "-";
            if (exists(%$tr->{$kw})) {
                $val = %$tr->{$kw}; 
            };
            $contents.="$val\t";
        }
        $contents.="\n";
    }
    $reload = writecfg($type,$contents) || $reload;
    return 1 if ($reload < 0);
    #### END ZONES
    

}


# Required for end of module
1;  