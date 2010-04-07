# ${license-info}
# ${developer-info}
# ${author-info}

#
# iptables - Setup the IPTABLES firewall.
#
# Managed files:
#   /etc/sysconfig/iptables
################################################################################

package NCM::Component::iptables;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use File::Copy;
use LC::Process qw(run);
use LC::Check;

use EDG::WP4::CCM::Element;
use EDG::WP4::CCM::Resource;

$NCM::Component::iptables::NoActionSupported = 1;

##########################################################################
# Global variables
##########################################################################

my $path_iptables     = '/software/components/iptables';


my %iptables_totality = (); # hash of tables, chains & targets

@{$iptables_totality{filter}{chains}}   = ('input','output','forward');
@{$iptables_totality{filter}{targets}}  = ('ordered','log','accept','reject', 'return', 'classify', 'ulog', 'drop');
@{$iptables_totality{filter}{commands}} = ('-A', '-D', '-I', '-R', '-N');

@{$iptables_totality{nat}{chains}}   = ('prerouting', 'output', 'postrouting');
@{$iptables_totality{nat}{targets}}  = ('dnat', 'snat', 'masquerade', 'redirect');
@{$iptables_totality{nat}{commands}} = ('-A', '-D', '-I', '-R', '-N');

@{$iptables_totality{mangle}{chains}}   = ('prerouting', 'input', 'output', 'forward', 'postrouting');
@{$iptables_totality{mangle}{targets}}  = ('tos', 'ttl', 'mark', 'netmap', 'classify', 'dscp', 'ecn', 'mark', 'same', 'tcpmss');
@{$iptables_totality{mangle}{commands}} = ('-A', '-D', '-I', '-R', '-N');

##########################################################################
sub regExp () {
    my $reg = "@_";
    $reg =~ s/\s/\|/g;
    return $reg;
}
##########################################################################

# Right order for iptables options.
my %options_ord = ( '-N'                  => 0,
                    '-A'                  => 0,
                    '-D'                  => 0,
                    '-I'                  => 0,
                    '-R'                  => 0,
                    '-s'                  => 1,
                    '-d'                  => 2,
                    '-p'                  => 3,
                    '--sport'             => 4,
                    '--dport'             => 5,
                    '--in-interface'      => 6,
                    '--out-interface'     => 7,
                    '--match'             => 8,
		    '--fragment'          => 9,
		    '! --fragment'        => 9,
		    '--set'               => 9,
		    '--dports'            => 9,
		    '--sports'            => 9,
                    '--pkt-type'          => 9,
                    '--state'             => 9,
		    '--ctstate'           => 9,
                    '--ttl'               => 9,
                    '--tos'               => 9,
                    '--sid-owner'         => 9,
                    '--limit'             => 9,
		    '--rcheck'            => 10,
		    '--seconds'           => 11,
                    '--uid-owner'         => 11,
                    '--syn'               => 12,
                    '! --syn'             => 12,
                    '--icmp-type'         => 13,
                    '--tcp-flags'         => 13,
                    '--tcp-option'        => 13,
                    '--length'            => 13,
                    '-j'                  => 14,
                    '--log-prefix'        => 15,
                    '--log-tcp-sequence'  => 16,
                    '--reject-with'       => 16,
                    '--set-class'         => 17,
                    '--log-level'         => 18,
                    '--log-tcp-options'   => 19,
                    '--log-ip-options'    => 20,
                    '--log-uid'           => 20,
                    '--limit-burst'       => 21,
                    '--to-destination'    => 22,
                    '--to-ports'          => 22
    );

