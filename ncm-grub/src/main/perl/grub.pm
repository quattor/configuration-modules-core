#${PMcomponent}

use Fcntl qw(SEEK_SET SEEK_END);
use CAF::Object qw(SUCCESS);
use CAF::FileEditor;
use CAF::FileWriter;

use Readonly;
use parent qw(NCM::Component CAF::Path);
our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

Readonly my $PATH_KERNEL_VERSION => '/system/kernel/version';
Readonly my $PATH_CONSOLE_SERIAL => '/hardware/console/serial';
Readonly my $GRUB_CONF           => '/boot/grub/grub.conf';
Readonly my $GRUB2_DIR           => '/boot/grub2';
Readonly my $GRUB2_USER_CFG      => "$GRUB2_DIR/user.cfg";
Readonly my $GRUBBY              => '/sbin/grubby';
Readonly my $PREFIX              => '/boot';
Readonly::Hash my %SERIAL_CONSOLE_DEFAULTS => {
    unit => 0,
    speed => 9600,
    word => 8,
    parity => "n",
};

our $GRUB_MAJOR = -d $GRUB2_DIR ? 2 : 1;

=pod

=head1 NAME

The I<grub> component manages the grub configuration.

=head1 DESCRIPTION

The I<grub> component manages the configuration of grub.

Most of the configuration is handled via the C<grubby> tool
(which supports grub2).

Some configuration like serial console settings and password
however is done by modifying the grub configfile
directly, which might not be safe under grub2.

=head1 RESOURCES

Besides C<< /software/component/grub >>, following resources are used:

=over

=item C<< /system/kernel/version >> for setting the default kernel

=item C<< /hardware/console/serial >> for serial console configuration

=back

=head1 EXAMPLES

=over

=item A standard SL4 kernel with initrd image to be loaded.

  "/software/components/grub/kernels/0" =
        nlist("kernelpath", "/vmlinuz-2.6.9-22.0.1.EL",
              "kernelargs", "ro root=LABEL=/",
              "title", "Scientific Linux 4.2 / 2.6.9",
              "initrd", "/initrd-2.6.9-22.0.1.EL.img"
  );

This configuration produces the following entry in grub.conf (via grubby):

  title Scientific Linux 4.2 / 2.6.9
        kernel /vmlinuz-2.6.9-22.0.1.EL ro root=LABEL=/
        initrd /initrd-2.6.9-22.0.1.EL.img

=item A Xen 3 hypervisor with Linux 2.6 domain 0 kernel and initrd (via grubby).

  "/software/components/grub/kernels/1" =
        nlist("multiboot", "/xen-3.0.2-2.gz",
              "mbargs", "dom0_mem=400000",
              "title", "Xen 3 / XenLinux 2.6.16",
              "kernelpath", "/vmlinuz-2.6.16-xen3_86.1_rhel4.1",
              "kernelargs", "max_loop=128 root=/dev/hda2 ro",
              "initrd", "/initrd-2.6.16-xen3_86.1_rhel4.1"
  );

Produces the following entry in grub.conf:

  title Xen 3 / XenLinux 2.6.16
        kernel /xen-3.0.2-2.gz dom0_mem=400000 addthis
        module /vmlinuz-2.6.16-xen3_86.1_rhel4.1 max_loop=128 root=/dev/hda2 ro
        module /initrd-2.6.16-xen3_86.1_rhel4.1

=back

=head2 Methods

=over

=item grubby_args_options

Given string C<args>, split and convert into grubby commandline options
to add and/or remove the arguments.
Arguments prefixed with '-' are scheduled for removal
If C<multiboot> is true, generate multiboot commandline options

Returns a list of options.

=cut

sub grubby_args_options
{
    my ($self, $args, $multiboot) = @_;

    $args = '' if ! defined($args);

    # howto remove an argument: precede with a -
    my @add;
    my @remove;

    # kernelargs cannot be '0'
    foreach my $arg (split(/\s+/, $args)) {
        if ($arg =~ s/^-//) {
            push(@remove, $arg);
        } else {
            push(@add, $arg);
        }
    }

    my @options;

    my $mb = $multiboot ? 'mb' : '';
    push(@options, "--${mb}args", join(" ", @add)) if @add;
    push(@options, "--remove-${mb}args", join(" ", @remove)) if @remove;

    $self->debug(1, "converted '$args' in options '@options'");
    return @options;
}


=item password

