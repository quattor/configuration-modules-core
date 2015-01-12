package OpennebulaMock;

use Test::MockModule;
use Test::More;
use Data::Dumper;
use base 'Exporter';
use XML::Simple;
use Cwd;

use rpcdata;

our @EXPORT = qw(rpc_history_reset rpc_history_ok diag_rpc_history);


my @rpc_history = ();
my @rpc_history_full = ();

# DEBUG only (can't get the output in unittests otherwise)
sub dlog {
    my ($type, @args) = @_;
    diag("[".uc($type)."] ".join(" ", @args));
}
our $nco = Test::MockModule->new('NCM::Component::opennebula');
foreach my $type ("error", "info", "verbose", "debug", "warn") {
    $nco->mock( $type, sub { shift; dlog($type, @_); } );
}

sub dump_rpc {
    return explain(\@rpc_history);
}

sub diag_rpc_history {
    diag("DEBUG rpc_history ".join(", ", @rpc_history));
};

# similar to Test::Quattor::command_history_reset
sub rpc_history_reset {
    @rpc_history = ();
    @rpc_history_full = ();
}

# similar to Test::Quattor::command_history_ok
sub rpc_history_ok {
    my $rpcs = shift;

    my $lastidx = -1;
    foreach my $rpc (@$rpcs) {
        # start iterating from lastidx+1
        my ( $index )= grep { $rpc_history[$_] =~ /$rpc/  } ($lastidx+1)..$#rpc_history;
        return 0 if !defined($index) or $index <= $lastidx;
        $lastidx = $index;
    };
    # in principle, when you get here, all is ok.                                                                                                                                        
    # but at least 1 command should be found, so lastidx should be > -1                                                                                                                  

    return $lastidx > -1;
    
}

sub mock_rpc {
    my ($self, $method, @params) = @_;
    my @params_values;
    foreach my $param (@params) {
        push(@params_values, $param->[1]);
    };

    push(@rpc_history, $method);
    push(@rpc_history_full, [$method, @params]);

    foreach my $short (sort keys %rpcdata::cmds) {
        my $data = $rpcdata::cmds{$short};

        my $sameparams = join(" _ ", @params_values) eq join(" _ ", @{$data->{params}});
        my $samemethod = $method eq $data->{method};
        if ($samemethod && $sameparams && defined($data->{out})) {
            note("This is my shortname:", $short);
            note("rpc internal params: ", join(" _ ", @params_values));
            note("rpc dictionary params: ", join(" _ ", @{$data->{params}}));
            note("rpc method: ", $method);

            if ($data->{out} =~ m/^\d+$/) {
                note("is id ", $data->{out});
                return $data->{out};
            } else {
                note("is xml ", $data->{out});
                return XMLin($data->{out}, forcearray => 1);
            } 
        }
    }
};

our $opennebula = Test::MockModule->new('Net::OpenNebula');
$opennebula->mock( '_rpc',  \&mock_rpc);

my $mock = Test::MockModule->new('CAF::TextRender');
$mock->mock('new', sub {
    my $init = $mock->original("new");
    my $trd = &$init(@_);
    $trd->{includepath} = getcwd()."/target/share/templates/quattor";
    return $trd;
});


1;
