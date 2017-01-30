unique template actions;

prefix "/software/components/metaconfig/services/{/foo/bar}";

"mode" = 0644;
"owner" = 'root';
"group" = 'root';
"module" = "json";
"contents" = dict("foo", "bar");

prefix "/software/components/metaconfig/services/{/foo/bar2}";

"mode" = 0644;
"owner" = 'root';
"group" = 'root';
"module" = "json";
"contents" = dict("foo", "bar");
