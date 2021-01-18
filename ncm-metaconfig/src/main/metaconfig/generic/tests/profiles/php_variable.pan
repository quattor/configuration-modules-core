object template php_variable;

prefix "/software/components/metaconfig/services/{/a/b/c}";

"mode" = 0644;
"owner" = "root";
"group" = "root";
"convert/unescapekey" = true;
"module" = "generic/php_variable";

prefix "contents/{variable1['some.value']}";
"emptylist" = list();
"emptydict" = dict();
"dictwithdigit" = dict(
    "DIGIT10", "abc",
    "DIGIT20", "def",
    "DIGIT50", "METACONFIG_PHP_CODE_some php code doing something"
    );
"null" = 'METACONFIG_PHP_NULL';
"dictlist" = dict(
    "abc", list('def', 'METACONFIG_PHP_NULL'),
    "def", list('ghi'),
    );
"listbool" = list(true, false);
"mixeddict" = dict(
    'METACONFIG_PHP_FIRSTELEMENT', 'whatisthis',
    'something', 'else',
    'METACONFIG_PHP_LASTELEMENT', 'howdoesitevenwork',
    );