# Translate resource names to iptables options.
my %options_tra = ( 'new_chain'          => '-N',
                    'append'             => '-A',
                    'delete'             => '-D',
                    'insert'             => '-I',
                    'replace'            => '-R',
                    'target'             => '-j',
                    'jump'               => '-j',
                    'src_addr'           => '-s',
                    'src'                => '-s',
                    'source'             => '-s',
                    'src_port'           => '--sport',
                    'src_ports'          => '--sports',
                    'dst_addr'           => '-d',
                    'dst'                => '-d',
                    'destination'        => '-d',
                    'dst_port'           => '--dport',
                    'dst_ports'          => '--dports',
                    'in_interface'       => '--in-interface',
                    'in-interface'       => '--in-interface',
                    'out_interface'      => '--out-interface',
                    'out-interface'      => '--out-interface',
                    'match'              => '--match',
                    'state'              => '--state',
		    'ctstate'            => '--ctstate',
                    'ttl'              	 => '--ttl',
                    'tos'                => '--tos',
                    'sid-owner'        	 => '--sid-owner',
                    'limit'              => '--limit',
                    'syn'                => '--syn',
                    'nosyn'              => '! --syn',
                    'icmp-type'          => '--icmp-type',
                    'protocol'           => '-p',
                    'log-prefix'         => '--log-prefix',
                    'log-level'          => '--log-level',
                    'log-tcp-sequence'   => '--log-tcp-sequence',
                    'log-tcp-options'    => '--log-tcp-options',
                    'log-ip-options'     => '--log-ip-options',
                    'log-uid'     => '--log-uid',
                    'reject-with'        => '--reject-with',
                    'set-class'                 => '--set-class',
                    'limit-burst'        => '--limit-burst',
                    'to-destination'     => '--to-destination',
                    'to-ports'           => '--to-ports',
                    'uid-owner'          => '--uid-owner',
                    'tcp-flags'                 => '--tcp-flags',
                    'tcp-option'         => '--tcp-option',
                    'pkt-type'               => '--pkt-type',
		    'length'             => '--length',
		    'fragment'           => '--fragment',
		    'nofragment'         => '! --fragment',
		    'set'                => '--set',
		    'rcheck'             => '--rcheck',
		    'seconds'             => '--seconds',
    );

# Preliminary test on the resource and sysconfig file options.
my %options_arg = ( '-A'              => "", #defined as "($regexp_chains)" on a table by table basis
                    '-D'              => "",
                    '-I'              => "",
                    '-R'              => "",
                    '-N'              => "",
                    '-p'              => '(tcp|udp|icmp|igmp|all)',
                    '-s'              => '(\!?\s*\d{0,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2}){0,1}|\S+)',
                    '-d'              => '(\!?\s*\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2}){0,1}|\S+)',
                    '--sport'         => '(\!?\s*[:\d]+|\!?\s*[\w:]+)',
                    '--dport'         => '(\!?\s*[:\d]+|\!?\s*[\w:]+)',
                    '--sports'        => '(\d+|\w+)(,(\d+|\w+)){0,14}',
                    '--dports'        => '(\d+|\w+)(,(\d+|\w+)){0,14}',
                    '--in-interface'  => '\!?\s*\w+',
                    '--out-interface' => '\!?\s*\w+',
                    '--match'         => '(tcp|udp|igmp|all|icmp|state|limit|owner|mark|ttl|pkttype|unclean|length|multiport|conntrack)',
                    '--pkt-type'      => '(unicast|broadcast|multicast)',
                    '--mark'          => '(\d+|\d+/\d+)',
                    '--ttl'           => '\d+',
                    '--tos'           => '\S+',
                    '--sid-owner'     => '\d+',
                    '--state'         => '(\!?\s+|)(new|established|related|invalid)',
                    '--limit'         => '\S+',
                    '--syn'           => '',
                    '! --syn'         => '',
                    '--icmp-type'     => '\w+',
                    '-j'              => "",
                    '--log-prefix'    => '\w+',
                    '--log-level'     => '(debug|info|notice|warning|warn|err|error|crit|alert|emerg|panic)',
		    '--log-tcp-sequence' => '',
                    '--log-tcp-options' => '',
                    '--log-ip-options' => '',
                    '--log-uid' => '',
		    '--reject-with' => '(icmp-net-unreachable|icmp-host-unreachable|icmp-port-unreachable|icmp-proto-unreachable|icmp-net-prohibited|icmp-host-prohibited|tcp-reset)',
                    '--set-class'       => '\d{1,2}:\d{1,2}',
                    '--limit-burst'     => '\S+',
                    '--to-destination'  => '\S+',
                    '--to-ports'        => '\d+(-\d+)?',
                    '--uid-owner'       => '\d+',
                    '--tcp-flags'       => '\S+',
                    '--tcp-option'      => '\d+',
		    '--length'          => '(\d+|\d+:\d+)',
		    '--ctstate'         => '(new|established|related|invalid|snat|dnat)(,(new|established|related|invalid|snat|dnat))*',
		    '--fragment'        => '',
		    '! --fragment'      => '',
		    '--set'             => '',
		    '--rcheck'          => '',
		    '--seconds'         => '\d+',
    );

