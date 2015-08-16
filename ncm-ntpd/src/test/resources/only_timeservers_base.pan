unique template only_timeservers_base;

function pkg_repl = {return(null);};
include 'components/ntpd/config';
"/software/components/ntpd/dependencies/pre" = null;

include 'base_servers';

include 'base_serverlist';
