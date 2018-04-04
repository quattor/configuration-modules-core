object template account_config;

include 'metaconfig/mailrc/config';

"/metaconfig/module" = "mailrc/main";
prefix "/software/components/metaconfig/services/{/etc/mail.rc}/contents/account/gmail";
"smtp" = 'mailserver.gmail.com';
"from" = 'root@gmail.com';
