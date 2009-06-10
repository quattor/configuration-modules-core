# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/iscsitarget/config-rpm;

include components/iscsitarget/schema;

"/software/components/testcomp/foo" ?= 'quux';
"/software/components/testcomp/bar" ?= 1;
