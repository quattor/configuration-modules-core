#${PMcomponent}

use 5.10.1;
use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all();

use EDG::WP4::CCM::Path 16.8.0 qw (unescape);
use Socket;
use CAF::Process;
use CAF::FileWriter;
use LC::Exception qw (throw_error);
use File::Path;

use constant ICINGA_FILES => {
    general             => '/etc/icinga/icinga.cfg',
    cgi                 => '/etc/icinga/cgi.cfg',
    hosts               => '/etc/icinga/objects/hosts.cfg',
    hosts_generic       => '/etc/icinga/objects/hosts_generic.cfg',
    hostgroups          => '/etc/icinga/objects/hostgroups.cfg',
    services            => '/etc/icinga/objects/services.cfg',
    serviceextinfo      => '/etc/icinga/objects/serviceextinfo.cfg',
    servicedependencies => '/etc/icinga/objects/servicedependencies.cfg',
    servicegroups       => '/etc/icinga/objects/servicegroups.cfg',
    contacts            => '/etc/icinga/objects/contacts.cfg',
    contactgroups       => '/etc/icinga/objects/contactgroups.cfg',
    commands            => '/etc/icinga/objects/commands.cfg',
    macros              => '/etc/icinga/resource.cfg',
    timeperiods         => '/etc/icinga/objects/timeperiods.cfg',
    hostdependencies    => '/etc/icinga/objects/hostdependencies.cfg',
    ido2db              => '/etc/icinga/ido2db.cfg',
    cfgdir              => '/etc/icinga',
};

use constant BASEPATH          => "/software/components/icinga/";
use constant REMAINING_OBJECTS => qw {servicegroups contactgroups timeperiods};

use constant ICINGAUSR => (getpwnam("icinga"))[2];
use constant ICINGAGRP => (getpwnam("icinga"))[3];

use constant ICINGA_PID_FILE => '/var/icinga/icinga.pid';
use constant ICINGA_START    => qw (/sbin/service icinga start);
use constant ICINGA_RELOAD   => qw (/sbin/service icinga reload);

use constant ICINGA_SPOOL        => '/var/icinga/spool/';
use constant ICINGA_CHECK_RESULT => ICINGA_SPOOL . 'checkresults';

# Prints the main Icinga file, icinga.cfg.
sub print_general
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->new(
        ICINGA_FILES->{general},
        log   => $self,
        owner => ICINGAUSR,
        group => ICINGAGRP,
        mode  => 0444
    );

    my $el;
    my $ed;

    $el = $t->{external_files} || [];
    $ed = $t->{external_dirs}  || [];

    print $fh "log_file=$t->{general}->{log_file}\n";
    delete $t->{general}->{log_file};

    while (my ($k, $path) = each(%{ICINGA_FILES()})) {
        next if ($k eq 'general' || $k eq 'cgi' || $k eq 'ido2db');
        if (exists($t->{$k})) {
            print $fh $k eq 'macros' ? "resource_file" : "cfg_file", "=$path\n";
        }
    }

    if (exists($t->{general}->{broker_module})) {
        foreach my $bm (@{$t->{general}->{broker_module}}) {
            print $fh "broker_module = $bm\n";
        }
        delete($t->{general}->{broker_module});
    }

    while (my ($k, $v) = each(%{$t->{general}})) {
        next if $k eq 'log_file';
        if (ref($v)) {
            print $fh "$k=", join("!", @$v), "\n";
        } else {
            print $fh "$k=$v\n";
        }
    }

    foreach my $f (@$el) {
        print $fh "cfg_file=$f\n";
    }

    foreach my $f (@$ed) {
        print $fh "cfg_dir=$f\n";
    }

    return $fh;
}

sub make_dirs
{
    my ($self, $t) = @_;

    my $path = $t->{check_result_path} || ICINGA_CHECK_RESULT;
    mkpath(
        $path,
        {
            error => \my $err,
            mode  => 0770,
            owner => ICINGAUSR,
            group => ICINGAGRP
        }
    );

    foreach my $i (@$err) {
        my ($f, $msg) = %$i;
        $self->error("Couldn't create $f: $msg");
    }
    chown(ICINGAUSR, ICINGAGRP, ICINGA_SPOOL) if -d ICINGA_SPOOL;
    chown(0, ICINGAGRP, ICINGA_FILES->{cfgdir});
    chmod(0755, ICINGA_FILES->{cfgdir});
}

