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


# Processes the aliases and prints them on the correct files. All
# aliases for a module given in the profile are controlled by this
# component.
sub process_aliases
{
    my ($self, $t, $fh) = @_;

    my ($name, $as, %aliases, $a);
    foreach my $i (@{$t->{modules}}) {
	if (exists($i->{alias})) {
	    $self->verbose("Adding alias $i->{alias} for $i->{name}");
	    print $fh "alias $i->{alias} $i->{name}\n";
	}
    }
}

# Processes the options for all modules. Again, all the options for
# any module listed here are the *only* ones to be applied.
sub process_options
{
    my ($self, $t, $fh) = @_;

    my ($name, $opt, $str, %options, $o);

    foreach my $i (@{$t->{modules}}) {
	if (exists($i->{options})) {
	    $self->verbose("Module $i->{name}: Adding options $i->{options}");
	    print $fh "options $i->{name} $i->{options}\n";
	}
    }
}

# Processess all the install scriptlets. Only one scriptlet per
# different module is allowed. Others may be deleted.
sub process_install
{
    my ($self, $t, $fh) = @_;

    foreach my $i (@{$t->{modules}}) {
	if (exists($i->{install})) {
	    print $fh "install $i->{name} $i->{install}\n";
	    $self->verbose("Added 'install' for $i->{name}: $i->{install}");
	}
    }
}

# Processes all the remove scriptlets. Only one such scriptlet per
# different module is allowed. Others may be deleted.
sub process_remove
{
    my ($self, $t, $fh) = @_;

    foreach my $i (@{$t->{modules}}) {
	if (exists($i->{remove})) {
	    print $fh "remove $i->{name} $i->{remove}\n";
	    $self->verbose("Added 'remove' for $i->{name}: $i->{remove}");
	}
    }
}

# Re-generates the initrds, if needed.
sub mkinitrd
{
    my ($self) = @_;

    my ($dir, @rs, $cmd);

    $dir = directory_contents("/boot");

    foreach my $i (@$dir) {
	if ($i =~ m{^^System\.map\-(2\.6\.*)$}) {
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
    my $fh = CAF::FileWriter->new($t->{file}, log => $self,
				  backup => '.old');

    $self->process_aliases($t, $fh);
    $self->process_options($t, $fh);
    $self->process_install($t, $fh);
    $self->process_remove($t, $fh);

    $self->mkinitrd($fh) if $fh->close();
    return 1;
}

1;
