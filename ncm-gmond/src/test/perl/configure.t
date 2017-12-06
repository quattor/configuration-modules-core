use strict;
use warnings;
use Test::More;
use Test::Quattor qw(configure);
use NCM::Component::gmond;

my $cmp = NCM::Component::gmond->new('gmond');
my $cfg = get_config_for_profile('configure');
is($cmp->Configure($cfg), 1, "Configure ran succesfully");

my $cmd = get_command("service gmond restart");
ok($cmd, "Daemon was restarted with (new) configuration" );

my $text = <<EOF;
# /etc/ganglia/gmond.conf
# written by ncm-gmond. Do not edit!
cluster {
}

globals {
  daemonize = true
  allow_extra_data = false
}

udp_send_channel {
  port = 123
  bind_hostname = true
}

udp_recv_channel {
  port = 456
}

tcp_accept_channel {
  port = 789
}

collection_group {
  metric {
    name = "test"
  }
}

EOF

my $fh = get_file('/etc/ganglia/gmond.conf');
is("$fh", $text, "correct (minimal) configuration");

done_testing;
