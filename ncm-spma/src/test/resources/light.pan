object template light;

"/" = value("simple:/");
prefix "/software/components";
"pre1" = dict();
"pre2" = dict();

prefix "/software/components/accounts";
"dependencies/pre" = list("pre1", "spma", "pre2");

variable SPMALIGHT_FILTERS = list("a", "b");
include 'components/spma/light';
