---
layout: documentation
title: iptables
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

iptables: Setup the IPTABLES firewall rules.

### DESCRIPTION

The _IPTABLES_ component perform the setup of the
__/etc/sysconfig/iptables__ configuration file and restarts the
iptables service.

### SYNOPSIS

Note: a detailed HOWTO for this component, including examples, is
found in `/usr/share/doc/ncm`-iptables-2.3.13/ncm-iptables-howto.html and in the FIO twiki pages
at https://twiki.cern.ch/twiki/bin/view/FIOgroup/Iptables.

- Configure()

    This function apply the component resource declaration to the
    _IPTABLES_ firewall tables.

    The _accept_, _drop_, _reject_, _return_, _classify_ and _log_
    default targets are supported.

    User defined targets are supported. We recommend that users specify new
    targets as a rule in the profile but the system will create them if it
    needs to - N.B. This means that you need to spell targets names
    consistantly and with identical capitalisation otherwise you will end up
    with multiple chains E.g. chain "LocalRules" is not the same as
    "localrules".

    Duplicated entries in the component resource declaration are
    ignored. For each configured table, the chains are added to the
    __/etc/sysconfig/iptable__ in order, the relative order among the rules
    belonging to the same chain is preserved.

- Unconfigure()

    Not implemented.

### RESOURCES

#### `/software/components/iptables`

Top component description with the following parameters:

    "filter"   ? component_iptables_acls
    "nat"      ? component_iptables_acls
    "mangle"   ? component_iptables_acls

These parameters correspond to the three _IPTABLES_ table types.

#### type component\_iptables\_acls

The _component\_iptables\_acls_ type is defined as:

    "preamble"      ? component_iptables_preamble
    "rules"         ? component_iptables_rule[]
    "epilogue"      ? string
    "ordered_rules" ? string with match (self, 'yes|no')

The __"epilogue"__ parameter is the "COMMIT" command at the end of
_IPTABLES_ table description. Presently, no check is performed upon
the content of this parameter.

If "ordered\_rules" is set to yes, the ruleset will be written as
ordered in the original array. If set to no is is unset (the default),
the rules will be ordered by target type (first, all the "log"  rules,
then "accept","drop", and "logging").

#### type component\_iptables\_preamble

The _component\_iptables\_preamble_ type is defined as:

    "input"    ? string
    "output"   ? string
    "forward"  ? string

These parameters contain the global rules for stated rules,
e.g. ":INPUT ACCEPT \[0:0\]". Presently, no check is performed upon the
content of this parameters.

#### type component\_iptables\_rule

The _component\_iptables\_rule_ type is defined as:

    "command"       ? string
    "chain"         : string
    "protocol"      ? string
    "src_addr"      ? string
    "src_port"      ? string
    "src_ports"     ? string
    "dst_addr"      ? string
    "dst_port"      ? string
    "dst_ports"     ? string
    "syn"           ? boolean
    "nosyn"         ? boolean
    "match"         ? string
    "state"         ? string
    "ctstate"       ? string
    "limit"         ? string
    "icmp_type"     ? string
    "in_interface"  ? string
    "out_interface" ? string
    "fragment"      ? boolean
    "nofragment"  ? boolean
    "target"        : string
    "reject-with"       ? string
    "log-prefix"        ? string
    "log-level"         ? string
    "log-tcp-options"   ? boolean
    "log-tcp-sequence"  ? boolean
    "log-ip-options"    ? boolean
    "set-class"	    ? string
    "limit-burst"     ? number
    "length"          ? string
    "set"             ? boolean
    "rcheck"          ? boolean
    "seconds"         ? number

The __"command"__ define the action to perform: "-A", "-D", "-I", "-N" or
"-R", it defaults to "-A".

The __"chain"__ define the chain: "input", "output" or "forward".

The __"protocol"__ define the packet protocol: "tcp", "udp" or "icmp".

The __"src\_addr"__ define the packet source address, it can be an IP
address, or a network in the form net/mask (CIDR notation or full mask), or a
hostname (which will be resolved at configuration time, not at
runtime) - all of which can be optionally prepended with "!" to negate
the selection. To limit the ability of hackers/crackers to use your
system for DDoS attacks it is worthwhile, for machines which are not
being used as routers, to block packets which do not come from their
IP address in the OUTPUT tables.

The __"src\_port"__ define the packet source port, it may be an integer
or a service name included in the `/etc/services` file. This parameter
requires __"protocol"__ also be set.

The __"dst\_addr"__ define the packet destination address, it follow's the same
rules as the src\_addr parameter.

The __"dst\_port"__ define the packet destination port, it follow's the same
rules as the src\_port parameter. This parameter requires __"protocol"__ also be set.

The __"syn"__ define the TCP packet with the SYN bit set to one, it will be set
if the parameter is true.

The __"match"__ define the match extension module for the packet.

The __"state"__ define the connection state.

The __"limit"__ defines the limit for logging.

The __"limit-burst"__ defines the number of instances per time step to record.

The __"icmp\_type"__ define the icmp type packet.

The __"in\_interface"__ define the input interface for the packet.

The __"out\_interface"__ define the output interface for the packet.

The __"target"__ define the target for the packet: "log", "accept" or "drop".

#### function add\_rule(<table>, <rule>)

This function add a new entry rule to the resource list

    "/software/components/iptables/<table>/rules"

### DEPENDENCIES

- Pre-installation

    The iptables RPM package must be installed.

### FILES

#### `/etc/sysconfig/iptables`:

_IPTABLES_ firewall configuration file policy.

#### pro\_declaration\_component\_iptables.tpl:

Component declaration.

#### pro\_declaration\_functions\_iptables.tpl:

Component functions declaration.

### BUGS

Not all valid iptables options are implemented, and not all
implemented options are properly documented.
The component is overly strict in what it accepts, some legal combinations
may be rejected.

### SEE ALSO

See in particular the __ncm-iptables__ HOWTO as found in
`/usr/share/doc/ncm`-iptables-2.3.13/ncm-iptables-howto.html, which includes usage examples.

__iptables__ man page
