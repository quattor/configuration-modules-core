object template actions_daemons;

include 'actions';

"/software/components/metaconfig/services/{/foo/bar}/daemons/test" = 'restart';
"/software/components/metaconfig/services/{/foo/bar2}/daemons/test" = 'reload';
