# ${license-info}
# ${developer-info}
# ${author-info}
#
# iptables - Setup the IPTABLES firewall.
#
package NCM::Component::iptables;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use File::Copy;
use File::Temp qw(tempfile);
use LC::Process qw(run);
use LC::Check;
use Readonly;

use EDG::WP4::CCM::Element;
use EDG::WP4::CCM::Resource;

$NCM::Component::iptables::NoActionSupported = 1;

# Global variables
Readonly::Scalar my $path_iptables => '/software/components/iptables';

Readonly::Scalar my $CONFIG_IPTABLES => '/etc/sysconfig/iptables';

# hash of tables, chains & targets
my %iptables_totality = (
    filter => {
        chains => ['input','output','forward'],
        targets => ['ordered','log','accept','reject', 'return', 'classify', 'ulog', 'drop'],
        commands => ['-A', '-D', '-I', '-R', '-N'],
    },
    nat => {
        chains => ['prerouting', 'output', 'postrouting'],
        targets => ['dnat', 'snat', 'masquerade', 'redirect', 'log'],
        commands => ['-A', '-D', '-I', '-R', '-N'],
    },
    mangle => {
        chains => ['prerouting', 'input', 'output', 'forward', 'postrouting'],
        targets => ['tos', 'ttl', 'mark', 'netmap', 'classify', 'dscp', 'ecn', 'mark', 'same', 'tcpmss'],
        commands => ['-A', '-D', '-I', '-R', '-N'],
    },
);

sub regExp {
    my ($self, $reg) = @_;
    $reg =~ s/\s/\|/g;
    return $reg;
}

# Right order for iptables options.
Readonly::Hash my %OPTION_SORT_ORDER => (
    '-N'                 => 0,
    '-A'                 => 0,
    '-D'                 => 0,
    '-I'                 => 0,
    '-R'                 => 0,
    '-s'                 => 1,
    '-d'                 => 2,
    '-p'                 => 3,
    '--in-interface'     => 6,
    '--out-interface'    => 7,
    '--match'            => 8,
    '--fragment'         => 9,
    '! --fragment'       => 9,
    '--set'              => 9,
    '--sport'            => 9,
    '--dport'            => 9,
    '--dports'           => 9,
    '--sports'           => 9,
    '--pkt-type'         => 9,
    '--state'            => 9,
    '--ctstate'          => 9,
    '--ttl'              => 9,
    '--tos'              => 9,
    '--sid-owner'        => 9,
    '--limit'            => 9,
    '--rcheck'           => 10,
    '--remove'           => 10,
    '--rdest'            => 10,
    '--rsource'          => 10,
    '--rttl'             => 10,
    '--update'           => 10,
    '--seconds'          => 11,
    '--hitcount'         => 11,
    '--name'             => 11,
    '--uid-owner'        => 11,
    '--syn'              => 12,
    '! --syn'            => 12,
    '--icmp-type'        => 13,
    '--tcp-flags'        => 13,
    '--tcp-option'       => 13,
    '--length'           => 13,
    '-j'                 => 14,
    '--log-prefix'       => 15,
    '--log-tcp-sequence' => 16,
    '--reject-with'      => 16,
    '--set-class'        => 17,
    '--log-level'        => 18,
    '--log-tcp-options'  => 19,
    '--log-ip-options'   => 20,
    '--log-uid'          => 20,
    '--limit-burst'      => 21,
    '--to-destination'   => 22,
    '--to-source'        => 22,
    '--to-ports'         => 22,
    '--comment'          => 23,
);

