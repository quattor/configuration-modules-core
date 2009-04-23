# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::gmetad;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;
use LC::Process qw (execute);
use LC::Exception qw (throw_error);

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use constant GMETAD_PATH => '/software/components/gmetad';
use constant GMETAD_FILE => '/etc/gmetad.conf';



sub print_host {
    my ($self, $fh,  $cfg) = @_;

    for my $i ( @{$cfg} ) {
        $fh->print(" $i->{address}");
        $fh->print(":$i->{port}") if ( $i->{port} );
    }
}

sub print_data_source {
    my ($self, $fh,  $cfg) = @_;

    for my $i ( @{$cfg} ) {
        $fh->print("data_source \"$i->{name}\" ");
        $fh->print("$i->{polling_interval} ") if ( $i->{polling_interval} );

        print_host($self, $fh, $i->{host});

        $fh->print("\n");
    }
}

sub Configure
{
    my ($self, $config) = @_;

    # daemon configuration
    if ( $config->elementExists(GMETAD_PATH) ) {
        my $st = $config->getElement(GMETAD_PATH)->getTree;

        # Location of the configuration file
        my $fh = FileHandle->new (GMETAD_FILE, 'w');
        unless ($fh) {
            throw_error ("Couldn't open " . GMETAD_FILE);
            return 0;
        }

        $fh->print ("# ".GMETAD_FILE."\n# written by ncm-gmetad. Do not edit!\n");

        # data sources
        print_data_source($self, $fh,  $st->{data_source});

        # daemon configuration
        $fh->print("debug_level $st->{debug_level}\n") if ( $st->{debug_level} );
        $fh->print("scalability $st->{scalability}\n") if ( $st->{scalability} );
        $fh->print("gridname \"$st->{gridname}\"\n") if ( $st->{gridname} );
        $fh->print("authority \"$st->{authority}\"\n") if ( $st->{authority} );

        $fh->print("all_trusted $st->{all_trusted}\n") if ( $st->{all_trusted} );
        if ( $st->{trusted_hosts} ) {
            $fh->print("trusted_hosts ");
            for my $i ( @{$st->{trusted_hosts}} ) {
                $fh->print("$i ");
            }
            $fh->print("\n");
        }

        $fh->print("setuid $st->{setuid}\n") if ( $st->{setuid} );
        $fh->print("setuid_username \"$st->{setuid_username}\"\n") if ( $st->{setuid_username} );
        $fh->print("xml_port $st->{xml_port}\n") if ( $st->{xml_port} );
        $fh->print("interactive_port $st->{interactive_port}\n") if ( $st->{interactive_port} );
        $fh->print("server_threads $st->{server_threads}\n") if ( $st->{server_threads} );
        $fh->print("rrd_rootdir \"$st->{rrd_rootdir}\"\n") if ( $st->{rrd_rootdir} );

        chmod (0644, GMETAD_FILE);

        execute (["/etc/init.d/gmetad", "restart"]);
    }


    return 1;
}
