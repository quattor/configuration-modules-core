object template simple;

function pkg_repl = { null; };
include 'components/altlogrotate/config';
'/software/components/altlogrotate/dependencies' = null;

prefix '/software/components/altlogrotate/entries/test1';
"pattern" = "a/b/c/*-2???-??-??.log";
"compress" = true;
"missingok" = true;
"frequency" = "daily";
"ifempty" = true;
"rotate" = 1;
"nomail" = true;
"create" = true;
"createparams/mode" = '0751';
"createparams/owner" = 'someuser';
"createparams/group" = 'agroup';
"mailselect" = "first";
"scripts" = dict("lastaction", "/run/this");
"tabooext" = list('a', 'b');
"taboo_replace" = true;

prefix '/software/components/altlogrotate/entries/global';
"include" = "some_file";

prefix '/software/components/altlogrotate/entries/test2_global';
"pattern" = "something";
"global" = true;
"tabooext" = list('a', 'b');
"taboo_replace" = false;
"ifempty" = false;

prefix '/software/components/altlogrotate/entries/test3_overwrite_with_file';
"pattern" = "test3";
"compress" = true;
"overwrite" = true;

prefix '/software/components/altlogrotate/entries/test4_overwrite_no_file';
"pattern" = "test4";
"compress" = true;
"overwrite" = true;