# Translate resource names to iptables options.
Readonly::Hash my %OPTION_MAPPINGS => (
    'new_chain'          => '-N',
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
    'ttl'                => '--ttl',
    'tos'                => '--tos',
    'sid-owner'          => '--sid-owner',
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
    'log-uid'            => '--log-uid',
    'reject-with'        => '--reject-with',
    'set-class'          => '--set-class',
    'limit-burst'        => '--limit-burst',
    'to-destination'     => '--to-destination',
    'to-source'          => '--to-source',
    'to-ports'           => '--to-ports',
    'uid-owner'          => '--uid-owner',
    'tcp-flags'          => '--tcp-flags',
    'tcp-option'         => '--tcp-option',
    'pkt-type'           => '--pkt-type',
    'length'             => '--length',
    'fragment'           => '--fragment',
    'nofragment'         => '! --fragment',
    'set'                => '--set',
    'rcheck'             => '--rcheck',
    'remove'             => '--remove',
    'rdest'              => '--rdest',
    'rsource'            => '--rsource',
    'rttl'               => '--rttl',
    'update'             => '--update',
    'seconds'            => '--seconds',
    'hitcount'           => '--hitcount',
    'name'               => '--name',
    'comment'            => '--comment',
);

# Preliminary test on the resource and sysconfig file options.
my %OPTION_VALIDATORS = (
    '-A'                 => "", #defined as "($regexp_chains)" on a table by table basis
    '-D'                 => "",
    '-I'                 => "",
    '-R'                 => "",
    '-N'                 => "",
    '-p'                 => '(tcp|udp|icmp|igmp|all)',
    '-s'                 => '(\!?\s*\d{0,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2}){0,1}|\S+)',
    '-d'                 => '(\!?\s*\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2}){0,1}|\S+)',
    '--sport'            => '(\!?\s*[:\d]+|\!?\s*[\w:]+)',
    '--dport'            => '(\!?\s*[:\d]+|\!?\s*[\w:]+)',
    '--sports'           => '(\d+|\w+)(,(\d+|\w+)){0,14}',
    '--dports'           => '(\d+|\w+)(,(\d+|\w+)){0,14}',
    '--in-interface'     => '\!?\s*\w+',
    '--out-interface'    => '\!?\s*\w+',
    '--match'            => '(tcp|udp|igmp|all|icmp|state|limit|owner|mark|ttl|pkttype|recent|unclean|length|multiport|conntrack)',
    '--pkt-type'         => '(unicast|broadcast|multicast)',
    '--mark'             => '(\d+|\d+/\d+)',
    '--ttl'              => '\d+',
    '--tos'              => '\S+',
    '--sid-owner'        => '\d+',
    '--state'            => '(\!?\s+|)(new|established|related|invalid)',
    '--limit'            => '\S+',
    '--syn'              => '',
    '! --syn'            => '',
    '--icmp-type'        => '\w+',
    '-j'                 => "",
    '--log-prefix'       => '\w+',
    '--log-level'        => '(debug|info|notice|warning|warn|err|error|crit|alert|emerg|panic)',
    '--log-tcp-sequence' => '',
    '--log-tcp-options'  => '',
    '--log-ip-options'   => '',
    '--log-uid'          => '',
    '--reject-with'      => '(icmp-net-unreachable|icmp-host-unreachable|icmp-port-unreachable|icmp-proto-unreachable|icmp-net-prohibited|icmp-host-prohibited|tcp-reset)',
    '--set-class'        => '\d{1,2}:\d{1,2}',
    '--limit-burst'      => '\S+',
    '--to-destination'   => '\S+',
    '--to-source'        => '\S+',
    '--to-ports'         => '\d+(-\d+)?',
    '--uid-owner'        => '\d+',
    '--tcp-flags'        => '\S+',
    '--tcp-option'       => '\d+',
    '--length'           => '(\d+|\d+:\d+)',
    '--ctstate'          => '(new|established|related|invalid|snat|dnat)(,(new|established|related|invalid|snat|dnat))*',
    '--fragment'         => '',
    '! --fragment'       => '',
    '--set'              => '',
    '--rcheck'           => '',
    '--update'           => '',
    '--remove'           => '',
    '--rdest'            => '',
    '--rsource'          => '',
    '--rttl'             => '',
    '--seconds'          => '\d+',
    '--hitcount'         => '\d+',
    '--name'             => '\S+',
    '--comment'          => '\S+',
);

