object template basic;

prefix '/software/components/iptables/';

'filter/preamble/input' = 'DROP [0:0]'; # Drop all inbound packets
'filter/preamble/output' = 'ACCEPT [0:0]'; # Accept all outbound packets
'filter/preamble/forward' = 'DROP [0:0]'; # Never forward packets
'filter/epilogue' = 'COMMIT';

# Initialise (but do not overwrite existing) any rules list
'filter/rules' ?= list();

# Accept all connections from private address range
'filter/rules' = append(dict(
    'command', '-A',
    'chain', 'input',
    'source', '10.0.0.0/8',
    'jump', 'ACCEPT',
));

# Accept all incoming packets associated with an established connection
'filter/rules' = append(dict(
    'command', '-A',
    'chain', 'input',
    'match', 'state',
    'state', 'ESTABLISHED,RELATED',
    'jump', 'ACCEPT',
));

# Accept all incoming packets on loopback interface
'filter/rules' = append(dict(
    'command', '-A',
    'chain', 'input',
    'in_interface', 'lo',
    'jump', 'ACCEPT',
));
