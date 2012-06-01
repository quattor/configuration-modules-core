object template simple;

prefix "/software/components/structured_config/services/{/foo/bar}";

"mode" = 0644;
"owner" = 'root';
"group" = 'root';
"module" = "json";
"daemon" = "foo";
"contents" = nlist("foo", "bar");