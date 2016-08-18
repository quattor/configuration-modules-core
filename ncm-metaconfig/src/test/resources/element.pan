object template element;

function pkg_repl = {return(null);};
include 'components/metaconfig/config';
'/software/components/metaconfig/dependencies/pre' = null; # remove it to avoid mocking spma

prefix "/software/components/metaconfig/services/{/foo/bar}";
"mode" = 0644;
"owner" = 'root';
"group" = 'root';
"module" = "tiny";
"contents" = dict(
    "string", "mystring",
    "boolean", true,
);

"/software/components/metaconfig/services/{/foo/bar2}" = value("/software/components/metaconfig/services/{/foo/bar}");
prefix "/software/components/metaconfig/services/{/foo/bar2}";
"convert/TRUEFALSE" = true;
"convert/singlequote" = true;

"convert/joincomma" = true;
# string elements will be single-quoted before the join
"contents/list" = list("a","b");
