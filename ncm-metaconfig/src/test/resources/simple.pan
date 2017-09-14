object template simple;

function pkg_repl = { null; };
include 'components/metaconfig/config';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/foo/bar}";

"mode" = 0644;
"owner" = 'root';
"group" = 'root';
"module" = "json";
"daemons/foo" = "restart";
"contents" = dict("foo", "bar");
