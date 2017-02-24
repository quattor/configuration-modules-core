object template aii_kickstart;

include 'vm';

prefix "/system/aii/hooks";
"configure/0" = dict(
    "image", true,
    "template", true,
);

"install/0" = dict(
    "vm", true,
    "onhold", true,
);

"remove/0" = dict(
    "vm", true,
    "image", true,
    "template", true,
);