# Operations to perform on the resource options when read for the first time.
Readonly::Hash my %OPTION_MODIFIERS => (
    '-A' => 'uppercase',
    '-D' => 'uppercase',
    '-I' => 'uppercase',
    '-R' => 'uppercase',
    '-N' => 'uppercase',
    '-j' => 'uppercase',
    '-s' => 'dns2ip',
    '-d' => 'dns2ip',
    '--comment' => 'quote_string',
);

sub quote_string {
    my ($self, $text) = @_;
    $text =~ s/^\s+|\s+$//g; # Strip leading and trailing whitespace
    if ($text =~ /\s/) {
        # Only quote if string still contains whitespace
        $text = "\"$text\"";
    }
    return $text;
}

# dns2ip () Translate host name to ip address.
#
# SYNOPSYS: $ip dns2ip ( $name )
#    INPUT: $name     - host name to translate;
#   OUTPUT: $ip       - ip address.
sub dns2ip {
    my ($self, $name) = @_;
    my ($hostname, $alias, $addrtype, $length, $addr);
    my @addr;
    my $isneg = 0;

    if (!defined $name || $name eq "") {
        $self->debug(2, "dns2ip-BAD: empty name");
        return '';
    };

    if ($name =~ /^!\s*(.*)/) {
        $self->debug(3, "dns2ip-INFO: negative specification");
        $isneg = 1;
        $name = $1;
    }

    if ($name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2}){0,1}$|\/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) { # optional netmask or CIDR postfix
        $self->debug(2, "dns2ip-OK: already numeric");
        if ($isneg) {
            return "! ".$name;
        } else {
            return $name;
        }
    }

    ($hostname, $alias, $addrtype, $length, $addr) = gethostbyname($name);

    if (!$hostname || $length != 4 || $addr eq "") {
        # no longer insist that the hostname in the config is canonical,
        # i.e. perfectly matches the DNS result
        $self->debug(2, "dns2ip-BAD: failed or weird gethostbyname");
        return '';
    }

    @addr = unpack ('C4', $addr);
    if (scalar(@addr) != 4) {
        $self->debug(2, "dns2ip-BAD: weird address format/length?");
        return '';
    };

    $name = "@addr";
    $name =~ s/\s/\./g;
    $self->debug(2, "dns2ip-OK: resolved $name");

    if ($isneg) {
        return "! ".$name;
    } else {
        return $name;
    }
}