# Prints the IcingaCGI configuration file, cgi.cfg.
sub print_cgi
{
    my ($self, $t) = @_;

    defined($t) or return;

    my $fh = CAF::FileWriter->new(
        ICINGA_FILES->{cgi},
        log   => $self,
        mode  => 0444,
        owner => ICINGAUSR,
        group => ICINGAGRP
    );

    print $fh "main_config_file=" . ICINGA_FILES->{general} . "\n";

    while (my ($opt, $val) = each(%$t)) {
        print $fh "$opt=$val\n";
    }
    return $fh;
}

# Prints all the host template definitions on
# /etc/icinga/objects/hosts_generic.cfg;
sub print_hosts_generic
{
    my ($self, $t) = @_;

    defined($t) or return;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{hosts_generic},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    while (my ($host, $hostdata) = each(%$t)) {
        print $fh "define host {\n";
        while (my ($k, $v) = each(%$hostdata)) {
            if (ref($v)) {
                if ($k =~ m{command} || $k =~ m{handler}) {
                    print $fh "\t$k\t", join("!", @$v), "\n";
                } else {
                    print $fh "\t$k\t", join(",", @$v), "\n";
                }
            } else {
                print $fh "\t$k\t$v\n";
            }
        }
        print $fh "}\n";
    }
    return $fh;
}

# Prints all the host definitions on /etc/icinga/objects/hosts.cfg
sub print_hosts
{
    my ($self, $t, $ign) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{hosts},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    $ign ||= [];

    while (my ($host, $hostdata) = each(%$t)) {

        #ignore some nodes
        if ($host ~~ $ign) {
            $self->verbose("skipping host " . $host);
            next;
        }
        print $fh "define host {\n", "\thost_name\t$host\n";
        while (my ($k, $v) = each(%$hostdata)) {
            if (ref($v)) {
                if ($k =~ m{command} || $k =~ m{handler}) {
                    print $fh "\t$k\t", join("!", @$v), "\n";
                } else {
                    print $fh "\t$k\t", join(",", @$v), "\n";
                }
            } else {
                print $fh "\t$k\t$v\n";
            }
        }
        unless (exists $hostdata->{address}) {
            $self->verbose("DNS looking for $host");
            my @addr = gethostbyname($host);
            if (scalar @addr == 0) {
                $self->error("No IP found for host $host. ", "The host is probably not in DNS.");
            } else {
                print $fh "\taddress\t", inet_ntoa($addr[4]), "\n";
            }
        }
        print $fh "}\n";
    }
    return $fh;
}

# Prints all the hostgroup defenitions on /etc/icinga/objects/hostgroups.cfg
sub print_hostgroups
{
    my ($self, $t, $ign) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{hostgroups},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    $ign ||= [];

    while (my ($hostgroup, $hostgroupinst) = each(%$t)) {
        print $fh "define hostgroup {\n", "\thostgroup_name\t", unescape($hostgroup), "\n";
        while (my ($a, $b) = each(%$hostgroupinst)) {
            if (ref($b)) {
                my @c = @$b;
                foreach my $ignorehost (@$ign) {
                    @c = grep {$_ ne $ignorehost} @c;
                }
                print $fh "\t$a\t", join(",", @c), "\n" if (scalar(@c));
            } else {
                print $fh "\t$a\t$b\n";
            }
        }
        print $fh "}\n";
    }
    return $fh;
}

# Prints all the service definitions on /etc/icinga/objects/services.cfg
sub print_services
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{services},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    while (my ($service, $serviceinstances) = each(%$t)) {
        foreach my $servicedata (@$serviceinstances) {
            print $fh "define service {\n", "\tservice_description\t", unescape($service), "\n";
            while (my ($k, $v) = each(%$servicedata)) {
                if (ref($v)) {
                    if ($k =~ m{command} || $k =~ m{handler}) {
                        print $fh "\t$k\t", join("!", @$v), "\n";
                    } else {
                        print $fh "\t$k\t", join(",", @$v), "\n";
                    }
                } else {
                    print $fh "\t$k\t$v\n";
                }
            }
            print $fh "}\n";
        }
    }
    return $fh;
}

# Prints all the macros to /etc/icinga/resources.cfg
sub print_macros
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{macros},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    while (my ($macro, $val) = each(%$t)) {
        print $fh "\$$macro\$=$val\n";
    }
    return $fh;
}

# Prints the command definitions to /etc/icinga/objects/commands.cfg
sub print_commands
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{commands},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    while (my ($cmd, $cmdline) = each(%$t)) {
        print $fh <<EOF;
define command {
	command_name $cmd
	command_line $cmdline
}
EOF
    }

    return $fh;
}

