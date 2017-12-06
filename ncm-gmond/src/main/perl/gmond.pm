#${PMcomponent}

=head1 DESCRIPTION

The I<gmond> component manages Ganglia's gmond daemon.
This daemon collects information at a node and uses multicast to distribute it
over the network.

=cut

use CAF::FileWriter;
use CAF::Service;

use parent qw (NCM::Component);

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

sub boolstr
{
    my $b = shift;
    my $t = "false";
    $t = "true" if ( $b );
    return $t;
}

sub print_acl
{
    my ($self, $fh, $cfg) = @_;

    print $fh "  acl {\n    default = \"$cfg->{default}\"\n";

    for my $i ( @{$cfg->{access}} ) {
        print $fh "    access {\n",
            "      ip = $i->{ip}\n",
            "      mask = $i->{mask}\n",
            "      action = \"$i->{action}\"\n",
            "    }\n";
    }

    print $fh "  }\n";
}

sub print_include
{
    my ($self, $fh, $cfg) = @_;
    for my $inc ( @{$cfg} ) {
        print $fh "include('$inc')\n";
    }
}

sub print_cluster
{
    my ($self, $fh, $cfg) = @_;

    print $fh "cluster {\n";
    print $fh "  name = \"$cfg->{name}\"\n" if ( $cfg->{name} );
    print $fh "  owner = \"$cfg->{owner}\"\n" if ( $cfg->{owner} );
    print $fh "  latlong = \"$cfg->{latlong}\"\n" if ( $cfg->{latlong} );
    print $fh "  url = \"$cfg->{url}\"\n" if ( $cfg->{url} );
    print $fh "}\n\n";
}

sub print_host
{
    my ($self, $fh, $cfg) = @_;

    return unless ($cfg);

    print $fh "host {\n  location = \"$cfg->{location}\"\n}\n\n";
}

sub print_globals
{
    my ($self, $fh, $cfg) = @_;

    print $fh "globals {\n";
    print $fh "  daemonize = ".boolstr($cfg->{daemonize})."\n" if ( defined $cfg->{daemonize} );
    print $fh "  setuid = ".boolstr($cfg->{setuid})."\n" if ( defined $cfg->{setuid} );
    print $fh "  user = $cfg->{user}\n" if ( $cfg->{user} );
    print $fh "  debug_level = $cfg->{debug_level}\n" if ( $cfg->{debug_level} );
    print $fh "  mute = ".boolstr($cfg->{mute})."\n" if ( defined $cfg->{mute} );
    print $fh "  deaf = ".boolstr($cfg->{deaf})."\n" if ( defined $cfg->{deaf} );
    print $fh "  host_dmax = $cfg->{host_dmax}\n" if ( $cfg->{host_dmax} );
    print $fh "  host_tmax = $cfg->{host_tmax}\n" if ( $cfg->{host_tmax} );
    print $fh "  cleanup_threshold = $cfg->{cleanup_threshold}\n" if ( $cfg->{cleanup_threshold} );
    print $fh "  gexec = ".boolstr($cfg->{gexec})."\n" if ( defined $cfg->{gexec} );
    print $fh "  send_metadata_interval = $cfg->{send_metadata_interval}\n" if ( $cfg->{send_metadata_interval} );
    print $fh "  module_dir = $cfg->{module_dir}\n" if ( $cfg->{module_dir} );
    print $fh "  allow_extra_data = ".boolstr($cfg->{allow_extra_data})."\n" if ( defined $cfg->{allow_extra_data} );
    print $fh "  max_udp_msg_len = $cfg->{max_udp_msg_len}\n" if ( $cfg->{max_udp_msg_len} );

    print $fh "}\n\n";
}

sub print_udp_send_channel
{
    my ($self, $fh, $cfg) = @_;

    for my $i ( @{$cfg} ) {
        print $fh "udp_send_channel {\n  port = $i->{port}\n";
        print $fh "  mcast_join = $i->{mcast_join}\n" if ( $i->{mcast_join} );
        print $fh "  mcast_if = $i->{mcast_if}\n" if ( $i->{mcast_if} );
        print $fh "  host = $i->{host}\n" if ( $i->{host} );
        print $fh "  ttl = $i->{ttl}\n" if ( defined $i->{ttl} );
        print $fh "  bind = $i->{bind}\n" if ( $i->{bind} );
        print $fh "  bind_hostname = ".boolstr($i->{bind_hostname})."\n" if ( defined $i->{bind_hostname} );
        print $fh "}\n\n";
    }
}

