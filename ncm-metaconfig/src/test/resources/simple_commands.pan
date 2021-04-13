unique template simple_commands;

include 'simple';

prefix "/software/components/metaconfig/commands";
"cmd_pre" = "/cmd pre";
"cmd_test" = "/cmd test";
"cmd_changed" = "/cmd changed";
"cmd_post" = "/cmd post";

prefix "/software/components/metaconfig/services/{/foo/bar}/actions";
"pre" = "cmd_pre";
"test" = "cmd_test";
"changed" = "cmd_changed";
"post" = "cmd_post";