Configure the grub password by editing the grub conf via filehandle
C<grub_fh> (a C<CAF::FileEditor> instance,
which is not closed in this method).

Returns SUCCESS on succes, undef otherwise.

=cut

sub password
{
    my ($self, $config, $grub_fh) = @_;

    my $password;

    # if passwords have not been explicitly enabled or disabled then do nothing.
    my $tree = $config->getTree($self->prefix . "/password");
    return SUCCESS if (!defined($tree));

    if (!defined($tree->{enabled})) {
        $self->verbose("password section defined, but enabled/disabled not set");
        return SUCCESS;
    } elsif (!$tree->{enabled}) {
        $self->info("removing grub password");
        $grub_fh->remove_lines(qr/^password\s+/, '');
        return SUCCESS;
    }

    if (my $passwordfile = $tree->{file}) {
        my $fileuser = $tree->{file_user};
        if (! -R $passwordfile) {
            $self->error("grub password file $passwordfile does not exist or is not readable.");
            return;
        }
        my $pf_fh = CAF::FileReader->new($passwordfile, log => $self);
        foreach my $line (split(/\n/, "$pf_fh")) {
            chomp $line;
            my @fields = split(/:/, $line, 2);
            if ($fields[0] eq $fileuser) {
                $password = $fields[1];
                last;
           }
        }
        if (!defined($password)) {
            $self->error("unable to find user $fileuser in grub password file $passwordfile");
            return;
        }
    } else {
        $password = $tree->{password};
    }

    my $val = $tree->{option} ? "--$tree->{option} " : "";
    $val .= $password;

    if ( $GRUB_MAJOR == 2 ) {
        my $usercfg_fh = CAF::FileEditor->new( $GRUB2_USER_CFG,
            owner => "root",
            group => "root",
            mode  => oct(400),
            log   => $self );

        $usercfg_fh->add_or_replace_lines(qr/^GRUB2_PASSWORD=/, qr/^GRUB2_PASSWORD=$password$/, "GRUB2_PASSWORD=$password\n", SEEK_END);
        $usercfg_fh->close();
    } else {
        my $val = $tree->{option} ? "--$tree->{option} " : "";
        $val .= $password;

        $grub_fh->add_or_replace_lines(qr/^password\s+/,
                                  qr/^password $val$/,
                                  "password $val\n",
                                  $self->main_section_offset($grub_fh),
                                  SEEK_END);
    }

    return SUCCESS;
}


=item serial_console

Configure the grub serial console settings (C<ttyS> devices only)
by editing the grub conf via filehandle C<grub_fh>
(a C<CAF::FileEditor> instance, which is not closed in this method).

Returns undef on failure, the console kernel commandline option
(or empty string if none is to be configured) on success.

=cut

sub serial_console
{
    my ($self, $config, $grub_fh) = @_;

    my $cons;

    my $ctree = $config->getTree($PATH_CONSOLE_SERIAL);
    if ($ctree) {
        my %sc = (%SERIAL_CONSOLE_DEFAULTS, %$ctree);

        $cons = "console=ttyS$sc{unit},$sc{speed}$sc{parity}$sc{word}";
        $self->verbose("Serial console kernel option $cons");

        # Grub settings
        my $serial = "--unit=$sc{unit} --speed=$sc{speed} --parity=$sc{parity} --word=$sc{word}";
        my $terminal = "serial console";

        $grub_fh->add_or_replace_lines(qr/^serial\s*/,
                                       qr/^serial $serial$/,
                                       "serial $serial\n",
                                       $self->main_section_offset($grub_fh),
                                       SEEK_END);

        $grub_fh->add_or_replace_lines(qr/^terminal\s*/,
                                       qr/^terminal $terminal$/,
                                       "terminal $terminal\n",
                                       $self->main_section_offset($grub_fh),
                                       SEEK_END);
    } else {
        $self->verbose('No serial console to configure');
        $cons = '';
    }

    return $cons;
}


=item main_section_offset

Given a grub config filehandle (a C<CAF::FileEditor> instance),
return the startposition of the main section
i.e. after the header comments (if any).

=cut

sub main_section_offset
{
    my ($self, $fh) = @_;

    my ($start, $end) = $fh->get_header_positions();

    return $start == -1 ? BEGINNING_OF_FILE : (SEEK_SET, $end);
}


=item grub_conf

Edit grub configfile and
return serial console kernel commandline option (if any).

