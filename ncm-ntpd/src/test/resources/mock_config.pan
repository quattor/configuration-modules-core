unique template mock_config;

# mock pkg_repl
function pkg_repl = { null; };
include 'components/ntpd/config';
# delete spma dependency (requires configured spma component otherwise)
"/software/components/ntpd/dependencies" = null;
