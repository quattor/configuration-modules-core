@{ Template for testing DNS client configuration by ncm-named }

object template client;

prefix '/software/components/named';

'active' = true;
'dependencies/pre/0' = 'spma';
'dispatch' = true;
'servers/0' = '134.158.88.149';
'servers/1' = '134.158.88.147';
'use_localhost' = true;
'version' = '14.6.0';
'options/0' = 'timeout:2';
'options/1' = 'debug';
