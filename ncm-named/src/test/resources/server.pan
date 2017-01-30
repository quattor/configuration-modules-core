@{ Template for testing DNS server configuration by ncm-named }

object template server;

prefix '/software/components/named';

'active' = true;
'dependencies/pre/0' = 'spma';
'dispatch' = true;
'serverConfig' = <<EOF;
// testdata
Creature. Grass image cattle their. Hath, third itself won't lights likeness were divided. Brought Hath dry.
EOF
