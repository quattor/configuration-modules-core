object template spank;

function pkg_repl = { null; };
include 'metaconfig/slurm/spank';
'/software/components/metaconfig/dependencies' = null;


prefix "/software/components/metaconfig/services/{/etc/slurm/plugstack.conf}/contents/plugins/0";
"plugin" = "/some/path";

prefix "/software/components/metaconfig/services/{/etc/slurm/plugstack.conf}/contents/plugins/1";
"plugin" = "/some/other/path";
"arguments" = dict(
    "woohoo", true,
    "hello", "world"
    );
"optional" = true;

prefix "/software/components/metaconfig/services/{/etc/slurm/plugstack.conf}/contents";
"includes/0/directory" = "/some/incl";
"includes/1/directory" = "/some/other/incl";
