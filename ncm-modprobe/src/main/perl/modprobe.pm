# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::modprobe - ncm modprobe configuration component
#

package NCM::Component::modprobe;

use strict;
use warnings;

use NCM::Component;
our @ISA = qw(NCM::Component);
our $EC  = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

use EDG::WP4::CCM::Configuration;
use CAF::Process;
use CAF::FileWriter;
use LC::File qw(directory_contents);
use Readonly;

no strict 'refs';
Readonly my $DEFAULT_MODPROBE_CONF => "/etc/modprobe.d/quattor.conf";

foreach my $method (qw(alias options install remove blacklist)) {
    *{__PACKAGE__ . "::process_$method"} = sub {
        my ($self, $t, $fh) = @_;
        foreach my $i (@{$t->{modules}}) {
            if (exists($i->{$method})) {
                if ($method eq "alias") {
                    $self->verbose("Adding: $method $i->{$method} $i->{name}");
                    print $fh "$method $i->{$method} $i->{name}\n";
                } elsif ($method eq "blacklist") {
                    $self->verbose("Adding: $method $i->{name}");
                    print $fh "$method $i->{name}\n";
                } else {
                    $self->verbose("Adding: $method $i->{name} $i->{$method}");
                    print $fh "$method $i->{name} $i->{$method}\n";
                }
            }
        }
    }
}

use strict 'refs';

# Re-generates the initrds, if needed.
sub mkinitrd
{
    my ($self) = @_;

    my ($dir, @rs, $cmd);

    $dir = directory_contents("/boot");

    foreach my $i (@$dir) {
        if ($i =~ m{^System\.map\-(.*)$}) {
            my $rl = $1;
            my $target = "/boot/initrd-$rl.img";
            $target = "/boot/initramfs-$rl.img" if -f "/boot/initramfs-$rl.img";
            CAF::Process->new(["mkinitrd", "-f", $target, $rl], log => $self)->run();
            $self->error("Unable to build the initrd for $rl") if $?;
        }
    }
}

sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement("/software/components/modprobe")->getTree();

    # Do not create a backup file as module-init-tools up to and including RH6
    # does not check the file extension, and would happily process the backup
    # file
    my $fh = CAF::FileWriter->new($t->{file} || $DEFAULT_MODPROBE_CONF, log => $self);

    $self->process_alias($t, $fh);
    $self->process_options($t, $fh);
    $self->process_install($t, $fh);
    $self->process_remove($t, $fh);
    $self->process_blacklist($t, $fh);

    $self->mkinitrd($fh) if $fh->close();
    return 1;
}

1;
