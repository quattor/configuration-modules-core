structure template struct/php_conf;

"global/directoryindex" = list("index.php");

"type/add" = list(
    dict(
        "name", "text/html",
        "target", list(".php"),
    ),
);

"handler/add" = list(
    dict(
        "name", "php5-script",
        "target", list(".php"),
    ),
);

"ifmodules" = list(
    dict(
        "name", "prefork.c",
        "modules", list(dict(
            "name", "php5_module",
            "path", "modules/libphp5.so",
            )),
        ),
    dict(
        "name", "worker.c",
        "modules", list(dict(
            "name", "php5_module",
            "path", "modules/libphp5-zts.so",
            )),
        ),
);
