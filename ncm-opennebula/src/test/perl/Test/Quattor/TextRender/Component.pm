# ${license-info}
# ${developer-info
# ${author-info}
# ${build-info}

use strict;
use warnings;

package Test::Quattor::TextRender::Component;

use File::Basename;

use Test::More;
use Test::Quattor::Panc qw(set_panc_includepath);

use Test::Quattor::TextRender::Suite;

use File::Path qw(mkpath);
use Cwd qw(getcwd abs_path);

use base qw(Test::Quattor::TextRender);

=pod

=head1 NAME

Test::Quattor::TextRender::Component - Class for unittesting 
NCM component TT files.

=head1 DESCRIPTION

This class should be used to unittest NCM component TT files.

To be used as

    my $u = Test::Quattor::TextRender::Metaconfig->new(
        service => 'logstash',
        version => '1.2',
        )->test();

=head2 Public methods

=over

=item new

Returns a new object, basepath is the default location
for metaconfig-unittests.

Accepts the following options

=over

=item service

The name of the service (the service is a subdirectory of the basepath).

=item version

If a specific version is to be tested (undef assumes no version).

=back

=back

=cut

sub _initialize
{
    my ($self) = @_;

    ok(exists($self->{component}), "Component name set ". ($self->{component} || ""));

    $self->{srcpath} = getcwd() . "/src/main";
    $self->{targetpath} = getcwd() . "/target";

    if (!$self->{basepath}) {
        $self->{basepath} = "$self->{srcpath}/resources";
    }
    
    # derive ttpath from
    # with resources as relpath!
    $self->{ttpath} = "$self->{srcpath}"; 
    $self->{ttpath} = "$self->{targetpath}/share/templates/quattor";

    
    # TODO pan files are not relative to basepath
    if (! exists($self->{pannamespace})) {
        # the component has a rolled-out pan-namespace 
        $self->{pannamespace} = "components/$self->{component}";
        $self->{panpath} = "$self->{targetpath}/pan/$self->{pannamespace}";
        $self->{panpath_in_namespacepath} = 1;
        $self->{namespacepath} = "$self->{targetpath}/pan";
    }

    ok($self->{pannamespace}, "Pannamespace set ".($self->{pannamespace} | ""));
    ok(-d $self->{panpath}, "Panpath directory ".($self->{panpath} | ""));
    
    if ($self->{panpath_in_namespacepath}) {
        $self->verbose("panpath_in_namespacepath set namespacepath to $self->{panpath}");
    } elsif (!$self->{namespacepath}) {
        # This path is not for distributing the pan file
        # can't be just pan for AII / or components
        # is there a way to avoid taking a copy?
        my $dest = "$self->{targetpath}/TT_test_tmp_pan"; 
        if (!-d $dest) {
            mkpath($dest)
        }
        $self->{namespacepath} = $dest;
    }

    $self->SUPER::_initialize();

}

#
# Return path to template-library-core to allow "include 'pan/types';"
#
sub get_template_library_core
{
    # only for logging
    my $self = shift;

    my $tlc = $ENV{QUATTOR_TEST_TEMPLATE_LIBRARY_CORE};
    if ($tlc && -d $tlc) {
        $self->verbose(
            "template-library-core path $tlc set via QUATTOR_TEST_TEMPLATE_LIBRARY_CORE");
    } else {

        # TODO: better guess?
        my $d = "../template-library-core";
        if (-d $d) {
            $tlc = $d;
        } elsif (-d "../$d") {
            $tlc = "../$d";
        } else {
            $self->error("no more guesses for template-library-core path");
        }
    }
    if ($tlc) {
        $tlc = abs_path($tlc);
        $self->verbose("template-library-core path found $tlc");
    } else {
        $self->error(
            "No template-library-core path found (set QUATTOR_TEST_TEMPLATE_LIBRARY_CORE?)");
    }
    return $tlc;
}


sub make_namespace
{
    my ($self, $panpath, $pannamespace) = @_;
    # Set panc include dirs
    if($self->{panpath_in_namespacepath}) {
        $self->verbose("panpath_in_namespacepath set to $self->{namespacepath}. No copy made.");
        # TODO  should return?
        # support in original code?
        my ($pans, $ipans) = $self->gather_pan($panpath, $pannamespace);
        my @not_copies = keys %$pans;
        return \@not_copies;
    } else {
        $self->verbose("panpath_in_namespacepath not set, make_namespace.");
        return $self->SUPER::make_namespace($panpath, $pannamespace);
    };
};

=pod

=head2 test

Run all unittests to validate a set of templates. 

=cut

sub test
{
    my ($self) = @_;

    $self->test_gather_tt();
    $self->test_gather_pan();

    # Set panc include dirs
    $self->make_namespace($self->{panpath}, $self->{pannamespace});
    set_panc_includepath($self->{namespacepath}, $self->get_template_library_core);

    my $testspath = "$self->{basepath}";
    $testspath .= "/$self->{version}" if (exists($self->{version}));

    # set relapth here? then no mocking below?
    my $st   = Test::Quattor::TextRender::Suite->new(
        # this is a hack to deal with fixed relpath? CAF::TextRender doesn't like it much
        # need to suppport undefined relpath and multiple include paths in CAF::TextRender
        includepath => "$self->{ttpath}", # also in Metaconfig with ttpath?
        testspath   => "$testspath/tests",
    );

    $st->test();

}


# TODO pass relpath in Test::Quattor::TextRender::RegexpTest render method
use Test::MockModule;
our $mock = Test::MockModule->new('CAF::TextRender');
$mock->mock('new', sub {
    my $init = $mock->original("new");
    my $trd = &$init(@_);
    $trd->{relpath} = "opennebula"; # no relpath is possible??
    return $trd;
});

1;
