#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::sudo;

=pod

=head1 DESCRIPTION

Test the C<Configure> method. We only have to ensure that all methods
are called in the correct order, which is to say C<write_sudoers> is
called last.

All other methods must be called, but B<before> C<write_sudoers>.

=cut

eval {use Class::Inspector; };

plan skip_all => "Imposible to redefine already tested methods. Skipping" if $@;

my $f = Class::Inspector->functions('NCM::Component::sudo');

# Replaces the methods passed as arguments with stubs that allow to
# track in which order they are called.
sub disable_all_executions
{
    my @funcs = @_;
    no strict 'refs';
    no warnings 'redefine';

    my $j;
    foreach my $i (@funcs) {
	*{"NCM::Component::sudo::$i" } = sub {
	    my $self = shift;
	    $self->{$i} = ++$j;
	    return 0;
	};
    }
    use warnings 'redefine';
    use strict 'refs';
}

my $cmp = NCM::Component::sudo->new('sudo');

my @disabled = grep($_ =~ m{^(?:generate|write)}, @$f);
disable_all_executions(@disabled);
$cmp->Configure();

foreach my $i (grep($_ !~ m{^write}, @disabled)) {
    ok(exists($cmp->{$i}), "Method $i gets called");
    ok($cmp->{$i} < $cmp->{write_sudoers}, "write_sudoers called after $i");
}

done_testing();
