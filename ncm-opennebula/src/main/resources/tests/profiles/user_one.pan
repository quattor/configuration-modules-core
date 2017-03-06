object template user_one;

include 'components/opennebula/schema';

bind "/metaconfig/contents/user/lsimngar" = opennebula_user;

"/metaconfig/module" = "user";

prefix "/metaconfig/contents/user/lsimngar";
"password" =  "my_fancy_pass";
"ssh_public_key" = list(
    'ssh-dss AAAAB3NzaC1kc3MAAACBAOTAivURhU user@OptiPlex-790',
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ hello@mylaptop'
);
"group" = "oneadmin";
"labels" = list("quattor", "quattor/localuser");