# Operations to perform on the resource options when read for the first time.
my %options_op  = ( '-A'              => \&upercase,
                    '-D'              => \&upercase,
                    '-I'              => \&upercase,
                    '-R'              => \&upercase,
                    '-N'              => \&upercase,
                    '-j'              => \&upercase,
                    '-s'              => \&dns2ip,
                    '-d'              => \&dns2ip
    );

##########################################################################
# dns2ip () Translate host name to ip address.
#
# SYNOPSYS: $ip dns2ip ( $name )
#    INPUT: $name     - host name to translate;
#   OUTPUT: $ip       - ip address.
##########################################################################
sub dns2ip ( $ ) {
    my ($self, $name) = @_;
    my ($hostname, $alias, $addrtype, $length, $addr);
    my @addr;
    my $isneg = 0;

    if ( ! defined $name || $name eq "" ) {
	$self->debug(2, "dns2ip-BAD: empty name");
	return '';
    };

    if ($name =~ /^!\s*(.*)/) {
	$self->debug(3, "dns2ip-INFO: negative specification");
	$isneg = 1;
	$name = $1;
    }

    if ( $name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2}){0,1}$/ ) {
	$self->debug(2, "dns2ip-OK: already numeric");
	if ($isneg) {
	    return "! ".$name;
	} else {
	    return $name;
	}
    }

    ($hostname, $alias, $addrtype, $length, $addr) = gethostbyname($name);
    
    if ( !$hostname || $length != 4 || $addr eq "" ) {
	# no longer insist that the hostname in the config is canonical,
        # i.e. perfectly matches the DNS result
	$self->debug(2, "dns2ip-BAD: failed or weird gethostbyname");
	return '';
    }
    
    @addr = unpack ('C4', $addr);
    if ( scalar(@addr) != 4 ) {
	$self->debug(2, "dns2ip-BAD: weird address format/length?");
	return '';
    };
    
    $name =  "@addr";
    $name =~ s/\s/\./g;
    $self->debug(2, "dns2ip-OK: resolved $name");

    if ($isneg) {
	return "! ".$name;
    } else {
	return $name;
    }
}

##########################################################################
# upercase() Transform all lowercase text to upercase.
#
# SYNOPSYS: $text uppercase ( $text )
#    INPUT: $text     - text to transform;
#   OUTPUT: $text     - text in upercase.
##########################################################################
sub upercase {
    my ($self, $text) = @_;

    return '' if ( ! defined $text );

    $text =~ tr/a-z/A-Z/;

    return $text;
}

##########################################################################
# GetPathEntries() Get the entries of a resource path.
#
# SYNOPSYS: $entries GetPathEntries( $path, $config )
#    INPUT: $path     - resource path,
#           $config   - configuration object,
#   OUTPUT: $entries  - the resource path entries in associate array form;
#           $?        - 0 got entries,
#                     - 1 $path is missing,
#                     - 2 $path doesn't exist,
#                     - 3 $config is missing,
#                     - 4 $config is not an object,
#                     - 5 $path doesn't exist as a resource path,
#                     - 6 $path has no entries.
##########################################################################
sub GetPathEntries {
    my ($path, $config) = @_;
    my ($content, $entry, $name, $value);
    my $entries = {};

    # Check the input parameters.
    if ( ! defined $path   || $path   eq "" ) {
	$? = 1;
	$@ = "resource path to query empty";
	return $entries;
    }
    if ( ! defined $config || $config eq "" ) {
	$? = 3;
	$@ = "missing configuration object when getting resource path \"$path\"";
	return $entries;
    }

    # Check if the resource path $path exist.
    if ( ! $config->elementExists($path) ) {
	$? = 5;
	$@ = "resource path \"$path\" not found";
	return $entries;
    }

    # Get the perl object representing the resource path content.
    $content = $config->getElement($path);
    unless ( defined $content ) {
	$? = 6;
	$@ = "cannot get resource path \"$path\"";
	return $entries;
    }

    while ( $content->hasNextElement() ) {
	$entry  = $content->getNextElement();
	$name   = $entry->getName();
	$value  = $entry->getValue();
	$value  = '' if ( $entry->getType() == 33 );
	$value  =~ s/^[\s\t]*|[\s\t]*$//g;
	$value  =~ s/[\s\t]+/ /g;

	#this is a fix for the issue of values with the "command" key
	#no translation => iptables screwing up
	if ($name eq "command"){
	    $value = $options_tra{$value} if defined $options_tra{$value};
	}

	$entries->{$name} = $value;
    }

    $? = 0;
    $@ = "resource path \"$path\" ok";
    return $entries;
}

