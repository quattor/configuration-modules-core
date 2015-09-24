structure template struct/php_conf;

"global/directoryindex" = list("index.php");

"type/add" = list(
    nlist(
        "name", "text/html",
        "target", list(".php"),
    ),
);

"handler/add" = list(
    nlist(
        "name", "php5-script",
        "target", list(".php"),
    ),
);

"ifmodules" = list(
    nlist(
        "name", "prefork.c",
        "modules", list(nlist(
            "name", "php5_module", 
            "path", "modules/libphp5.so",
            )),
        ),
    nlist(
        "name", "worker.c",
        "modules", list(nlist(
            "name", "php5_module", 
            "path", "modules/libphp5-zts.so",
            )),
        ),
);
