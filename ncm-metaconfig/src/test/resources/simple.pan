object template simple;

prefix "/software/components/metaconfig/services/{/foo/bar}";

"mode" = 0644;
"owner" = 'root';
"group" = 'root';
"module" = "json";
"daemons/foo" = "restart";
"contents" = dict("foo", "bar");
