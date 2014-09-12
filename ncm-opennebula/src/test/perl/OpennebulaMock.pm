package OpennebulaMock;

use Test::MockModule;
use Test::More;
use Data::Dumper;
use base 'Exporter';
use XML::Simple;

use rpcdata;

our @EXPORT = qw(rpc_history_reset rpc_history_ok diag_rpc_history);


my @rpc_history = ();
my @rpc_history_full = ();


sub dump_rpc {
    return Dumper(\@rpc_history);
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

sub mock_rpc_basic {
    my ($self, $method, @params) = @_;
    push(@rpc_history, $method);
    push(@rpc_history_full, [$method, @params]);
    if ($method eq "one.host.allocate") {
	return []; # return ARRAY
    } else {
	return ();# return hash reference
    }
};


sub mock_rpc {
    my ($self, $method, @params) = @_;
    my @params_values;
    foreach my $param (@params) {
	push(@params_values, $param->[1]);
    };

    push(@rpc_history, $method);
    push(@rpc_history_full, [$method, @params]);
    while (my ($short, $data) = each %rpcdata::cmds) {
	my $sameparams = join(" _ ", @params_values) eq join(" _ ", @{$data->{params}});
	my $samemethod = $method eq $data->{method};
    diag("This is my shortname:", $short);

    diag("rpc params: ", join(" _ ", @params_values));
    #diag("There are data params ", join(" _ ", @{$data->{params}}));


	if ($samemethod && $sameparams && defined($data->{out})) {
	    if ($data->{out} =~ m/^\d+$/) {
		    diag("is id ", $data->{out});
		    return $data->{out};
	    } else {
		    diag("is xml ", $data->{out});
            #my $xmldata = XMLin($data->{out}, ForceArray => 1);
            #diag("xml Dumper : ", Dumper(\$xmldata));
            return XMLin($data->{out}, forcearray => 1);
	    } 
        

    }

    }
   
};

our $opennebula = new Test::MockModule('Net::OpenNebula');
#$opennebula->mock( '_rpc',  \&mock_rpc_basic);
$opennebula->mock( '_rpc',  \&mock_rpc);




1;

