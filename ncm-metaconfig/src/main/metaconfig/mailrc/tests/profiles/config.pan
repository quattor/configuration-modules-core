object template config;

include 'metaconfig/mailrc/config';

"/metaconfig/module" = "mailrc/main";
prefix "/software/components/metaconfig/services/{/etc/mail.rc}/contents";
"smtp" = 'mailserver.example.com';
"from" = 'root@example.com';

