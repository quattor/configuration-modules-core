# ${license-info}
# ${developer-info}
# ${author-info}
#
# iptables - Setup the IPTABLES firewall.
#
package NCM::Component::iptables;

use strict;
use base qw(NCM::Component);
use vars qw(@ISA $EC);
our $EC=LC::Exception::Context->new->will_store_all;
use CAF::Process;
use CAF::FileWriter;
use Readonly;

$NCM::Component::iptables::NoActionSupported = 1;

# Global variables
Readonly::Scalar my $path_iptables => '/software/components/iptables';

Readonly::Scalar my $CONFIG_IPTABLES => '/etc/sysconfig/iptables';

# hash of tables, chains & targets
my %iptables_totality = (
    filter => {
        chains => ['input', 'output', 'forward'],
        targets => ['ordered', 'log', 'accept', 'reject', 'return', 'classify', 'ulog', 'drop'],
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

# Craft a regular expression from a list of options
# by joining the list with the alternative operator
sub regExp
{
    my ($self, $reg) = @_;
    $self->debug(5, 'regExp - called with ' . $reg);
    $reg = join('|', @$reg);
    $self->debug(5, 'regExp - made ' . $reg);
    return $reg;
}

# Define the correct order for iptables options sorted into
Readonly::Array my @OPTION_SORT_ORDER => (
    '-N',
    '-A',
    '-D',
    '-I',
    '-R',
    '-s',
    '-d',
    '-p',
    '--in-interface',
    '--out-interface',
    '--match',
    '--fragment',
    '! --fragment',
    '--set',
    '--sport',
    '--dport',
    '--dports',
    '--sports',
    '--pkt-type',
    '--state',
    '--ctstate',
    '--ttl',
    '--tos',
    '--sid-owner',
    '--limit',
    '--rcheck',
    '--remove',
    '--rdest',
    '--rsource',
    '--rttl',
    '--update',
    '--seconds',
    '--hitcount',
    '--name',
    '--uid-owner',
    '--syn',
    '! --syn',
    '--icmp-type',
    '--tcp-flags',
    '--tcp-option',
    '--length',
    '-j',
    '--log-prefix',
    '--log-tcp-sequence',
    '--reject-with',
    '--set-class',
    '--log-level',
    '--log-tcp-options',
    '--log-ip-options',
    '--log-uid',
    '--limit-burst',
    '--to-destination',
    '--to-source',
    '--to-ports',
    '--comment',
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

# Trim leading and trailing whitespace from a string
sub trim_whitespace
{
    my ($self, $text) = @_;
    $text =~ s/^\s+|\s+$//g;
    return defined $text ? $text : '';
}

# Collapse repeated whitespace characters into single space characters
sub collapse_whitespace
{
    my ($self, $text) = @_;
    $text =~ s/\s+/ /g;
    return defined $text ? $text : '';
}

# Wrap strings containing whitespace in quotation marks
sub quote_string
{
    my ($self, $text) = @_;
    $text = $self->trim_whitespace($text);
    if ($text =~ /\s/) {
        $text = "\"$text\"";
    }
    return $text;
}

# dns2ip () Translate host name to ip address.
#
# SYNOPSYS: $ip dns2ip ( $name )
#    INPUT: $name     - host name to translate;
#   OUTPUT: $ip       - ip address.
sub dns2ip
{
    my ($self, $name) = @_;

    if (!$name) {
        $self->debug(2, "dns2ip-BAD: empty name");
        return '';
    };

    my $isneg = 0;
    if ($name =~ /^!\s*(.*)/) {
        $self->debug(3, "dns2ip-INFO: negative specification");
        $isneg = 1;
        $name = $1;
    }

    if ($name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2}){0,1}$|\/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) { # optional netmask or CIDR postfix
        $self->debug(2, "dns2ip-OK: already numeric");
        return ($isneg ? '! ' : '').$name;
    }

    my ($hostname, $alias, $addrtype, $length, $addr) = gethostbyname($name);

    if (!$hostname || $length != 4 || $addr eq "") {
        # no longer insist that the hostname in the config is canonical,
        # i.e. perfectly matches the DNS result
        $self->debug(2, "dns2ip-BAD: failed or weird gethostbyname");
        return '';
    }

    my @addr = unpack ('C4', $addr);
    if (scalar(@addr) != 4) {
        $self->debug(2, "dns2ip-BAD: weird address format/length?");
        return '';
    };

    $name = join('.', @addr);
    $self->debug(2, "dns2ip-OK: resolved $name");
    return ($isneg ? '! ' : '').$name;
}

# uppercase() Transform all lowercase text to uppercase.
#
# SYNOPSYS: $text uppercase ( $text )
#    INPUT: $text     - text to transform;
#   OUTPUT: $text     - text in uppercase.
sub uppercase
{
    my ($self, $text) = @_;
    return defined $text ? uc($text) : '';
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
sub GetPathEntries
{
    my ($self, $path, $config) = @_;
    my $entries = {};

    $self->debug(5, "Entering method GetPathEntries");

    # Check the input parameters.
    if (!$path) {
        $? = 1;
        $@ = "resource path to query empty";
        return $entries;
    }
    if (!$config) {
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
    my $content = $config->getElement($path);
    unless (defined $content) {
        $? = 6;
        $@ = "cannot get resource path \"$path\"";
        return $entries;
    }

    while ($content->hasNextElement()) {
        my $entry = $content->getNextElement();
        my $name = $entry->getName();
        my $value = $entry->getValue();
        if ( $entry->getType() == 33 ) {
            # Type 33 is boolean
            # Boolean options are handled by this code as seperate options (e.g. syn/nosyn) with empty values which is just horrible
            $value = ''
        }
        $value = $self->trim_whitespace($value);
        $value = $self->collapse_whitespace($value);

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
sub GetResource
{
    my ($self, $path, $config) = @_;

    $self->debug(5, "Entering method GetResource");

    my $entries = $self->GetPathEntries( $path, $config );
    return $entries if $?;

    foreach my $table (keys %iptables_totality) {
        next if (!defined $entries->{$table});

        #define the regular expressions for -N, -A etc based on the specific targets for table
        my $tmp = $self->uppercase($self->regExp(\@{$iptables_totality{$table}{chains}}));
        $OPTION_VALIDATORS{$_} = $tmp foreach (@{$iptables_totality{$table}{commands}});
        $OPTION_VALIDATORS{'-j'} = $self->uppercase($self->regExp(\@{$iptables_totality{$table}{targets}}));

        $entries->{$table} = $self->GetPathEntries("$path/$table", $config);
        next if $?;

        $entries->{$table}->{preamble} = $self->GetPathEntries("$path/$table/preamble", $config);

        my $cnt = {};
        foreach my $target (@{$iptables_totality{$table}{targets}}) {
            $cnt->{$target} = 0;
        }

        $entries->{$table}->{rules} = $self->GetPathEntries("$path/$table/rules", $config);
        next if $?;

        RULE: foreach my $name (sort { $a <=> $b } keys %{$entries->{$table}->{rules}}) {
            next if ($name !~ /^\d+$/);
            my $rule = $self->GetPathEntries( "$path/$table/rules/$name", $config );
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
                    $self->debug(5, 'Defined "' . $rule->{-j} . '" as a user target');
                }
            }

            $rule->{command} = $iptables_totality{$table}{commands}[0] if(!$rule->{command});
            $rule->{$rule->{command}} = $rule->{chain};
            delete $rule->{command};
            delete $rule->{chain};

            my $val = $self->regExp(\@{$iptables_totality{$table}{commands}});

            foreach my $key (keys %{$rule}) {
                if ($OPTION_MODIFIERS{$key}) {
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

                if ($OPTION_VALIDATORS{$key}) {
                    my $aux = $OPTION_VALIDATORS{$key};
                    if ($rule->{$key} !~ /^$aux$/ && $key =~ /^$val$/) {
                        my $skip = 0;
                        foreach my $target (@{$iptables_totality{$table}{targets}}) {
                            $skip = 1 if $target eq $rule->{$key};
                        }
                        next if $skip;
                        push(@{$iptables_totality{$table}{targets}}, $rule->{$key});
                        $iptables_totality{$table}{user_targets}{$rule->{$key}} = 1;
                    }
                }
            }

            my $target;
            if (defined $rule->{'-j'}) {
                $target = lc($rule->{'-j'});
            }

            if (defined $entries->{$table}->{ordered_rules} && $entries->{$table}->{ordered_rules} eq "yes") {
                $target = "ordered";
            }

            if (defined $cnt->{$target}) {
                next if (!$self->find_rule($rule, $entries->{$table}->{rules}->{$target}->{$cnt->{$target}}));
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
sub sort_keys
{
    my ($self, $rule) = @_;

    $self->debug(5, "Entering method sort_keys");

    # Check parameters.
    if ($rule !~ /^HASH/) {
        $self->error("Rule passed to sort_keys is not a hash");
        return ();
    }

    my @keys;
    foreach my $option (@OPTION_SORT_ORDER) {
        if (exists $rule->{$option}) {
            $self->debug(5, "Found $option in rule");
            push @keys, $option;
        }
    }

    $self->debug(5, "Finished sorting keys");
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
sub rule_options_translate
{
    my ($self, $rule) = @_;

    $self->debug(5, "Entering method rule_options_translate");

    # Check parameters.
    if ($rule !~ /^HASH/) {
        $? = 1;
        $@ = "bad rule";
        return $?;
    }

    foreach my $key (keys %{$rule}) {
        next if (!$OPTION_MAPPINGS{$key});
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
#           $iptables - hash of iptables rules;
#   OUTPUT: $?        - 0 Not changes to $filename,
#                     - > 0 $filename updated.
sub WriteFile
{
    my ($self, $filename, $iptables) = @_;

    $self->debug(5, "Entering method WriteFile");

    # Check input parameters.
    if (!$filename) {
        $self->error('No filename passed to WriteFile');
        return 0;
    }

    if (!$iptables) {
        $self->error("No iptables rules passed to WriteFile");
        return 0;
    }

    # Open the file.
    my $fh = CAF::FileWriter->open(
        $filename,
        owner => 'root',
        group => 'root',
        mode => '0444',
    );

    # write our "tag" into it. Assist some poor admin in debugging..
    print $fh "# Firewall configuration written by ncm-iptables\n";
    print $fh "# Manual modifications will be overwritten on the next NCM run.\n";
    $self->debug(5, "Wrote header tag to file");

    # Write new content to file.
    $self->debug(5, "iterating over tables");
    foreach my $table (keys %iptables_totality) {
        $self->debug(5, "processing table $table");
        next if (!$iptables->{$table} || ref($iptables->{$table}) !~ /^HASH/);
        print $fh "*$table\n";

        if (defined $iptables->{$table}->{preamble} && ref($iptables->{$table}->{preamble}) =~ /^HASH/ ) {
            my $preamble = $iptables->{$table}->{preamble};
            $self->debug(5, "table has preamble $preamble");

            foreach my $chain (@{$iptables_totality{$table}{chains}}) {
                $self->debug(5, "processing chain $chain");
                next if (!$preamble->{$chain});
                my $g = uc($chain);
                $preamble->{$chain} = $self->trim_whitespace($preamble->{$chain});
                $preamble->{$chain} = $self->collapse_whitespace($preamble->{$chain});
                print $fh ":$g $preamble->{$chain}\n";
            }
        }

        foreach my $target (sort keys %{$iptables_totality{$table}{user_targets}}){
            $self->debug(5, "defining target $target");
            print $fh "-N $target\n";
        }

        foreach my $target (@{$iptables_totality{$table}{targets}}) {
            $self->debug(5, "processing rules for target $target");
            next if (!defined $iptables->{$table}->{rules}->{$target});
            next if (ref($iptables->{$table}->{rules}->{$target}) !~ /^HASH/);
            next if (!scalar(%{$iptables->{$table}->{rules}->{$target}}));

            foreach my $name (sort { $a <=> $b; } keys %{$iptables->{$table}->{rules}->{$target}}) {
                $self->debug(5, "processing rule $name for target $target");
                next if ($name !~ /^\d+$/);
                my $rule = $iptables->{$table}->{rules}->{$target}->{$name};
                my $line = '';
                foreach my $field ($self->sort_keys($rule)) {
                    $line .= ($line) ? " $field" : $field;
                    $line .= " $rule->{$field}" if $OPTION_VALIDATORS{$field};
                }
                print $fh "$line\n" if $line and $line !~ /^-N/;
            }
        }
        print $fh "$iptables->{$table}->{epilogue}\n" if (defined $iptables->{$table}->{epilogue} && $iptables->{$table}->{epilogue} ne "");
    }

    return $fh->close();
}

# cmp_rules() Compare two iptables rules.
#
# SYNOPSYS: $? cmp_rules ( $rule1, $rule2 )
#    INPUT: $rule1    - pointer to an hash table describing the one rule,
#           $rule2    - pointer to an hash table describing the other rule;
#   OUTPUT: $?        - 0 the rules are equal,
#                     - 1 one, or the two rules, is empty or is not an
#                         hash tables, or the rules are different.
sub cmp_rules
{
    my ($self, $rule1, $rule2) = @_;

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

    my @fields1 = keys %{$rule1};
    my @fields2 = keys %{$rule2};

    return $? if (scalar(@fields1) <= 0 && scalar(@fields2) >  0);
    return $? if (scalar(@fields1) >  0 && scalar(@fields2) <= 0);

    if (scalar(@fields1) <= 0 && scalar(@fields2) <=  0) {
        $? = 0;
        $@ = "rules are equal";
        return $?;
    }
    return $? if (scalar(@fields1) != scalar(@fields2));

    foreach my $field (@fields1) {
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
sub find_rule
{
    my ($self, $rule, $hash) = @_;

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

    foreach my $name (keys %{$hash}) {
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

sub Configure
{
    my ($self, $config) = @_;
    local $@;

    $self->debug(5, "Entering method Configure");

    # Get global components parameters
    my $iptables = $self->GetResource($path_iptables, $config);
    $self->error($@) and return 1 if $?;

    my $changes = $self->WriteFile($CONFIG_IPTABLES, $iptables);
    $self->debug(5, "WriteFile returned $changes");
    if ($changes) {
        my $proc = CAF::Process->new([qw(/sbin/service iptables condrestart)], log=> $self);
        my $ip_stdouterr = $proc->output();
        if ($?) {
            $self->error("command \"$proc\" failed:\n$ip_stdouterr");
        } else {
            $self->info("ran command \"$proc\"", $ip_stdouterr ? $ip_stdouterr : '');
        }
    } else {
        $self->info("No change for $CONFIG_IPTABLES, not restarting service");
    }
    return;
}

1; # Required for PERL modules
