object template user_oneadmin;

include 'components/opennebula/schema';

bind "/metaconfig/contents/user/oneadmin" = opennebula_user;

"/metaconfig/module" = "user";

prefix "/metaconfig/contents/user/oneadmin";
"ssh_public_key" = list(
    'ssh-dss AAAAB3NzaC1yc2EAAAADAQABAAABAQDI4gvhOpwKbukZP/Tht/GmKcRCBHGn8JadVlgb9U6O/EP/hR1KLDbKY7KVjVOlUcvfawn44SIGsmKCzehYJV2s/XU1QSaaLrjB7n+vfOyj1C3EgzfZcMOHvL51xPuSgIoKd9oER/63B/pUV/BEZK5LEC06O1LgAjwLy2DrHNN3cQdnTbxQ4vM5ggDb/BC+DyRYlN5NG74VFguVQmoqMPA8FYXBvT/bBvIAZFw7piZIQFd6C803dtG61234 another@laptop'
);
