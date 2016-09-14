object template sysconfig;

function pkg_repl = { null; };
include 'components/shorewall/sysconfig';
# remove the dependencies for metaconfig
'/software/components/metaconfig/dependencies' = null;
