object template element;

include 'components/metaconfig/schema';

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
"element/TRUEFALSE" = true;
"element/singlequote" = true;