##########################################################################
# GetResource() Get all the entries of a resource path.
#
# SYNOPSYS: %entries GetResource( $path, $config )
#    INPUT: $path     - resource path,
#           $config   - configuration object,
#   OUTPUT: $entries  - the resource path entries in associate array form;
#           $?        - 0 got entries,
#                     - 1 $path is missing,
#                     - 2 $path doesn't exist,
#                     - 3 $config is missing,
#                     - 4 $config is not an object,
#                     - 5 $path doesn't exist as a resource path,
#                     - 6 $path has no entries,
#                     - 7 resource have at least one bad rule.
#   ASSUME: The rules content is valid.
##########################################################################
sub GetResource {
    my ($self, $path, $config) = @_;
    my ($entries, $table, $target, $rule, $name, $command, $key, $aux, $i);
    my $target_exists = 0;

    $entries = &GetPathEntries( $path, $config );
    return $entries if $?;

    foreach $table (keys %iptables_totality) {

	next if ( ! defined $entries->{$table} );

	#define the regular expressions for -N, -A etc based on the specific targets for table

	my $tmp = &upercase($self, &regExp(@{$iptables_totality{$table}{chains}}));
	$options_arg{$_} = $tmp foreach (@{$iptables_totality{$table}{commands}});
	$options_arg{'-j'} = &upercase($self, &regExp(@{$iptables_totality{$table}{targets}}));

	#

	$entries->{$table} = &GetPathEntries( "$path/$table", $config );
	next if $?;

	$entries->{$table}->{preamble} = &GetPathEntries( "$path/$table/preamble", $config );

	my $cnt = {};
	foreach $target ( @{$iptables_totality{$table}{targets}} ) {
	    $cnt->{$target} = 0;
	}

	$entries->{$table}->{rules} = &GetPathEntries( "$path/$table/rules", $config );
	next if $?;
	
RULE:	foreach $name (sort { $a <=> $b } keys %{$entries->{$table}->{rules}}) {
    next if ( $name !~ /^\d+$/ );
    $rule    = &GetPathEntries( "$path/$table/rules/$name", $config );
    return if $?;
    &rule_options_translate($rule);

    if ( ! defined $rule->{chain} ) {
	$? = 7;
	$@ = "missed chain entry on rule \"$path/$table/rules/$name\"";
	return {};
    }

    if ( defined $rule->{-j} ) {
	#check if exists
	if ( &upercase($self, $rule->{-j}) !~ /$options_arg{'-j'}/) {
	    $iptables_totality{$table}{user_targets}{&upercase($self, $rule->{-j})} = 1;
	}

    }

    $rule->{command}=$iptables_totality{$table}{commands}[0] if(! defined $rule->{command} || $rule->{command} eq "");
    $rule->{$rule->{command}} = $rule->{chain};
    delete $rule->{command};
    delete $rule->{chain};

    my $val = &regExp( @{$iptables_totality{$table}{commands}} );

    foreach $key (keys %{$rule}) {
	
	if ( defined $options_op{$key} && $options_op{$key} ne "" ) {
	    my $opresult;
	    $opresult = &{$options_op{$key}}($self, $rule->{$key});
	    if (!$opresult) {
		$self->warn("failed to convert $key : ".$rule->{$key}." - IGNORING THIS RULE");
		next RULE;
	    } else {
		$self->debug(2, "converted $key : ".$rule->{$key}." to $opresult");
		$rule->{$key} = $opresult;
	    }
	}

	if ( defined $options_arg{$key} && $options_arg{$key} ne "" ) {
	    $aux = $options_arg{$key};
	    if ($rule->{$key} !~ /^$aux$/ && $key =~ /^$val$/){
		my $skip = 0;
		foreach (@{$iptables_totality{$table}{targets}}) {
		    $skip = 1 if $_ eq $rule->{$key};
		}
		next if $skip;
		push(@{$iptables_totality{$table}{targets}}, $rule->{$key});
		$iptables_totality{$table}{user_targets}{$rule->{$key}} = 1;
	    }
	}
    }

    if (defined $rule->{'-j'}) {
	$target = $rule->{'-j'};
	$target =~ tr/A-Z/a-z/;
    }


    if ( defined $entries->{$table}->{ordered_rules} &&
	 $entries->{$table}->{ordered_rules} eq "yes" ) {
	$target = "ordered";
    }

    if ( defined $cnt->{$target} ) {
	next if ( ! &find_rule($rule,$entries->{$table}->{rules}->{$target}->{$cnt->{$target}}) );
	$entries->{$table}->{rules}->{$target}->{$cnt->{$target}} = $rule;
	$cnt->{$target}++;
    }

}
    }

    $? = 0;
    $@ = "get all resource path \"$path\" entries";
    return $entries;
}

