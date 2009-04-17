# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::gmond;

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

use constant GMOND_PATH => '/software/components/gmond';



sub boolstr {
    my $b = shift;
    my $t = "false";
    $t = "true" if ( $b );
    return $t;
}

sub print_acl {
    my ($self, $fh,  $cfg) = @_;
    
    $fh->print("  acl {\n    default = \"$cfg->{default}\"\n");

    for my $i ( @{$cfg->{access}} ) {
        $fh->print("    access {\n",
                   "      ip = $i->{ip}\n",
                   "      mask = $i->{mask}\n",
                   "      action = \"$i->{action}\"\n",
                   "    }\n");
    }

    $fh->print("  }\n");
}

sub print_include {
    my ($self, $fh,  $cfg) = @_;
    for my $inc ( @{$cfg} ) {
        $fh->print("include('$inc')\n");
    }
}

sub print_cluster {
    my ($self, $fh,  $cfg) = @_;
    $fh->print("cluster {\n");
    $fh->print("  name = \"$cfg->{name}\"\n") if ( $cfg->{name} );
    $fh->print("  owner = \"$cfg->{owner}\"\n") if ( $cfg->{owner} );
    $fh->print("  latlong = \"$cfg->{latlong}\"\n") if ( $cfg->{latlong} );
    $fh->print("  url = \"$cfg->{url}\"\n") if ( $cfg->{url} );
    $fh->print("}\n\n");
}

sub print_host {
    my ($self, $fh,  $cfg) = @_;
    $fh->print("host {\n",
        "  location = \"$cfg->{location}\"\n",
        "}\n\n");
}

sub print_globals {
    my ($self, $fh,  $cfg) = @_;
    $fh->print("globals {\n");
    $fh->print("  daemonize = ".boolstr($cfg->{daemonize})."\n",) if ( $cfg->{daemonize} );
    $fh->print("  setuid = ".boolstr($cfg->{setuid})."\n",) if ( $cfg->{setuid} );
    $fh->print("  user = $cfg->{user}\n",) if ( $cfg->{user} );
    $fh->print("  debug_level = $cfg->{debug_level}\n",) if ( $cfg->{debug_level} );
    $fh->print("  mute = ".boolstr($cfg->{mute})."\n",) if ( $cfg->{mute} );
    $fh->print("  deaf = ".boolstr($cfg->{deaf})."\n",) if ( $cfg->{deaf} );
    $fh->print("  host_dmax = $cfg->{host_dmax}\n",) if ( $cfg->{host_dmax} );
    $fh->print("  cleanup_threshold = $cfg->{cleanup_threshold}\n",) if ( $cfg->{cleanup_threshold} );
    $fh->print("  gexec = ".boolstr($cfg->{gexec})."\n",) if ( $cfg->{gexec} );
    $fh->print("  send_metadata_interval = $cfg->{send_metadata_interval}\n",) if ( $cfg->{send_metadata_interval} );
    $fh->print("  module_dir = $cfg->{module_dir}\n",) if ( $cfg->{module_dir} );
        
    $fh->print("}\n\n");
}

sub print_udp_send_channel {
    my ($self, $fh,  $cfg) = @_;
    
    for my $i ( @{$cfg} ) {
        $fh->print("udp_send_channel {\n  port = $i->{port}\n");
        $fh->print("  mcast_join = $i->{mcast_join}\n",) if ( $i->{mcast_join} );
        $fh->print("  mcast_if = $i->{mcast_if}\n",) if ( $i->{mcast_if} );
        $fh->print("  host = $i->{host}\n",) if ( $i->{host} );
        $fh->print("  ttl = $i->{ttl}\n",) if ( $i->{ttl} );
        $fh->print("}\n\n");
    }
}

