template simple_links;

function pkg_repl = { null; };
include 'components/symlink/config';
'/software/components/symlink/dependencies' = null;

prefix "/software/components/symlink";
"links" = append(dict("name", "/link1", "target", "target1"));
"links" = append(dict("name", "/link2", "target", "target2"));

