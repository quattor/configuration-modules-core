object template commands_fail_pre;

include 'simple_commands';

"/software/components/metaconfig/commands/cmd_pre_fail" =
    "-" + value("/software/components/metaconfig/commands/cmd_pre");

"/software/components/metaconfig/services/{/foo/bar}/actions/pre" = "cmd_pre_fail";
