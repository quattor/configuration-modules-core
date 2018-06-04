${componentconfig}

'securitypath' ?= {
    if (exists('/system/archetype/os/name') &&
        value('/system/archetype/os/name') == 'solaris') {
        '/etc/cron.d';
    } else {
        '/etc';
    };
};
