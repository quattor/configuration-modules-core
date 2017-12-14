object template simple;

function pkg_repl = { null; };
include 'components/nrpe/config';
"/software/components/nrpe/dependencies/pre" = null;

prefix "/software/components/nrpe";
"mode" = 0640;

"options/allowed_hosts/0" = "a";
"options/allowed_hosts/1" = "b";

"options/command/cmd" = "foobar";

"options/include/0" = "foo";
"options/include_dir/0" = "bar";
