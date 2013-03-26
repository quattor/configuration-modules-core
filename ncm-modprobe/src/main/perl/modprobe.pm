# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::modprobe - ncm modprobe configuration component
#
################################################################################

package NCM::Component::modprobe;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
our @ISA = qw(NCM::Component);
our $EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use EDG::WP4::CCM::Configuration;
use CAF::Process;
use CAF::FileWriter;
use LC::File qw(directory_contents);
use Fcntl qw(:seek);


no strict 'refs';

foreach my $method (qw(alias options install remove)) {
    *{__PACKAGE__."::process_$method"} = sub {
        my ($self, $t, $fh) = @_;
        foreach my $i (@{$t->{modules}}) {
            if (exists($i->{$method})) {
                $self->verbose("Adding $method $i->{$method} for $i->{name}");
                print $fh "$method $i->{$method} $i->{name}\n";
            }
        }
    };
}

use strict 'refs';


# Re-generates the initrds, if needed.
sub mkinitrd
{
    my ($self) = @_;

    my ($dir, @rs, $cmd);

    $dir = directory_contents("/boot");

    foreach my $i (@$dir) {
	if ($i =~ m{^System\.map\-(2\.6\..*)$}) {
	    my $rl = $1;
	    CAF::Process->new(["mkinitrd", "-f", "/boot/initrd-$rl.img", $rl],
			      log => $self)->run();
	    $self->error("Unable to build the initrd for $rl") if $?;
	}
    }
}


sub Configure {
    my ($self,$config)=@_;

    my $t = $config->getElement("/software/components/modprobe")->getTree();

    # Do not create a backup file as module-init-tools up to and including RH6
    # does not check the file extension, and would happily process the backup
    # file
    my $fh = CAF::FileWriter->new($t->{file}, log => $self);

    $self->process_alias($t, $fh);
    $self->process_options($t, $fh);
    $self->process_install($t, $fh);
    $self->process_remove($t, $fh);

    $self->mkinitrd($fh) if $fh->close();
    return 1;
}

1;