##########################################################################
# sort_keys() Give a rule keys in the right order to print to the
#             iptables configuration file.
#
# SYNOPSYS: @keys sort_keys ( $rule )
#    INPUT: $rule     - pointer to an hash table describing the rule;
#   OUTPUT: @keys     - list of keys in the right order,
#           $?        - 0 keys sorted,
#                     - 1 error.
#      USE: %options_ord
#   ASSUME: If rule is not empty then is well formed.
##########################################################################
sub sort_keys {
    my ($self,$rule) = @_;
    my ($i, $m, $purge, $swap, $reg);
    my (@keys, @ord);

    # Check parameters.
    if ( $rule !~ /^HASH/ ) {
	$? = 1;
	$@ = "bad rule";
	return ();
    }

    @keys = keys %{$rule};

    $purge = 1;
WHILE: while( $purge ) {
FOR:     for($i=0, $purge=0; $i<=$#keys; $i++) {
    next if ( $keys[$i] !~ /^(err|checked)$/ );
    splice(@keys,$i,1);
    $purge = 1;
    last FOR;
}
}

    $swap = 1;
    while ( $swap ) {
	for($m=0, $swap=0; $m<$#keys; $m++) {
	    for($i=$m+1; $i<=$#keys; $i++) {

		$self->error("$keys[$i] is not a valid option\n") if ! exists $options_ord{$keys[$i]};
		$self->error("$keys[$m] is not a valid option\n") if ! exists $options_ord{$keys[$m]};

		#next
		if (! exists $options_ord{$keys[$i]} || ! exists $options_ord{$keys[$m]}){
		    $? = 1;
		    $@ = "keys unsorted";
		    return @keys;
		}
		next if ( $options_ord{$keys[$i]} > $options_ord{$keys[$m]} );
		$reg      = $keys[$i];
		$keys[$i] = $keys[$m];
		$keys[$m] = $reg;
		$swap++;
	    }
	}
    }

    $? = 0;
    $@ = "keys sorted";

    return @keys;
}

##########################################################################
# rule_options_translate() Translate the template options type to iptables
#                          options style.
#
# SYNOPSYS: $? rule_options_translate ( $rule )
#    INPUT: $rule     - pointer to an hash table describing the rule;
#   OUTPUT: $?        - 0 options translated,
#                     - 1 error.
#      USE: %options_tra
#   ASSUME: If rule is not empty then is well formed.
##########################################################################
sub rule_options_translate {
    my ($rule) = @_;
    my $key;

    # Check parameters.
    if ( $rule !~ /^HASH/ ) {
	$? = 1;
	$@ = "bad rule";
	return $?;
    }

    foreach $key (keys %{$rule}) {

	next if ( ! defined $options_tra{$key} || $options_tra{$key} eq "" );
	next if (   defined $rule->{$options_tra{$key}} );
	$rule->{$options_tra{$key}} = $rule->{$key};
	delete $rule->{$key};

    }

    $? = 0;
    $@ = "options translated";

    return $?;
}

