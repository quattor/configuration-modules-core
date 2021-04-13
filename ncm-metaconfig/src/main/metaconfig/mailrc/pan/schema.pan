declaration template metaconfig/mailrc/schema;

include 'pan/types';

type mailrc_element = {
    'smtp' ? string
    'from' ? type_email
    'smtp-use-starttls' ? boolean
    'smtp-auth-user' ? string
    'smtp-auth-password' ? string
    'nss-config-dir' ? string
    'ssl-verify' ? choice("ask", "ignore", "strict", "warn")
};

type mailrc_config = {
    include mailrc_element
    'account' ? mailrc_element{}
};
