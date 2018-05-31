# #
# Software subject to following license(s):
#   Apache 2 License (http://www.opensource.org/licenses/apache2.0)
#   Copyright (c) Responsible Organization
#

declaration template components/ssh/schema-7.4;

type ssh_authkeyscommand_options_type = {
    'AuthorizedKeysCommand' ? string(1..)
    'AuthorizedKeysCommandUser' ? string(1..)
} with {
    if (exists(SELF['AuthorizedKeysCommand']) != exists(SELF['AuthorizedKeysCommandUser'])) {
        error('Cannot set only one of AuthorizedKeysCommand and AuthorizedKeysCommandUser, set both or neither.');
    };
    true;
};
