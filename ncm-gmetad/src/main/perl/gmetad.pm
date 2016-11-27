#${PMpre} NCM::Component::gmetad${PMpost}

use CAF::FileWriter;
use CAF::Service;

use parent qw(NCM::Component);

our $NoActionSupported = 1;
our $EC = LC::Exception::Context->new->will_store_all;

sub print_host
{
    my ($self, $fh, $cfg) = @_;

    for my $i ( @{$cfg} ) {
        print $fh " $i->{address}";
        print $fh ":$i->{port}" if ( $i->{port} );
    }
}

sub print_data_source
{
    my ($self, $fh, $cfg) = @_;

    for my $i ( @{$cfg} ) {
        print $fh "data_source \"$i->{name}\" ";
        print $fh "$i->{polling_interval} " if ( $i->{polling_interval} );

        $self->print_host($fh, $i->{host});

        print $fh "\n";
    }
}

sub Configure
{
    my ($self, $config) = @_;

    # daemon configuration
    my $st = $config->getTree($self->prefix());
    if ( defined($st) ) {
        # Location of the configuration file
        my $cfgfile = $st->{file};
        my $fh = CAF::FileWriter->new ($cfgfile, mode => 0644, log => $self);

        print $fh "# $cfgfile\n# written by ncm-gmetad. Do not edit!\n";

        # data sources
        $self->print_data_source($fh,  $st->{data_source});

        # daemon configuration
        print $fh "debug_level $st->{debug_level}\n" if ( $st->{debug_level} );
        print $fh "scalability $st->{scalability}\n" if ( $st->{scalability} );
        print $fh "gridname \"$st->{gridname}\"\n" if ( $st->{gridname} );
        print $fh "authority \"$st->{authority}\"\n" if ( $st->{authority} );

        print $fh "all_trusted $st->{all_trusted}\n" if ( $st->{all_trusted} );
        if ( $st->{trusted_hosts} ) {
            print $fh "trusted_hosts ";
            for my $i ( @{$st->{trusted_hosts}} ) {
                print $fh "$i ";
            }
            print $fh "\n";
        }

        print $fh "setuid $st->{setuid}\n" if ( $st->{setuid} );
        print $fh "setuid_username \"$st->{setuid_username}\"\n" if ( $st->{setuid_username} );
        print $fh "xml_port $st->{xml_port}\n" if ( $st->{xml_port} );
        print $fh "interactive_port $st->{interactive_port}\n" if ( $st->{interactive_port} );
        print $fh "server_threads $st->{server_threads}\n" if ( $st->{server_threads} );
        print $fh "rrd_rootdir \"$st->{rrd_rootdir}\"\n" if ( $st->{rrd_rootdir} );

        if ($fh->close()) {
            CAF::Service->new(['gmetad'], log => $self)->restart()
        };
    }

    return 1;
}