# uppercase() Transform all lowercase text to uppercase.
#
# SYNOPSYS: $text uppercase ( $text )
#    INPUT: $text     - text to transform;
#   OUTPUT: $text     - text in uppercase.
sub uppercase {
    my ($self, $text) = @_;
    return '' if (!defined $text);
    $text =~ tr/a-z/A-Z/;
    return $text;
}

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
sub GetPathEntries {
    my ($self, $path, $config) = @_;
    my ($content, $entry, $name, $value);
    my $entries = {};

    $self->debug(5, "Entering method GetPathEntries");

    # Check the input parameters.
    if (!defined $path || $path   eq "") {
        $? = 1;
        $@ = "resource path to query empty";
        return $entries;
    }
    if (!defined $config || $config eq "") {
        $? = 3;
        $@ = "missing configuration object when getting resource path \"$path\"";
        return $entries;
    }

    # Check if the resource path $path exist.
    if (!$config->elementExists($path)) {
        $? = 5;
        $@ = "resource path \"$path\" not found";
        return $entries;
    }

    # Get the perl object representing the resource path content.
    $content = $config->getElement($path);
    unless (defined $content) {
        $? = 6;
        $@ = "cannot get resource path \"$path\"";
        return $entries;
    }

    while ($content->hasNextElement()) {
        $entry = $content->getNextElement();
        $name = $entry->getName();
        $value = $entry->getValue();
        if ( $entry->getType() == 33 ) {
            # Type 33 is boolean
            # Boolean options are handled by this code as seperate options (e.g. syn/nosyn) with empty values which is just horrible
            $value = ''
        }
        $value =~ s/^\s*|\s*$//g;
        $value =~ s/\s+/ /g;

        #this is a fix for the issue of values with the "command" key
        #no translation => iptables screwing up
        if ($name eq "command") {
            $value = $OPTION_MAPPINGS{$value} if defined $OPTION_MAPPINGS{$value};
        }

        $entries->{$name} = $value;
    }

    $? = 0;
    $@ = "resource path \"$path\" ok";
    return $entries;
}

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
sub GetResource {
    my ($self, $path, $config) = @_;
    my ($entries, $table, $target, $rule, $name, $command, $key, $aux, $i);
    my $target_exists = 0;

    $self->debug(5, "Entering method GetResource");

    $entries = $self->GetPathEntries( $path, $config );
    return $entries if $?;

    foreach $table (keys %iptables_totality) {
        next if (!defined $entries->{$table});

        #define the regular expressions for -N, -A etc based on the specific targets for table
        my $tmp = $self->uppercase($self->regExp(@{$iptables_totality{$table}{chains}}));
        $OPTION_VALIDATORS{$_} = $tmp foreach (@{$iptables_totality{$table}{commands}});
        $OPTION_VALIDATORS{'-j'} = $self->uppercase($self->regExp(@{$iptables_totality{$table}{targets}}));

        $entries->{$table} = $self->GetPathEntries("$path/$table", $config);
        next if $?;

        $entries->{$table}->{preamble} = $self->GetPathEntries("$path/$table/preamble", $config);

        my $cnt = {};
        foreach $target (@{$iptables_totality{$table}{targets}}) {
            $cnt->{$target} = 0;
        }

        $entries->{$table}->{rules} = $self->GetPathEntries("$path/$table/rules", $config);
        next if $?;

        RULE: foreach $name (sort { $a <=> $b } keys %{$entries->{$table}->{rules}}) {
            next if ($name !~ /^\d+$/);
            $rule = $self->GetPathEntries( "$path/$table/rules/$name", $config );
            return if $?;
            $self->rule_options_translate($rule);

            if (!defined $rule->{chain}) {
                $? = 7;
                $@ = "missed chain entry on rule \"$path/$table/rules/$name\"";
                return {};
            }

            if (defined $rule->{-j}) {
                #check if exists
                if ($self->uppercase($rule->{-j}) !~ /$OPTION_VALIDATORS{'-j'}/) {
                    $iptables_totality{$table}{user_targets}{$self->uppercase($rule->{-j})} = 1;
                }
            }

            $rule->{command}=$iptables_totality{$table}{commands}[0] if(!defined $rule->{command} || $rule->{command} eq "");
            $rule->{$rule->{command}} = $rule->{chain};
            delete $rule->{command};
            delete $rule->{chain};

            my $val = $self->regExp(@{$iptables_totality{$table}{commands}});

            foreach $key (keys %{$rule}) {
                if (defined $OPTION_MODIFIERS{$key} && $OPTION_MODIFIERS{$key} ne "") {
                    my $opresult;
                    my $modifier = $OPTION_MODIFIERS{$key};
                    $opresult = $self->$modifier($rule->{$key});
                    if (!$opresult) {
                        $self->warn("failed to convert $key : ".$rule->{$key}." - IGNORING THIS RULE");
                        next RULE;
                    } else {
                        $self->debug(2, "converted $key : ".$rule->{$key}." to $opresult");
                        $rule->{$key} = $opresult;
                    }
                }

                if (defined $OPTION_VALIDATORS{$key} && $OPTION_VALIDATORS{$key} ne "") {
                    $aux = $OPTION_VALIDATORS{$key};
                    if ($rule->{$key} !~ /^$aux$/ && $key =~ /^$val$/) {
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


            if (defined $entries->{$table}->{ordered_rules} && $entries->{$table}->{ordered_rules} eq "yes") {
                $target = "ordered";
            }

            if ( defined $cnt->{$target} ) {
                next if (!$self->find_rule($rule,$entries->{$table}->{rules}->{$target}->{$cnt->{$target}}));
                $entries->{$table}->{rules}->{$target}->{$cnt->{$target}} = $rule;
                $cnt->{$target}++;
            }
        }
    }

    $? = 0;
    $@ = "get all resource path \"$path\" entries";
    return $entries;
}

# sort_keys() Give a rule keys in the right order to print to the
#             iptables configuration file.
#
# SYNOPSYS: @keys sort_keys ( $rule )
#    INPUT: $rule     - pointer to an hash table describing the rule;
#   OUTPUT: @keys     - list of keys in the right order,
#           $?        - 0 keys sorted,
#                     - 1 error.
#      USE: %OPTION_SORT_ORDER
#   ASSUME: If rule is not empty then is well formed.
sub sort_keys {
    my ($self, $rule) = @_;
    my ($i, $m, $purge, $swap, $reg);
    my (@keys, @ord);

    $self->debug(5, "Entering method sort_keys");

    # Check parameters.
    if ($rule !~ /^HASH/) {
        $? = 1;
        $@ = "bad rule";
        return ();
    }

    @keys = keys %{$rule};

    $purge = 1;
    WHILE: while($purge) {
        FOR: for($i=0, $purge=0; $i<=$#keys; $i++) {
            next if ($keys[$i] !~ /^(err|checked)$/);
            splice(@keys,$i,1);
            $purge = 1;
            last FOR;
        }
    }

    $swap = 1;
    while ($swap) {
        for($m=0, $swap=0; $m<$#keys; $m++) {
            for($i=$m+1; $i<=$#keys; $i++) {
                $self->error("$keys[$i] is not a valid option\n") if ! exists $OPTION_SORT_ORDER{$keys[$i]};
                $self->error("$keys[$m] is not a valid option\n") if ! exists $OPTION_SORT_ORDER{$keys[$m]};

                #next
                if (!exists $OPTION_SORT_ORDER{$keys[$i]} || !exists $OPTION_SORT_ORDER{$keys[$m]}) {
                    $? = 1;
                    $@ = "keys unsorted";
                    return @keys;
                }
                next if ($OPTION_SORT_ORDER{$keys[$i]} >= $OPTION_SORT_ORDER{$keys[$m]});
                $reg = $keys[$i];
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

# rule_options_translate() Translate the template options type to iptables
#                          options style.
#
# SYNOPSYS: $? rule_options_translate ( $rule )
#    INPUT: $rule     - pointer to an hash table describing the rule;
#   OUTPUT: $?        - 0 options translated,
#                     - 1 error.
#      USE: %OPTION_MAPPINGS
#   ASSUME: If rule is not empty then is well formed.
sub rule_options_translate {
    my ($self, $rule) = @_;
    my $key;

    $self->debug(5, "Entering method rule_options_translate");

    # Check parameters.
    if ($rule !~ /^HASH/) {
        $? = 1;
        $@ = "bad rule";
        return $?;
    }

    foreach $key (keys %{$rule}) {
        next if (! defined $OPTION_MAPPINGS{$key} || $OPTION_MAPPINGS{$key} eq "");
        next if (defined $rule->{$OPTION_MAPPINGS{$key}});
        $rule->{$OPTION_MAPPINGS{$key}} = $rule->{$key};
        delete $rule->{$key};
    }

    $? = 0;
    $@ = "options translated";

    return $?;
}

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
sub WriteFile {
    my ($self, $filename, $iptables) = @_;
    my ($table, $chain, $target, $rule, $name, $field, $line);
    my (@names);

    $self->debug(5, "Entering method WriteFile");

    # Check input parameters.
    if (!defined $filename || $filename eq "") {
        $? = 1;
        $@ = 'filename to write missing';
        return $?;
    }

    # Open the file.
    unless (open(FILE, ">$filename")) {
        $? = 6;
        $@ = "cannot open $filename";
        return $?;
    }
    # write our "tag" into it. Assist some poor admin in debugging..
    print FILE "# Firewall configuration written by ncm-iptables\n";
    print FILE "# Manual modifications will be overwritten on the next NCM run.\n";
    $self->debug(5, "Wrote header tag to file");

    # Write new content to file.
    if ( defined $iptables && ref($iptables) =~ /^HASH/ ) {
        $self->debug(5, "iterating over tables");
        foreach $table (keys %iptables_totality) {
            $self->debug(5, "processing table $table");
            next if (!defined $iptables->{$table} || $iptables->{$table} eq "" || ref($iptables->{$table}) !~ /^HASH/);
            print FILE "*$table\n";

            if (defined $iptables->{$table}->{preamble} && ref($iptables->{$table}->{preamble}) =~ /^HASH/ ) {
                my $preamble = $iptables->{$table}->{preamble};
                $self->debug(5, "table has preamble $preamble");

                foreach $chain (@{$iptables_totality{$table}{chains}}) {
                    $self->debug(5, "processing chain $chain");
                    next if (!defined $preamble->{$chain} || $preamble->{$chain} eq "");
                    my $g = $chain;
                    $g =~ tr/a-z/A-Z/;
                    $preamble->{$chain} =~ s/^[\s\t]*|[\s\t]*$//g;
                    $preamble->{$chain} =~ s/[\s\t+]/ /g;
                    print FILE ":$g $preamble->{$chain}\n";
                }
            }

            foreach $target (sort keys %{$iptables_totality{$table}{user_targets}}){
                $self->debug(5, "defining target $target");
                print FILE "-N $target\n";
            }

            foreach $target (@{$iptables_totality{$table}{targets}}) {
                $self->debug(5, "processing rules for target $target");
                next if ( ! defined $iptables->{$table}->{rules}->{$target}         );
                next if (   ref($iptables->{$table}->{rules}->{$target}) !~ /^HASH/ );
                next if ( ! scalar(%{$iptables->{$table}->{rules}->{$target}})      );

                foreach $name (sort { $a <=> $b; } keys %{$iptables->{$table}->{rules}->{$target}}) {
                    $self->debug(5, "processing rule $name for target $target");
                    next if ($name !~ /^\d+$/);
                    $rule = $iptables->{$table}->{rules}->{$target}->{$name};
                    $line = '';
                    foreach $field ($self->sort_keys($rule)) {
                        $line .= ($line) ? " $field" : $field;
                        $line .= " $rule->{$field}" if $OPTION_VALIDATORS{$field};
                    }
                    print FILE "$line\n" if $line and $line !~ /^-N/;
                }
            }
            print FILE "$iptables->{$table}->{epilogue}\n" if (defined $iptables->{$table}->{epilogue} && $iptables->{$table}->{epilogue} ne "");
        }
    }

    # Close the temporary file.
    unless (close(FILE)) {
        $? = 7;
        $@ = "cannot close $filename";
        return $?;
    }

    $? = 0;
    $@ = "modified $filename";
    return $?;
}

# cmp_rules() Compare two iptables rules.
#
# SYNOPSYS: $? cmp_rules ( $rule1, $rule2 )
#    INPUT: $rule1    - pointer to an hash table describing the one rule,
#           $rule2    - pointer to an hash table describing the other rule;
#   OUTPUT: $?        - 0 the rules are equal,
#                     - 1 one, or the two rules, is empty or is not an
#                         hash tables, or the rules are different.
sub cmp_rules {
    my ($self, $rule1, $rule2) = @_;
    my ($field);
    my (@fields1, @fields2);

    $self->debug(5, "Entering method cmp_rules");

    # Check parameters.
    if (!defined $rule1 || ref($rule1) !~ /^HASH/) {
        $? = 1;
        $@ = "first rule is not an hash table";
        return $?;
    }
    if (!defined $rule2 || ref($rule2) !~ /^HASH/) {
        $? = 1;
        $@ = "second rule is not an hash table";
        return $?;
    }

    $? = 1;
    $@ = "rule is not in the list";

    @fields1 = keys %{$rule1};
    @fields2 = keys %{$rule2};

    return $? if (scalar(@fields1) <= 0 && scalar(@fields2) >  0);
    return $? if (scalar(@fields1) >  0 && scalar(@fields2) <= 0);

    if (scalar(@fields1) <= 0 && scalar(@fields2) <=  0) {
        $? = 0;
        $@ = "rules are equal";
        return $?;
    }
    return $? if (scalar(@fields1) != scalar(@fields2));

    foreach $field (@fields1) {
        return $? if (!defined $rule2->{$field} || $rule1->{$field} ne "$rule2->{$field}");
    }

    $? = 0;
    $@ = "rule found in the list";
    return $?;
}

# find_rule() Find a rule in a list of rules.
#
# SYNOPSYS: $? find_rule ( $rule1, $hash )
#    INPUT: $rule     - pointer to an hash table describing the rule to find,
#           $hash     - hash list of rules to search on, the hash tables
#                       are on the forma (0,hash), (1,hash), ...;
#   OUTPUT: $?        - 0 the rules was found,
#                     - 1 the rule was not found.
sub find_rule {
    my ($self, $rule, $hash) = @_;
    my ($name);

    $self->debug(5, "Entering method find_rule");

    # Check parameters.
    if (!defined $rule || ref($rule) !~ /^HASH/) {
        $? = 1;
        $@ = "rule is not an hash table";
        return $?;
    }
    if (!defined $hash || ref($hash) !~ /^HASH/) {
        $? = 1;
        $@ = "hash list is not an HASH table";
        return $?;
    }
    if (!scalar(%{$hash})) {
        $? = 1;
        $@ = "hash list empty";
    }

    foreach $name (keys %{$hash}) {
        next if ($name !~ /^\d+$/);
        next if (ref($hash->{$name}) !~ /^HASH/);

        if (!$self->cmp_rules($rule, $hash->{$name}) && ! $?) {
            $@ = "rule found on the list";
            return $?
        }
    }

    $? = 1;
    $@ = "rule is not on the list";
    return $?;
}

sub Configure {
    my ($self, $config) = @_;
    my $iptables;
    local $@;

    $self->debug(5, "Entering method Configure");

    # Get global components parameters
    $iptables = $self->GetResource($path_iptables, $config);
    $self->error($@) and return 1 if $?;

    # Create tmpdir if necessary
    my ($iptc_temp_fh, $iptc_temp);
    eval {
        ($iptc_temp_fh, $iptc_temp) = tempfile("ncm-iptables-XXXXX");
    };
    $self->error("failed to create temporary iptables file: $@") and return 1 if $@;

    $self->WriteFile($iptc_temp, $iptables);
    if ($? > 0) {
        # bad - bail out
        $self->error($@);
        return 1;
    }
    $self->debug(1,$@);

    my $changes = 0;
    $changes = LC::Check::file(
        $CONFIG_IPTABLES,
        owner => 'root',
        group => 'root',
        mode => '0444',
        source => "$iptc_temp",
    );
    if ($changes) {
        # Reload the service - file changed
        if ($NoAction) {
            $self->info("Would run \"/sbin/service iptables condrestart\"");
        } else {
            # allow no "dangling" file descriptors, this may be executing in a restricted targeted SELinux context
            my $ip_stdouterr;
            if (LC::Process::execute([qw(/sbin/service iptables condrestart)], "stdout" => \$ip_stdouterr, "stderr" => "stdout")) {
                $self->info("ran \"/sbin/service iptables condrestart\"");
                if($ip_stdouterr) {
                    $self->info($ip_stdouterr);
                }
            } else {
                $self->error("command \"/sbin/service iptables condrestart\" failed:\n$ip_stdouterr");
            }
        }
    } else {
        $self->info("No change for $CONFIG_IPTABLES, not restarting service");
    }
    return;
}

1; # Required for PERL modules