sub print_udp_recv_channel {
    my ($self, $fh,  $cfg) = @_;

    for my $i ( @{$cfg} ) {
        $fh->print("udp_recv_channel {\n  port = $i->{port}\n");
        $fh->print("  mcast_join = $i->{mcast_join}\n",) if ( $i->{mcast_join} );
        $fh->print("  mcast_if = $i->{mcast_if}\n",) if ( $i->{mcast_if} );
        $fh->print("  bind = $i->{bind}\n",) if ( $i->{bind} );
        $fh->print("  family = $i->{family}\n",) if ( $i->{family} );

        print_acl($self, $fh, $i->{acl}) if ( $i->{acl} );

        $fh->print("}\n\n");
    }
}

sub print_tcp_accept_channel {
    my ($self, $fh,  $cfg) = @_;

    for my $i ( @{$cfg} ) {
        $fh->print("tcp_accept_channel {\n  port = $i->{port}\n");
        $fh->print("  bind = $i->{bind}\n",) if ( $i->{bind} );
        $fh->print("  family = $i->{family}\n",) if ( $i->{family} );
        $fh->print("  timeout = $i->{timeout}\n",) if ( $i->{timeout} );
        print_acl($self, $fh, $i->{acl}) if ( $i->{acl} );

        $fh->print("}\n\n");
    }
}

sub print_metric {
    my ($self, $fh,  $cfg) = @_;
    $fh->print("  metric {\n    name = \"$cfg->{name}\"\n");
    $fh->print("    title = \"$cfg->{title}\"\n") if ( $cfg->{title} );
    $fh->print("    value_threshold = \"$cfg->{value_threshold}\"\n") if ( $cfg->{value_threshold} );
    $fh->print("  }\n");
}

sub print_collection_group {
    my ($self, $fh,  $cfg) = @_;

    for my $i ( @{$cfg} ) {
        $fh->print("collection_group {\n");
        $fh->print("  collect_once = ".boolstr($i->{collect_once})."\n") if ( $i->{collect_once} );
        $fh->print("  collect_every = $i->{collect_every}\n") if ( $i->{collect_every} );
        $fh->print("  time_threshold = $i->{time_threshold}\n") if ( $i->{time_threshold} );

        for my $j ( @{$i->{metric}} ) {
            print_metric($self, $fh, $j);
        }
        $fh->print("}\n\n");
        
    }
}

sub print_module {
    my ($self, $fh,  $cfg) = @_;

    return unless ($cfg);

    $fh->print("modules {\n");
    for my $i ( @{$cfg} ) {
        $fh->print("  module {\n");
        $fh->print("    name = \"$i->{name}\"\n");
        $fh->print("    language = \"$i->{language}\"\n") if ( $i->{language} );
        $fh->print("    path = \"$i->{path}\"\n") if ( $i->{path} );
        $fh->print("    params = \"$i->{params}\"\n") if ( $i->{params} );

        for my $k ( keys %{$i->{param}} ) {
            $fh->print("    param $k {\n    value = $i->{param}{$k}\n  }\n");
        }

        $fh->print("  }\n");
    }
    $fh->print("}\n\n");
}



sub Configure
{
    my ($self, $config) = @_;

    # daemon configuration
    if ( $config->elementExists(GMOND_PATH) ) {
        my $st = $config->getElement(GMOND_PATH)->getTree;

        # Location of the configuration file
        my $cfgfile = $st->{file};
        my $fh = FileHandle->new ($cfgfile, 'w');
        unless ($fh) {
            throw_error ("Couldn't open " . $cfgfile);
            return 0;
        }

        $fh->print ("# $cfgfile\n# written by ncm-gmond. Do not edit!\n");

        print_include($self, $fh,  $st->{include});
        print_cluster($self, $fh,  $st->{cluster});
        print_host($self, $fh,  $st->{host});
        print_globals($self, $fh,  $st->{globals});
        print_udp_send_channel($self, $fh,  $st->{udp_send_channel});
        print_udp_recv_channel($self, $fh,  $st->{udp_recv_channel});
        print_tcp_accept_channel($self, $fh,  $st->{tcp_accept_channel});
        print_collection_group($self, $fh,  $st->{collection_group});
        print_module($self, $fh,  $st->{module});

        chmod (0640, $cfgfile);

        execute (["/etc/init.d/gmond", "restart"]);
    }


    return 1;
}
