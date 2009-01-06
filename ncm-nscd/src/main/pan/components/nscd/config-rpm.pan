# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/nscd/config-rpm;

include components/nscd/schema;

"/software/components/nscd/paranoia" ?= 'yes';
"/software/components/nscd/hosts/positive-time-to-live" ?= 300;
"/software/components/nscd/active" ?= true;
"/software/components/nscd/dispatch" ?= true;
"/software/packages" = pkg_repl ("ncm-nscd", "1.1.0-1", "noarch");
