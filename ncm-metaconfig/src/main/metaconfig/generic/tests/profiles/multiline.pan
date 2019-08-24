object template multiline;

include 'metaconfig/generic/schema';

# explicit bind with metaconfig_generic_multiline here so it is tested
bind "/software/components/metaconfig/services/{/a/b/c}/contents" = metaconfig_generic_multiline;

"/software/components/metaconfig/services/{/a/b/c}" = create('metaconfig/generic/multiline',
    "contents", list("first", "second", "third"),
    );
