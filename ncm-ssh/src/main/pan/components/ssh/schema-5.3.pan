# #
# Software subject to following license(s):
#   Apache 2 License (http://www.opensource.org/licenses/apache2.0)
#   Copyright (c) Responsible Organization
#

declaration template components/ssh/schema-5.3;

type ssh_authkeyscommand_options_type = {
            "AuthorizedKeysCommand" ? string
            "AuthorizedKeysCommandRunAs" ? string
};