=cut

sub grub_conf
{
    my ($self, $config) = @_;

    my $grub_fh = CAF::FileEditor->new($GRUB_CONF,
                                       owner => "root",
                                       group => "root",
                                       mode  => oct(400),
                                       log   => $self);

    if (!"$grub_fh") {
        print $grub_fh "# Generated by ncm-grub\n";
    }

    my $cons = $self->serial_console($config, $grub_fh);

    $self->password($config, $grub_fh);

    $grub_fh->close();

    return $cons;
}


=item grubby

Run C<grubby> with arraref C<args> via C<CAF::Proces> using the
C<output> method and return the output.

Has following options

=over

=item proc: return new C<CAF::Process> instance with C<args> (i.e. without execute/output)

=item success: run execute and return 1 on success, 0 on failure

=item keeps_state: pass keeps_state flag

=back

=cut

sub grubby
{
    my ($self, $args, %opts) = @_;

    my %p_opts = (
        log => $self,
    );
    $p_opts{keeps_state} = 1 if $opts{keeps_state};

    my $proc = CAF::Process->new([$GRUBBY, @{$args || []}], %p_opts);

    if ($opts{proc}) {
        return $proc;
    } elsif ($opts{success}) {
        $proc->execute();
        return $? ? 0 : 1;
    } else {
        return $proc->output();
    }
}


=item current_default

Return current full path of current default kernel.

=cut

sub current_default
{
    my ($self) = @_;

    my $current = $self->grubby([qw(--default-kernel --bad-image-okay)], keeps_state => 1);
    chomp($current);
    if ($?) {
        $self->error("Can't run $GRUBBY --default-kernel (return code $? output $current)");
        return;
    } elsif ($current eq '') {
        $self->warn("Can't get current default kernel");
    }

    return $current;
}


=item set_default

Set default kernel to C<new> kernelpath and verify by (re)checking the default kernel.

Returns success on success; on failure, return either

=over

=item undef: setting default kernel returned non-zero exitcode

=item 0: setting default was succesful, but new default kernel is not expected kernel

=back

No errors are reported.

=cut

sub set_default
{
    my ($self, $new) = @_;

    my $ret;
    my $msg = "the new default kernel to $new";
    if($self->grubby(["--set-default", $new], success => 1)) {
        # check that new kernel is really set
        # as grubby always returns ec=0
        my $current = $self->current_default();
        if ($current eq $new) {
            $self->verbose("Set $msg");
            $ret = SUCCESS;
        } else {
            $self->verbose("Failed to set $msg; current default is $current");
            $ret = 0;
        }
    } else {
        $self->verbose("Something went wrong while trying to set $msg");
        $ret = undef;
    }

    return $ret;
}


=item configure_default

Configure the new default kernel to be C<new>.
If this fails and C<mbnew> exists, try to set C<mbnew> as default.

If neither C<new> nor C<mbnew> are successful,
report an error and revert to C<original>.

=cut

sub configure_default
{
    my ($self, $new, $mbnew, $original) = @_;

    my $ret;
    if ($self->set_default($new)) {
        $self->verbose("configured new default kernel $new");
        $ret = SUCCESS;
    } else {
        my $errormsg = "failed to set new default kernel using $new";
        if ($mbnew && $self->set_default($mbnew)) {
            $self->verbose("configured new default kernel using multiboot $mbnew (failed with kernel $new)");
            $ret = SUCCESS;
        } else {
            $errormsg .= $mbnew ? " and multiboot $mbnew" : " and no multiboot";

            if ($original) {
                $errormsg .= $self->set_default($original) ? ", reverted" : ", failed to revert" ;
                $errormsg .= " original $original";
            } else {
                $errormsg .= " and no original to revert to"
            }
            $self->error($errormsg);
        }
    }

    return $ret

}


=item kernel

Configure boot entry using C<kernel> hashref, the kernel C<prefix>
and optional serial console kernel commandline option C<cons>.

Any serial console settings in the C<kernelargs> attribute
is replaced by C<cons> (when defined).

=cut

