#${PMpre} NCM::Component::syslogng${PMpost}

use CAF::FileWriter;
use CAF::Service;

use constant PATH	=> '/software/components/syslogng/';
use constant SYSLOGFILE	=> '/etc/syslog-ng/syslog-ng.conf';
use constant SYSLOG_PIDFILE => '/var/run/syslogd.pid';

use constant TYPES => {
    files	=> 'file',
    pipes	=> 'pipe',
    unixdgram=> 'unix-dgram',
    unixstream=>'unix-stream',
    udp	=> 'udp',
    tcp	=> 'tcp',
    internal => 'internal'
};

use parent qw(NCM::Component);

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

# Prints syslog-ng global options.
sub print_opts
{

	my ($fh, $cfg) = @_;

	print $fh "options {\n";

	while (my ($k, $v) = each (%$cfg)) {
		print $fh "\t$k($v);\n";
	}
	print $fh "};\n";
}

# Prints source statements
sub print_srcs
{
	my ($fh, $cfg) = @_;

	while (my ($n, $src) = each (%$cfg)) {
		print $fh "source $n {\n\t";
		while (my ($t, $val) = each (%$src)) {
			foreach my $i (@$val) {
				print $fh "\t".TYPES->{$t}." (\n";
				print $fh "\t\t$i->{path}\n" if exists $i->{path};
				while (my ($k, $v) = each (%$i)) {
					print $fh "\t\t$k($v)\n" unless $k eq 'path';
				}
				print $fh "\t);\n";
			}
		}
		print $fh "};\n";
	}
}

# Prints destination definitions.
sub print_dsts
{
	my ($fh, $cfg) = @_;

	while (my ($n, $src) = each (%$cfg)) {
		print $fh "destination $n {\n\t";
		while (my ($t, $val) = each (%$src)) {
			foreach my $i (@$val) {
				print $fh "\t",TYPES->{$t}, " (\n";
				print $fh "\t\t$i->{ip}\n" if exists $i->{ip};
				print $fh "\t\t$i->{path}\n" if exists $i->{path};
				while (my ($k, $v) = each (%$i)) {
					print $fh "\t\t$k($v)\n" unless $k eq 'path' ||
					$k eq 'ip';
				}
				print $fh "\t);\n";
			}
		}
		print $fh "};\n";
	}

}


# Prints filter declarations
sub print_filters
{
	my ($fh, $cfg) = @_;

	while (my ($fn, $ft) = each (%$cfg)) {
		print $fh "filter $fn {\n\t";
		my @conds;
		push (@conds, "\tfacility(".
		      join (",", @{$ft->{facility}}). ")\n")
		    if exists $ft->{facility};
		push (@conds, "\tlevel(".
		      join (",", @{$ft->{level}}). ")\n")
		    if exists $ft->{level};
		push (@conds, "\tprogram($ft->{program})\n")
		    if exists $ft->{program};
		push (@conds, "\thost($ft->{host})\n")
		    if exists $ft->{host};
		if (exists ($ft->{filter})) {
		    foreach my $f (@{$ft->{filter}}) {
			    push (@conds, "\tfilter ($f)\n");
		    }
		}
		if (exists ($ft->{exclude_filters})) {
		    foreach my $f (@{$ft->{exclude_filters}}) {
			    push (@conds, "\tnot filter ($f)\n");
		    }
		}
		print $fh join ("\n\tor\n", @conds), ";\n};\n";
	}
}

sub print_log_flags
{
	my ($fh, $cfg) = @_;

    my @flags = grep {$cfg->{$_}} sort keys %$cfg;

	print $fh "\tflags(", join (",", @flags), ");\n";
}

# Prints a log path
sub print_logpaths
{
	my ($fh, $cfg) = @_;

	foreach my $lg (@$cfg) {
		print $fh "log {\n";
		print_log_flags ($fh, $lg->{flags}) if exists($lg->{flags});
		while (my ($k, $v) = each (%$lg)) {
			next if $k eq 'flags';
			$k =~ m{(.+)s};
			my $kv = $1;
			foreach my $i (@$v) {
				print $fh "\t$kv($i);\n";
			}
		}
		print $fh "};\n";
	}
}

sub Configure
{
	my ($self, $config) = @_;

	my $t = $config->getElement (PATH)->getTree;

	my $fh = CAF::FileWriter->new (SYSLOGFILE, log => $self);

	print_opts ($fh, $t->{options});
	print_srcs ($fh, $t->{sources});
	print_dsts ($fh, $t->{destinations});
	print_filters ($fh, $t->{filters});
	print_logpaths ($fh, $t->{log_rules});

    if ($fh->close()) {
        my $srv = CAF::Service->new(['syslog-ng'], log => $self);
        if (-f NAGIOS_PID_FILE) {
            $srv->reload();
        } else {
            $srv->start();
        }
    }

	return 1;
}

1;