##########################################################################
# WriteFile() Create and fill a filename.
#
# SYNOPSYS: $? WriteFile ( $filename, $iptables )
#    INPUT: $filename - full path to the filename;
#           $path     - main component resource path,
#           $config   - component object descriptor;
#   OUTPUT: $?        - 0 $filename writed,
#                     - 1 $filename is missing,
#                     - 2 $path missing,
#                     - 6 cannot open $filename for writing,
#                     - 7 cannot close $filename.
#   ASSUME: The component resource path is well formed.
##########################################################################
sub WriteFile {
    my ($self, $filename, $iptables) = @_;
    my ($table, $chain, $target, $rule, $name, $field, $line);
    my (@names);

    # Check input parameters.
    if ( ! defined $filename || $filename eq "" ) {
	$? = 1;
	$@ = 'filename to write missing';
	return $?;
    }

    # Open the file.
    unless ( open(FILE, ">$filename") ) {
	$? = 6;
	$@ = "cannot open $filename";
	return $?;
    }
    # write our "tag" into it. Assist some poor admin in debugging..
    print FILE "# Firewall configuration written by ncm-iptables\n";
    print FILE "#  Manual modifications will be overwritten on the next NCM run.\n";

    # Write new content to file.
    if ( defined $iptables && ref($iptables) =~ /^HASH/ ) {
	foreach $table (keys %iptables_totality) {
	    next if ( ! defined $iptables->{$table} || $iptables->{$table} eq "" ||
		      ref($iptables->{$table}) !~ /^HASH/ );

	    print FILE "*$table\n";


	    if ( defined $iptables->{$table}->{preamble} &&
		 ref($iptables->{$table}->{preamble}) =~ /^HASH/ ) {
		my $preamble = $iptables->{$table}->{preamble};



		foreach $chain ( @{$iptables_totality{$table}{chains}}) {
		    next if ( ! defined $preamble->{$chain} || $preamble->{$chain} eq "" );
		    my $g = $chain;
		    $g =~ tr/a-z/A-Z/;
		    $preamble->{$chain} =~ s/^[\s\t]*|[\s\t]*$//g;
		    $preamble->{$chain} =~ s/[\s\t+]/ /g;
		    print FILE ":$g $preamble->{$chain}\n";
		}
	    }



	    foreach $target ( sort keys %{$iptables_totality{$table}{user_targets}} ){
		print FILE "-N $target\n";
	    }

	    foreach $target (@{$iptables_totality{$table}{targets}}) {

		next if ( ! defined $iptables->{$table}->{rules}->{$target}         );
		next if (   ref($iptables->{$table}->{rules}->{$target}) !~ /^HASH/ );
		next if ( ! scalar(%{$iptables->{$table}->{rules}->{$target}})      );

		foreach $name (sort { $a <=> $b; } keys %{$iptables->{$table}->{rules}->{$target}}) {

		    next if ( $name !~ /^\d+$/ );

		    $rule = $iptables->{$table}->{rules}->{$target}->{$name};
		    $line = '';
		    foreach $field (&sort_keys($self,$rule)) {
			$line .= ($line) ? " $field" : $field;
			$line .= " $rule->{$field}" if $options_arg{$field};
		    }
		    print FILE "$line\n" if $line and $line !~ /^-N/;

		}

	    }

	    print FILE "$iptables->{$table}->{epilogue}\n"
		if ( defined $iptables->{$table}->{epilogue} && $iptables->{$table}->{epilogue} ne "");

	}
    }

    # Close the temporary file.
    unless ( close(FILE) ) {
	$? = 7;
	$@ = "cannot close $filename";
	return $?;
    }

    $? = 0;
    $@ = "modified $filename";
    return $?;
}

