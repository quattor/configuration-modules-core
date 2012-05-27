object template simple;

prefix "/software/components/structured_config/services/{/foo/bar}";

"mode" = 0644;
"owner" = 'root';
"group" = 'root';
"module" = "JSON::XS";
"daemon" = "foo";
"contents" = nlist("foo", "bar");