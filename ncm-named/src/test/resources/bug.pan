@{ Template for testing a bug in which newlines are not appended after
the search line configuration by ncm-named @}

object template bug;

prefix '/software/components/named';

'active' = true;
'dependencies/pre/0' = 'spma';
'dispatch' = true;
'servers/0' = '4.3.2.1';
'search/0' = 'somewhere.org';
'search/1' = 'here.fr';
'use_localhost' = true;
'version' = '14.6.0';