##########################################################################
# cmp_rules() Compare two iptables rules.
#
# SYNOPSYS: $? cmp_rules ( $rule1, $rule2 )
#    INPUT: $rule1    - pointer to an hash table describing the one rule,
#           $rule2    - pointer to an hash table describing the other rule;
#   OUTPUT: $?        - 0 the rules are equal,
#                     - 1 one, or the two rules, is empty or is not an
#                         hash tables, or the rules are different.
##########################################################################
sub cmp_rules {
    my ($rule1, $rule2) = @_;
    my ($field);
    my (@fields1, @fields2);

    # Check parameters.
    if ( ! defined $rule1 || ref($rule1) !~ /^HASH/ ) {
	$? = 1;
	$@ = "first rule is not an hash table";
	return $?;
    }
    if ( ! defined $rule2 || ref($rule2) !~ /^HASH/ ) {
	$? = 1;
	$@ = "second rule is not an hash table";
	return $?;
    }

    $? = 1;
    $@ = "rule is not in the list";

    @fields1 = keys %{$rule1};
    @fields2 = keys %{$rule2};

    return $? if ( scalar(@fields1) <= 0 && scalar(@fields2) >  0 );
    return $? if ( scalar(@fields1) >  0 && scalar(@fields2) <= 0 );

    if ( scalar(@fields1) <= 0 && scalar(@fields2) <=  0 ) {
	$? = 0;
	$@ = "rules are equal";
	return $?;
    }
    return $? if ( scalar(@fields1) != scalar(@fields2) );

    foreach $field (@fields1) {
	return $? if ( ! defined $rule2->{$field} ||
		       $rule1->{$field} ne "$rule2->{$field}" );
    }

    $? = 0;
    $@ = "rule found in the list";
    return $?;
}

##########################################################################
# find_rule() Find a rule in a list of rules.
#
# SYNOPSYS: $? find_rule ( $rule1, $hash )
#    INPUT: $rule     - pointer to an hash table describing the rule to find,
#           $hash     - hash list of rules to search on, the hash tables
#                       are on the forma (0,hash), (1,hash), ...;
#   OUTPUT: $?        - 0 the rules was found,
#                     - 1 the rule was not found.
##########################################################################
sub find_rule {
    my ($rule, $hash) = @_;
    my ($name);

    # Check parameters.
    if ( ! defined $rule || ref($rule) !~ /^HASH/ ) {
	$? = 1;
	$@ = "rule is not an hash table";
	return $?;
    }
    if ( ! defined $hash || ref($hash) !~ /^HASH/ ) {
	$? = 1;
	$@ = "hash list is not an HASH table";
	return $?;
    }
    if ( ! scalar(%{$hash}) ) {
	$? = 1;
	$@ = "hash list empty";
    }

    foreach $name (keys %{$hash}) {

	next if ( $name !~ /^\d+$/ );
	next if ( ref($hash->{$name}) !~ /^HASH/ );

	if ( ! &cmp_rules( $rule, $hash->{$name} ) && ! $? ) {
	    $@ = "rule found on the list";
	    return $?
	}

    }

    $? = 1;
    $@ = "rule is not on the list";
    return $?;
}

##########################################################################

##########################################################################

##########################################################################
sub Configure($$@) {
##########################################################################

    my ($self, $config) = @_;

    my $iptables;


    ######################################################################
    # Get global components parameters
    ######################################################################
    $iptables = $self->GetResource( $path_iptables, $config );
    $self->error($@) and return 1 if $?;

    ######################################################################
    # Write changes to file
    ######################################################################
    my $iptc_temp = "/var/ncm/tmp/iptables.tmp";
    unlink($iptc_temp);

    &WriteFile($self, $iptc_temp, $iptables );
    if ($? > 0 ) {
	# bad - bail out
	$self->error($@);
	return 1;
    }
    $self->debug(1,$@);

    my $changes = 0;
    $changes = LC::Check::file('/etc/sysconfig/iptables',
			       owner => 'root',
			       group => 'root',
			       mode => '0444',
			       source => "$iptc_temp",
	);
    if($changes) {
	####################################################################
	# Reload the service - file changed
	####################################################################

	if ($NoAction) {
	    $self->info("Would run \"/sbin/service iptables condrestart\"");
	} else {
	    # allow no "dangling" file descriptors, this may be executing in a restricted
	    # targeted SELinux context

	    my $ip_stdouterr;
	    if (LC::Process::execute([qw(/sbin/service iptables condrestart)],
				     "stdout" => \$ip_stdouterr,
				     "stderr" => "stdout") ) {
		$self->info("ran \"/sbin/service iptables condrestart\"");
		if($ip_stdouterr) {
		    $self->info($ip_stdouterr);
		}
	    } else {
		$self->error("command \"/sbin/service iptables condrestart\" failed:\n$ip_stdouterr");
	    }
	}
    } else {
	$self->info("No change for /etc/sysconfig/iptables, not restarting service");
    }
    unlink($iptc_temp);
    return;
}

1;      # Required for PERL modules

### Local Variables: ///
### mode: perl ///
### End: ///