sub kernel
{
    my ($self, $kernel, $prefix, $cons) = @_;

    if (!$kernel->{kernelpath}) {
        # check is not really needed, this is mandatory in schema
        $self->error("Mandatory kernelpath missing, skipping this kernel");
        return;
    }

    my ($args, $initrd, $fullinitrd, $mbpath, $fullmbpath);

    my $path = $kernel->{kernelpath};
    my $fullpath = "$prefix$path";

    if ($kernel->{kernelargs}) {
        $args = $kernel->{kernelargs};
        if ($cons) {
            # by $cons we mean serial cons, so we should only sub serial entries.
            $args =~ s{console=(ttyS[^ ]*)}{};
            $args .= " $cons";
        }
    }

    my @options = $self->grubby_args_options($args);

    my $mbargs = $kernel->{mbargs} || '';
    my @mboptions = $self->grubby_args_options($mbargs, 1);

    my $title = $kernel->{title} || $path;

    if ($kernel->{initrd}) {
        $initrd     = $kernel->{initrd};
        $fullinitrd = "$prefix$initrd";
    }

    if ($kernel->{multiboot}) {
        $mbpath     = $kernel->{multiboot};
        $fullmbpath = "$prefix$mbpath";
    }

    # check whether this kernel is already installed
    my $installed = $self->grubby(['--info', $fullpath], success => 1);

    # check whether the multiboot loader is installed
    my $mbinstalled = $mbpath ? $self->grubby(['--info', $fullmbpath], success => 1) : 0;

    my $proc = $self->grubby([], proc => 1);

    if ((! $installed) && (! $mbinstalled)) {
        $self->info("Kernel $path not installed, trying to add it");

        $proc->pushargs(
            "--add-kernel", $fullpath,
            "--title", $title,
            @options);

        $proc->pushargs("--initrd", $fullinitrd) if $initrd;

        # installing multiboot loader
        if ($kernel->{multiboot}) {
            $self->verbose("Adding multiboot kernel $fullmbpath");
            $proc->pushargs("--add-multiboot", $fullmbpath, @mboptions);
        } else {
            $self->info("Adding new standard kernel");
        }
    } else {
        $self->info("Updating installed kernel $path");
        $proc->pushargs("--update-kernel", $fullpath, @options);

        if ($kernel->{multiboot}) {
            $self->verbose("Updating multiboot kernel $fullmbpath");
            $proc->pushargs("--add-multiboot", $fullmbpath, @mboptions);
        }
    }

    if (defined($proc)) {
        $self->verbose("Configuring kernel using $proc");
        $proc->output();
    }

    return SUCCESS;
}


=item get_info

Return info for default kernel as an arrayref of hashref

Same kernel can have multiple entries.

=cut

sub get_info
{
    my ($self, $kernel) = @_;

    my @default;

    my $info = $self->grubby(['--info', $kernel], keeps_state => 1);

    # First, build hash of arrayrefs
    # We assume that every key= occurs only once per index
    my %names;
    foreach my $line (split("\n", $info)) {
        chomp($line); # do not care for whitespace
        if ($line =~ m/^([^=]+)\s*=\s*(.*)$/) {
            my $name = $1;
            if (! exists($names{$name})) {
                $names{$name} = [];
            };
            push(@{$names{$name}}, $2);
        }
    };

    my @entries;
    # convert hash of arrayrefs in array of hashrefs
    # Number of indices is number of kernel keys
    # We assume all keys appear equal amount of times
    foreach my $ind (0 .. scalar @{$names{kernel} || []} - 1) {
        my %res;
        foreach my $key (keys %names) {
            $res{$key} = $names{$key}->[$ind];
        };
        $self->debug(1, "Entry from kernel $kernel info: ",
                     join(" ", map {"$_=$res{$_}"} sort keys %res));
        push (@entries, \%res);
    };

    $self->verbose(scalar @entries, " entries from kernel $kernel info");

    return \@entries;
};


=item default_options

Configure kernel commandline options of default kernel

=cut