sub print_udp_recv_channel
{
    my ($self, $fh, $cfg) = @_;

    for my $i ( @{$cfg} ) {
        print $fh "udp_recv_channel {\n  port = $i->{port}\n";
        print $fh "  mcast_join = $i->{mcast_join}\n" if ( $i->{mcast_join} );
        print $fh "  mcast_if = $i->{mcast_if}\n" if ( $i->{mcast_if} );
        print $fh "  bind = $i->{bind}\n" if ( $i->{bind} );
        print $fh "  family = $i->{family}\n" if ( $i->{family} );

        $self->print_acl($fh, $i->{acl}) if ( $i->{acl} );

        print $fh "}\n\n";
    }
}

sub print_tcp_accept_channel
{
    my ($self, $fh, $cfg) = @_;

    for my $i ( @{$cfg} ) {
        print $fh "tcp_accept_channel {\n  port = $i->{port}\n";
        print $fh "  bind = $i->{bind}\n" if ( $i->{bind} );
        print $fh "  family = $i->{family}\n" if ( $i->{family} );
        print $fh "  timeout = $i->{timeout}\n" if ( $i->{timeout} );
        $self->print_acl($fh, $i->{acl}) if ( $i->{acl} );

        print $fh "}\n\n";
    }
}

sub print_metric
{
    my ($self, $fh, $cfg) = @_;

    print $fh "  metric {\n    name = \"$cfg->{name}\"\n";
    print $fh "    title = \"$cfg->{title}\"\n" if ( $cfg->{title} );
    print $fh "    value_threshold = \"$cfg->{value_threshold}\"\n" if ( $cfg->{value_threshold} );
    print $fh "  }\n";
}

sub print_collection_group
{
    my ($self, $fh, $cfg) = @_;

    for my $i ( @{$cfg} ) {
        print $fh "collection_group {\n";
        print $fh "  collect_once = ".boolstr($i->{collect_once})."\n" if ( defined $i->{collect_once} );
        print $fh "  collect_every = $i->{collect_every}\n" if ( $i->{collect_every} );
        print $fh "  time_threshold = $i->{time_threshold}\n" if ( $i->{time_threshold} );

        for my $j ( @{$i->{metric}} ) {
            $self->print_metric($fh, $j);
        }
        print $fh "}\n\n";

    }
}

sub print_module
{
    my ($self, $fh, $cfg) = @_;

    return unless ($cfg);

    print $fh "modules {\n";
    for my $i ( @{$cfg} ) {
        print $fh "  module {\n";
        print $fh "    name = \"$i->{name}\"\n";
        print $fh "    language = \"$i->{language}\"\n" if ( $i->{language} );
        print $fh "    path = \"$i->{path}\"\n" if ( $i->{path} );
        print $fh "    params = \"$i->{params}\"\n" if ( $i->{params} );

        for my $k ( sort keys %{$i->{param}} ) {
            print $fh "    param $k {\n    value = $i->{param}{$k}\n  }\n";
        }

        print $fh "  }\n";
    }
    print $fh "}\n\n";
}



sub Configure
{
    my ($self, $config) = @_;

    # daemon configuration
    my $st = $config->getTree($self->prefix());

    # Location of the configuration file
    my $cfgfile = $st->{file};
    my $fh = CAF::FileWriter->new ($cfgfile, mode => oct(640), log => $self);

    print $fh "# $cfgfile\n# written by ncm-gmond. Do not edit!\n";

    $self->print_include($fh, $st->{include});
    $self->print_cluster($fh, $st->{cluster});
    $self->print_host($fh, $st->{host});
    $self->print_globals($fh, $st->{globals});
    $self->print_udp_send_channel($fh, $st->{udp_send_channel});
    $self->print_udp_recv_channel($fh, $st->{udp_recv_channel});
    $self->print_tcp_accept_channel($fh, $st->{tcp_accept_channel});
    $self->print_collection_group($fh, $st->{collection_group});
    $self->print_module($fh, $st->{module});

    if ($fh->close()) {
        CAF::Service->new(['gmond'], log => $self)->restart()
    };

    return 1;
}

1;
