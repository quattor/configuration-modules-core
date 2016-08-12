object template download;

# mock pkg_repl
function pkg_repl = { null; };

include 'components/download/config';

# remove the dependencies
'/software/components/download/dependencies' = null;


prefix "/software/components/download";
"server" = "default.server";
"proto" = "https";
"proxyhosts" = list('broken', 'working');

prefix "/software/components/download/files";
"{/a/b/c}" = dict(
    "proxy", true,
    "href" ,"something",
    );
"{/a/b/d}" = dict(
    "proxy", true,
    "href" ,"abc://ok/something/else",
    );
"{/a/b/e}" = dict(
    "proxy", false,
    "href" ,"def://ok/something/entirely/different",
    "post", "postprocess",
    );
