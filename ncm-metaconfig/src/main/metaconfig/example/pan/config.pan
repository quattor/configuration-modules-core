unique template metaconfig/example/config;

include 'metaconfig/example/schema';

bind "/software/components/metaconfig/services/{/etc/example/exampled.conf}/contents" = example_service;

prefix "/software/components/metaconfig/services/{/etc/example/exampled.conf}";
"daemon" = "exampled";
"module" = "example/main";