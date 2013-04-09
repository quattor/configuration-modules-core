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
use Cwd qw(abs_path);
use File::Spec::Functions qw(abs2rel file_name_is_absolute);

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

    return $fh->close() && $srv->{daemon} && scalar(@{$srv->{daemon}});
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

    while (my ($k, $v) = each(%$cfg)) {
        if (ref($v)) {
            $c->{$k} = $v;
        } else {
            $c->{_}->{$k} = $v;
        }
    }
    return $c->write_string();
}

sub general
{
    my ($self, $cfg) = @_;

    $self->load_module("Config::General") or return;
    my $c = Config::General->new($cfg);
    return $c->save_string();
}

sub sanitize_template
{
    my ($self, $tplname) = @_;

    if (file_name_is_absolute($tplname)) {
        $self->error ("Must have a relative template name");
        return undef;
    }

    if ($tplname !~ m{\.tt$}) {
        $tplname .= ".tt";
    }

    $tplname = "metaconfig/$tplname";
    # Sorry, we have to break the rule of Demeter here
    my $base = $self->template()->service()->context()->config()->{INCLUDE_PATH};
    $self->debug(3, "We must ensure that all templates lie below $base");
    $tplname = abs_path("$base/$tplname");
    if (!$tplname || !-f $tplname) {
        $self->error ("Non-existing template name given");
        return undef;
    }

    if ($tplname =~ m{^$base/(metaconfig/.*)$}) {
        return $1;
    } else {
        $self->error ("Insecure template name. Final template must be under $base");
        return undef;
    }
}


sub tt
{
    my ($self, $cfg, $template) = @_;

    my ($sane_tpl, $str, $tpl);
    $sane_tpl = $self->sanitize_template($template);
    if (!$sane_tpl) {
        $self->error("Invalid template name: $template");
        return;
    }

    $tpl = $self->template();
    if (!$tpl->process($sane_tpl, $cfg, \$str)) {
        $self->error("Unable to process template for file $template: ",
                     $tpl->error());
        return undef;
    }
    return $str;
}

# Generate $file, configuring $srv. It will instantiate the correct
# configuration module (typically JSON::XS, YAML::XS, Config::General
# or Config::Tiny.
sub handle_service
{
    my ($self, $file, $srv) = @_;

    my ($method, $str);

    if ($srv->{module} !~ m{^([\w+/\.\-]+)$}) {
        $self->error("Invalid configuration style: $srv->{module}");
        return;
    }

    if ($method = $self->can(lc($1))) {
        $self->debug(3, "Rendering file $file with $method");
    } else {
        $method = \&tt;
        $self->debug(3, "Using Template toolkit to render $file");
    }

    $str = $method->($self, $srv->{contents}, $srv->{module});

    if (!defined($str)) {
        $self->error("Failed to render $file. Skipping");
        return;
    }

    my %opts  = (log => $self,
                 mode => $srv->{mode},
                 owner => scalar(getpwnam($srv->{owner})),
                 group => scalar(getgrnam($srv->{group})));
    $opts{backup} = $srv->{backup} if exists($srv->{backup});

    my $fh = CAF::FileWriter->new($file, %opts);
    print $fh "$str\n";
    if ($self->needs_restarting($fh, $srv)) {
        foreach my $d (@{$srv->{daemon}}) {
            $self->{daemons}->{$d} = 1;
        }
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
