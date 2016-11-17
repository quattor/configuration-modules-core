object template user_one;

include 'components/opennebula/schema';

bind "/metaconfig/contents/user/lsimngar" = opennebula_user;

"/metaconfig/module" = "user";

prefix "/metaconfig/contents/user/lsimngar";
"password" =  "my_fancy_pass";
"ssh_public_key" = list(
    'ssh-dss AAAAB3NzaC1kc3MAAACBAOTAivURhUrg2Zh3DqgVd2ofRYKmXKjWDM4LITQJ/Tr6RBWhufdxmJos/w0BG9jFbPWbUyPn1mbRFx9/2JJjaspJMACiNsQV5KD2a2H/yWVBxNkWVUwmq36JNh0Tvx+ts9Awus9MtJIxUeFdvT433DePqRXx9EtX9WCJ1vMyhwcFAAAAFQDcuA4clpwjiL9E/2CfmTKHPCAxIQAAAIEAnCQBn1/tCoEzI50oKFyF5Lvum/TPxh6BugbOKu18Okvwf6/zpsiUTWhpxaa40S4FLzHFopTklTHoG3JaYHuksdP4ZZl1mPPFhCTk0uFsqfEVlK9El9sQak9vXPIi7Tw/dyylmRSq+3p5cmurjXSI93bJIRv7X4pcZlIAvHWtNAYAAACBAOCkwou/wYp5polMTqkFLx7dnNHG4Je9UC8Oqxn2Gq3uu088AsXwaVD9t8tTzXP1FSUlG0zfDU3BX18Ds11p57GZtBSECAkqH1Q6vMUiWcoIwj4hq+xNq3PFLmCG/QP+5Od5JvpbBKqX9frc1UvOJJ3OKSjgWMx6FfHr8PxqqACw lsimngar@OptiPlex-790',
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI4gvhOpwKbukZP/Tht/GmKcRCBHGn8JadVlgb9U6O/EP/hR1KLDbKY7KVjVOlUcvfawn44SIGsmKCzehYJV2s/XU1QSaaLrjB7n+vfOyj1C3EgzfZcMOHvL51xPuSgIoKd9oER/63B/pUV/BEZK5LEC06O1LgAjwLy2DrHNN3cQdnTbxQ4vM5ggDb/BC+DyRYlN5NG74VFguVQmoqMPA8FYXBvT/bBvIAZFw7piZIQFd6C803dtG6xwgo2yNXp hello@mylaptop'
);
"group" = "oneadmin";
"labels" = list("quattor", "quattor/localuser");