sub default_options
{
    my ($self, $tree, $default) = @_;

    my $fullcontrol = $tree->{fullcontrol};
    $self->debug(2, "fullcontrol is ", $fullcontrol ? "true" : "false/not defined");

    # With fullcontrol, any args starting with '-' whould be invalid anyway
    my @options = $self->grubby_args_options($tree->{args});

    my $entries = $self->get_info($default);
    if (scalar @$entries > 1) {
        $self->warn("More than one grub entry for kernel $default found.",
                    " Only first entry / lowest index will be modified");
    };

    # If we want full control of the arguments:
    if ($fullcontrol) {
        # Check current arguments
        my $current = '';
        if (@$entries && $entries->[0]->{args} && $entries->[0]->{args} =~ m/^\"(.*)\"$/) {
            $current = $1;
            $self->debug(1, "fullcontrol found current args for kernel $default: '$current'");
        }

        # Check if the arguments we want to add are the same we have
        # compare with commandline option
        if (join(' ', @options) eq "--args $current") {
            $self->verbose("fullcontrol defaultkernel kernel $default no changes in the arguments required");
        } else {
            # Remove all the arguments
            if ($current eq "") {
                $self->verbose("fullcontrol default kernel $default no current arguments to remove");
            } else {
                if ($self->grubby(['--update-kernel', $default, '--remove-args', $current], success => 1)) {
                    $self->info("fullcontrol removed current args '$current' from default kernel $default");
                } else {
                    $self->error("fullcontrol cannot remove current args '$current' from default kernel $default");
                    return;
                }
            }

            # Add the arguments specified inside $kernelargs
            if (@options) {
                if ($self->grubby(['--update-kernel', $default, @options], success => 1)) {
                    $self->info("fullcontrol set args with '@options' for default kernel $default");
                } else {
                    $self->error("fullcontrol cannot set args with '@options' for default kernel $default");
                    return;
                }
            } else {
                $self->verbose("fullcontrol default kernel $default no arguments added");
            }
        }
    } else {
        # If we want no full control of the arguments
        if (@options) {
            if ($self->grubby(['--update-kernel', $default, @options], success => 1)) {
                $self->info("set args with '@options' for default kernel $default");
            } else {
                $self->error("cannot set args with '@options' for default kernel $default");
                return;
            }
        } else {
            $self->verbose("No kernel arguments set");
        }
    }

    return SUCCESS;
}

=item Configure

Updates the grub.conf configuration file using grubby according to a
list of kernels described in the profile.

Sets the default kernel to that specified in C<< /system/kernel/version >>.

Supports

=over

=item serial console configuration specified in C<< /hardware/console/serial >>.

=item multiboot loaders (most commonly used for configuration of Xen systems).

=back

Returns error in case of failure.

=cut

sub Configure
{

    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix);

    # assumes prefix cannot be 0 or empty string
    my $prefix = $tree->{prefix} || $PREFIX;

    # Full path to the default kernel (if not configured, the current default kernel will be assigned)
    my $default;
    if ($config->elementExists($PATH_KERNEL_VERSION)) {
        my $version = $config->getValue($PATH_KERNEL_VERSION);
        $default = "$prefix/vmlinuz-$version";
        # Sanity check
        my $msg = "Configured default kernel $default (version $version prefix $prefix)";
        if ($self->file_exists($default)) {
            $self->verbose($msg);
        } else {
            $self->error("$msg not found");
            return;
        }
    } else {
        $self->debug(1, "No kernel version defined");
    }

    if (!$self->file_exists($GRUBBY)) {
        $self->error("$GRUBBY not found");
        return;
    }

    # the checks that grub uses to determine whether a kernel is "good"
    # are simplistic, and include checking that the name is like "vmlinuz"
    # so we disable them for now
    my $original = $self->current_default();

    # error already reported
    # we only check and possibly return once
    return if (!defined($original));

    # Modifications start here

    my $cons = $self->grub_conf($config);

    # List with candidate multiboot kernel(s) that could be the default kernel
    my @multiboot_default;
    # Process all configured kernels
    foreach my $kernel (@{$tree->{kernels}}) {
        my $path = "$prefix$kernel->{kernelpath}";
        push (@multiboot_default, $path) if ($kernel->{multiboot} && $path eq $default);
        $self->kernel($kernel, $prefix, $cons);
    }

    # handle the default kernel as defined in /system/kernel/version
    if (!defined($default)) {
        $self->info("no default kernel configured, using the current default $original");
        $default = $original;
    } elsif ($original eq $default) {
        $self->info("correct default kernel $default already configured");
    } else {
        # only try first multiboot_default
        if (scalar(@multiboot_default) > 1) {
            $self->warn("More than one mutliboot kernel found that matches default;",
                        " only using first one: ", join(', ', @multiboot_default));
        }

        return if (!$self->configure_default($default, shift(@multiboot_default), $original, 0));
    }

    # if we get here, default is the current default kernel
    # TODO: no search and replace for console settings like kernel method? i.e. pass $cons
    $self->default_options($tree, $default);

    return SUCCESS;
};

=pod

=back

=cut

1;
