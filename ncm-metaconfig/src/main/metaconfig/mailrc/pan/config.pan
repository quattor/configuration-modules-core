unique template metaconfig/mailrc/config;

include 'metaconfig/mailrc/schema';

bind "/software/components/metaconfig/services/{/etc/mail.rc}/contents" = mailrc_config;
prefix "/software/components/metaconfig/services/{/etc/mail.rc}";
"module" = "mailrc/main";
