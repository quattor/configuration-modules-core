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
use CAF::FileEditor;
use LC::File qw(directory_contents);
use Fcntl qw(:seek);


# Opens a file
sub file_open
{
    my ($self, $filename) = @_;

    my $fh = CAF::FileEditor->new($filename,
				  backup => '.old', log => $self,
				  owner => 0, group => 0, mode => 0600);
    $fh->cancel() unless ${$fh->string_ref()};
    return $fh;
}

# Processes the aliases and prints them on the correct files. All
# aliases for a module given in the profile are controlled by this
# component.
sub process_aliases
{
    my ($self, $t, $f1, $f2) = @_;

    my ($i, $name, $as, $str, %aliases, $a);
    foreach $i (@{$t->{modules}}) {
	if (exists($i->{alias})) {
	    $self->debug(4, "Adding alias $i->{alias} for $i->{name}");
	    if (exists($aliases{$i->{name}})) {
		push(@{$aliases{$i->{name}}}, $i->{alias});
	    } else {
		$aliases{$i->{name}} = [$i->{alias}];
	    }
	}
    }

    foreach $i ($f1, $f2) {
	$str = ${$i->string_ref()};
	while (($name, $as) = each(%aliases)) {
	    $self->debug(4, "Printing aliases for: $name");
	    $str =~ s{^alias\s+\S+\s+$name$}{}mg;
	    $i->set_contents($str);
	    seek($i, 0, SEEK_END);
	    foreach $a (@$as) {
		print $i "alias $a $name\n";
	    }
	}
    }
}

# Processes the options for all modules. Again, all the options for
# any module listed here are the *only* ones to be applied.
sub process_options
{
    my ($self, $t, $f1, $f2) = @_;

    my ($i, $name, $opt, $str, %options, $o);

    foreach $i (@{$t->{modules}}) {
	if (exists($i->{options})) {
	    $self->debug(4, "Module $i->{name}: Adding options $i->{options}");
	    if (exists($options{$i->{name}})) {
		push(@{$options{$i->{name}}}, $i->{options});
	    } else {
		$options{$i->{name}} = [$i->{options}];
	    }
	}
    }

    foreach $i ($f1, $f2) {
	$str = ${$i->string_ref()};
	while (($name, $opt) = each(%options)) {
	    $self->debug(4, "Adding options ", join(" ", @$opt), " to module $name");
	    $str =~ s{^options $name\s.*}{}mg;
	    $i->set_contents($str);
	    seek($i, 0, SEEK_END);
	    print $i "options $name ", join(" ", @$opt), "\n";
	}
    }
}

# Processess all the install scriptlets. Only one scriptlet per
# different module is allowed. Others may be deleted.
sub process_install
{
    my ($self, $t, $f1, $f2) = @_;

    my ($i, $j, $str);

    foreach $i (@{$t->{modules}}) {
	if (exists($i->{install})) {
	    foreach $j ($f1, $f2) {
		$str = ${$j->string_ref()};
		$str =~ s!^install $i->{name}.*$!install $i->{name} {$i->{install}}!mg;
	    }
	}
    }
}

# Processes all the remove scriptlets. Only one such scriptlet per
# different module is allowed. Others may be deleted.
sub process_remove
{
    my ($self, $t, $f1, $f2) = @_;

    my ($i, $j, $str);

    foreach $i (@{$t->{modules}}) {
	if (exists($i->{remove})) {
	    foreach $j ($f1, $f2) {
		$str = ${$j->string_ref()};
		$str =~ s!^remove $i->{name}.*$!remove $i->{name} {$i->{remove}}!mg;
	    }
	}
    }
}

# Re-generates the initrds, if needed.
sub mkinitrd
{
    my ($self, $f24, $f26) = @_;

    my ($i, $dir, @releases, @rs, $cmd, $str);

    $dir = directory_contents("/boot");

    foreach $i (@$dir) {
	if ($i =~ m{^^System\.map\-(2\.[46]\.*)$}) {
	    push(@releases, $1);
	}
    }

    $str = $f24->string_ref();
    $$str =~ s{^\s*\n}{}mg;
    $f24->set_contents($str);

    if ($f24->close()) {
	@rs = grep(m{^2\.4}, @releases);
	foreach $i (@rs) {
	    $cmd = CAF::Process->new(
		["/sbin/mkinitrd -f", "/boot/initrd-$i.img", "$i"],
		log => $self)->run();
	}
    }

    $str = $f26->string_ref();
    $$str =~ s{^\s*\n}{}mg;
    $f26->set_contents($str);

    if ($f26->close()) {
	@rs = grep(m{^2\.6}, @releases);
	foreach $i (@rs) {
	    $cmd = CAF::Process->new(
		["/sbin/mkinitrd -f", "/boot/initrd-$i.img", "$i"],
		log => $self)->run();
	}
    }
}

sub Configure {
    my ($self,$config)=@_;
    my ($t, $f24, $f26, $c, $i);

    $t = $config->getElement("/software/components/modprobe")->getTree();
    $f24 = $self->file_open("/etc/modules.conf");
    $f26 = $self->file_open("/etc/modprobe.conf");

    $self->process_aliases($t, $f24, $f26);
    $self->process_options($t, $f24, $f26);
    $self->process_install($t, $f24, $f26);
    $self->process_remove($t, $f24, $f26);

    $self->mkinitrd($f24, $f26);
    return 1;
}



1;
