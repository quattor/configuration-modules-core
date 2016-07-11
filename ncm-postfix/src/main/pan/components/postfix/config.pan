# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/postfix/config;

include 'components/postfix/schema';

bind '/software/components/postfix' = postfix_component;

prefix '/software/components/postfix';
'active' ?= true;
'dispatch' ?= true;
'dependencies/pre' ?= list('spma');

'/software/packages' = pkg_repl('ncm-postfix','${no-snapshot-version}-${rpm.release}','noarch');