# Prints all contacts to /etc/icinga/objects/contacts.cfg
sub print_contacts
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{contacts},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    while (my ($cnt, $cntst) = each(%$t)) {
        print $fh "define contact {\n", "\tcontact_name\t$cnt\n";
        while (my ($k, $v) = each(%$cntst)) {
            print $fh "\t$k\t";
            if (ref($v)) {
                my @s;
                if ($k =~ m{commands}) {
                    push(@s, join('!', @$_)) foreach @$v;
                } else {
                    @s = @$v;
                }
                print $fh join(',', @s);
            } else {
                print $fh $v;
            }
            print $fh "\n";
        }
        print $fh "}\n";
    }
    return $fh;
}

# Prints the service dependencies configuration files.
sub print_servicedependencies
{
    my ($self, $t) = @_;

    defined($t) or return;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{servicedependencies},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    foreach my $i (@$t) {
        print $fh "define servicedependency {\n";
        while (my ($k, $v) = each(%$i)) {
            print $fh "\t$k\t", ref($v) ? join(',', @$v) : $v;
            print $fh "\n";
        }
        print $fh "}\n";
    }
    return $fh;
}

# Prints the extended service configuration files.
sub print_serviceextinfo
{
    my ($self, $t) = @_;

    defined($t) or return;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{serviceextinfo},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    foreach my $i (@$t) {
        print $fh "define serviceextinfo {\n";
        while (my ($k, $v) = each(%$i)) {
            print $fh "\t$k\t", ref($v) ? join(',', @$v) : $v;
            print $fh "\n";
        }
        print $fh "}\n";
    }
    return $fh;
}

# Prints the host dependency configuration files.
sub print_hostdependencies
{
    my ($self, $t) = @_;

    defined($t) or return;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{hostdependencies},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    while (my ($host, $dependency) = each(%$t)) {
        print $fh "define hostdependency {\n", "\thost_name\t$host\n";
        while (my ($k, $v) = each(%$dependency)) {
            print $fh "\t$k\t", ref($v) ? join(',', @$v) : $v, "\n";
        }
        print $fh "}\n";
    }
    return $fh;
}

# Prints the ido2db configuration file.
sub print_ido2db_config
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{ido2db},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
        mode  => 0444
    );

    while (my ($ido2db_setting, $val) = each(%$t)) {
        print $fh "$ido2db_setting=$val\n";
    }

    return $fh;
}

# Prints one of the files listed in REMAINING_OBJECTS.
sub print_other
{
    my ($self, $t, $file) = @_;

    my $fh = CAF::FileWriter->open(
        ICINGA_FILES->{$file},
        owner => ICINGAUSR,
        group => ICINGAGRP,
        log   => $self,
    );

    # The files must not be empty!
    $file =~ m{(.*[^s])s?$};
    my $kv = $1;
    while (my ($k, $v) = each(%$t)) {
        print $fh "define $kv {\n", "\t$kv", "_name\t$k\n";
        while (my ($a, $b) = each(%$v)) {
            if (ref($b)) {
                print $fh "\t$a\t", join(",", @$b), "\n";
            } else {
                print $fh "\t$a\t$b\n";
            }
        }
        print $fh "}\n";
    }
    return $fh;
}

# Restarts the Icinga daemon if needed.
sub restart_icinga
{
    my $self = shift;

    my $cmd = CAF::Process->new([qw(service icinga)], log => $self);

    if (-f ICINGA_PID_FILE) {
        $cmd->pushargs("reload");
    } else {
        $cmd->pushargs("restart");
    }
    $cmd->run();
    if ($?) {
        $self->error("Unable to restart Icinga");
    }
    return $cmd;
}

# Configure method. Writes all the configuration files and starts or
# reloads the Icinga service
sub Configure
{
    my ($self, $config) = @_;

    if (! (defined(ICINGAUSR)  && defined(ICINGAGRP))) {
        $self->error("Icinga user and/or group undefined");
        return 0;
    }

    my $t = $config->getElement(BASEPATH)->getTree();

    $self->make_dirs($t);
    $self->print_general($t);
    $self->print_cgi($t->{cgi});
    $self->print_macros($t->{macros});
    $self->print_hosts($t->{hosts}, $t->{ignore_hosts});
    $self->print_hosts_generic($t->{hosts_generic});
    $self->print_hostgroups($t->{hostgroups}, $t->{ignore_hosts});
    $self->print_commands($t->{commands});
    $self->print_services($t->{services});
    $self->print_servicedependencies($t->{servicedependencies});
    $self->print_contacts($t->{contacts});
    $self->print_serviceextinfo($t->{serviceextinfo});
    $self->print_hostdependencies($t->{hostdependencies});
    $self->print_ido2db_config($t->{ido2db});

    # Print the rest of objects
    foreach my $i (REMAINING_OBJECTS) {
        next unless exists($t->{$i});
        $self->print_other($t->{$i}, $i);
    }

    $self->restart_icinga();

    return !$?;
}
