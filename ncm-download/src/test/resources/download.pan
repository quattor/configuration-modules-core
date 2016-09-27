object template download;

# mock pkg_repl
function pkg_repl = { null; };

include 'components/download/config';

# remove the dependencies
'/software/components/download/dependencies' = null;


prefix "/software/components/download";
"server" = "default.server";
"proto" = "https";
"proxyhosts" = list('broken', 'working', 'working2');

prefix "/software/components/download/files";
"{/a/b/c1}" = dict(
    "proxy", true,
    "href" ,"something1",
    );
"{/a/b/c2}" = dict(
    "proxy", true,
    "href" ,"something2",
    );
"{/a/b/c3}" = dict(
    "proxy", true,
    "href" ,"something3",
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
