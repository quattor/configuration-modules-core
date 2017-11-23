unique template base;

function pkg_repl = { null; };
include 'components/pcs/config';
"/software/components/pcs/dependencies/pre" = null;

prefix "/software/components/pcs/cluster";
"name" = "simple";
"nodes" = list("nodea", "nodeb");
