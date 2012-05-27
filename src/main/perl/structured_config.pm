# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;

use base qw(NCM::Component);

use LC::Exception;
use LC::Find;
use LC::File qw(copy makedir);
use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use File::Basename;
use File::Path;

use Readonly;

Readonly::Scalar my $PATH => '/software/components/${project.artifactId}';

our $EC=LC::Exception::Context->new->will_store_all;

# Restart any daemon that has seen its configuration changed by the
# component.
sub restart_daemon {
    my ($self, $daemon) = @_;
    CAF::Process->new(["/sbin/service", $daemon, "restart"],
		      log => $self)->run();
    if ($?) {
	$self->error("Impossible to restart $daemon");
	return;
    }
    return 1;
}

sub needs_restarting
{
    my ($self, $fh, $srv) = @_;

    return $fh->close() && $srv->{daemon};
}


# Generate $file, configuring $srv. It will instantiate the correct
# configuration module (typically JSON::XS, YAML::XS, Config::General
# or Config::Tiny.
sub handle_service
{
    my ($self, $file, $srv) = @_;

    my $owner = getpwnam($srv->{owner});
    my $group = getgrnam($srv->{group});
    my $perms = $srv->{mode};

    if ($srv->{module} =~ m{^(\w+(?:::\w+)*(?:\s*qw\((?:\w*\s*)*\))?)$}) {
	eval "use $1";
	if ($@) {
	    $self->error("Unable to load module $srv->{module}: $@");
	    return;
	}
    } else {
	$self->error("Module $srv->{module} is not a valid Perl module");
	return;
    }

    my $d = $srv->{module}->new();
    my $m = $d->can("Dump") 	||
	$d->can("write_string") ||
	$d->can("save_string");

    my $fh = CAF::FileWriter->new($file,
				  log 	=> $self,
				  mode 	=> $perms,
				  owner => $owner,
				  group => $group);

    print $fh $m->($d, $srv->{contents}), "\n";
    if ($self->needs_restarting($fh, $srv)) {
	$self->{daemons}->{$srv->{daemon}} = 1;
    }
    return 1;
}


sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement($PATH)->getTree();

    while (my ($f, $c) = each(%{$t->{services}})) {
	$self->handle_service(unescape($f), $c);
    }

    # Restart any daemons whose configurations we have changed.
    foreach my $d (keys(%{$self->{daemons}})) {
	$self->restart_daemon($d);
    }
    return 1;
}

1; # Required for perl module!
