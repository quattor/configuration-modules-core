declaration template metaconfig/chrony/schema;

include 'pan/types';

type chrony_service_server_flag = choice(
    'iburst', 'burst', 'offline', 'auto_offline', 'prefer', 'noselect', 'trust', 'require', 'xleave'
);

@documentation{
    the crony.conf configuration entry for server/pool/peer options
}
type chrony_service_server_options = {
    'minpoll' ? long # = -6 - power of 2 (1/64th of a second)
    'maxpoll' ? long(0..) # = 6 - power of 2 (32)
    'key' ? string
    'maxdelay' ? double
    'maxdelayratio' ? double
    'maxdelaydevratio' ? double
    'mindelay' ? double
    'asymmetry' ? double(-1..1)
    'offset' ? double
    'minsamples' ? long(0..)
    'maxsamples' ? long(0..)
    'maxsources' ? long # = 4
    'filter' ? long(0..)
    'polltarget' ? long(6..60) # = 8
    'port' ? type_port
    'presend' ? long(0..)
    'minstratum' ? long
    'version' ? choice('3', '4') # = 4
};

@documentation{
    the crony.conf configuration entry for server/pool/peer
}
type chrony_service_server = {
    'hostname' : type_hostname
    'options' ? chrony_service_server_options
    'flags' ? chrony_service_server_flag[]
};

type chrony_service_flag = choice('rtcsync', 'rtconutc', 'manual', 'noclientlog');

@documentation{
    Normally chronyd will cause the system to gradually correct any time offset,
    by slowing down or speeding up the clock as required.
    In certain situations, the system clock might be so far adrift that this slewing process
    would take a very long time to correct the system clock.

    This directive forces chronyd to step the system clock if the adjustment is larger than a threshold value,
    but only if there were no more clock updates since chronyd was started than a specified limit
    (a negative value can be used to disable the limit)
}
type chrony_service_makestep = {
    'threshold' : double(0..)
    'limit' : long
};

@documentation{
    The allow/deny directive is used to designate a particular subnet from which NTP clients
    are allowed/denied to access the computer as an NTP server.
}
type chrony_service_network = {
    'action' : choice('allow', 'deny')
    'host' : type_network_name
};

@documentation{
    The smoothtime directive can be used to enable smoothing of the time that chronyd serves to its clients to make it
    easier for them to track it and keep their clocks close together even when large offset or frequency corrections
    are applied to the server’s clock, for example after being offline for a longer time.
}
type chrony_service_smoothtime = {
    @{ Maximum frequency offset of the smoothed time to the tracked NTP time (in ppm) }
    'max_freq' : double(0..100000)
    @{ Maximum rate at which the frequency offset is allowed to change (in ppm per second) }
    'max_wander' : double(0..100000)
    @{ Only smooth leap seconds, ignore normal offset and frequency changes }
    'leaponly' : boolean
};

@documentation{
    the crony.conf configuration
}
type chrony_service = {
    'server' ? chrony_service_server[]
    'pool' ? chrony_service_server[]
    'peer' ? chrony_service_server[]
    'flags' ? chrony_service_flag[]
    'makestep' ? chrony_service_makestep
    'driftfile' ? absolute_file_path
    'minsources' ? long
    'hwtimestamp' ? string[]
    'network' ? chrony_service_network[]
    'keyfile' ? absolute_file_path
    'logdir' ? absolute_file_path
    'leapsectz' ? string
    @{ Select how errors caused by inerting leap seconds are corrected for }
    'leapsecmode' ? choice('system', 'step', 'slew', 'ignore')
    @{ Maximum rate at which chronyd is allowed to slew the time (in ppm), defaults to 83333.333 (i.e. 1000000/12)}
    'maxslewrate' ? double(0..100000)
    @{ Control smoothing of the time that chronyd serves to its clients }
    'smoothtime' ? chrony_service_smoothtime
};
