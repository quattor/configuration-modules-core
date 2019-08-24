object template string;

include 'metaconfig/generic/schema';

# explicit bind with metaconfig_generic_string here so it is tested
bind "/software/components/metaconfig/services/{/a/b/c}/contents" = metaconfig_generic_string;

"/software/components/metaconfig/services/{/a/b/c}" = create('metaconfig/generic/string',
    "contents", "a very long string\nwith\nnarbitrarysomething\nno eol newline in value",
    );
