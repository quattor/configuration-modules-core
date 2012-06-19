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
use EDG::WP4::CCM::Element qw(unescape);

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

sub load_module
{
    my ($self, $module) = @_;

    $self->verbose("Loading module $module");

    eval "use $module";
    if ($@) {
	$self->error("Unable to load $module: $@");
	return;
    }
    return 1;
}

sub needs_restarting
{
    my ($self, $fh, $srv) = @_;

    return $fh->close() && $srv->{daemon};
}

sub json
{
    my ($self, $cfg) = @_;

    $self->load_module("JSON::XS") or return;
    my $j = JSON::XS->new();
    return $j->encode($cfg);
}

sub yaml
{
    my ($self, $cfg) = @_;

    $self->load_module("YAML::XS") or return;

    if ($@) {
	$self->error("Unable to load YAML::XS: $@");
	return;
    }

    return YAML::XS::Dump($cfg);
}

sub tiny
{
    my ($self, $cfg) = @_;

    $self->load_module("Config::Tiny") or return;

    my $c = Config::Tiny->new();

    $c->{_} = $cfg;
    return $c->write_string();
}

sub general
{
    my ($self, $cfg) = @_;

    $self->load_module("Config::General") or return;
    my $c = Config::General->new($cfg);
    return $c->save_string();
}

# Generate $file, configuring $srv. It will instantiate the correct
# configuration module (typically JSON::XS, YAML::XS, Config::General
# or Config::Tiny.
sub handle_service
{
    my ($self, $file, $srv) = @_;

    my $method;

    if ($srv->{module} !~ m{^(\w+)$}) {
	$self->error("Invalid configuration style: $srv->{module}");
	return;
    }

    $method = $self->can(lc($1));
    if (!$method) {
	$self->error("Don't know how to handle $srv->{module}-style configs");
	return;
    }

    my %opts  = (log => $self,
		 mode => $srv->{mode},
		 owner => scalar(getpwnam($srv->{owner})),
		 group => scalar(getgrnam($srv->{group})));
    $opts{backup} = $srv->{backup} if exists($srv->{backup});

    my $fh = CAF::FileWriter->new($file, %opts);

    print $fh $method->($self, $srv->{contents}), "\n";
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
