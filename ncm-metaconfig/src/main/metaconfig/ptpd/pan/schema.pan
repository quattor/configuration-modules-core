declaration template metaconfig/ptpd/schema;

@documentation{
    PTPv2 configuration based on 2.3.1 configfile
}
# generated based on
# grep -B 1 'ptpengine:' /etc/ptpd2.conf | sed "s/^;\?ptpengine:\(.*\)=/    '\1' ? string # default /; s/^; *\(.*\)/    @{\1}/" | grep -v '\--'

include 'pan/types';

# an interface with an ip
# TODO move to core templates
type usable_network_interface = string with {
    path = format('/system/network/interfaces/%s', SELF);
    return(exists(path+'/ip') || (exists(path+'/bootproto') && value(path+'/bootproto') == 'dhcp'));
};

type ptpd_service_ptpengine = {
    @{interface has to be specified}
    'interface' : usable_network_interface
    @{PTP domain}
    'domain' ? long(0..) = 0
    @{available presets are slaveonly, masteronly and masterslave (full IEEE 1588 implementation)}
    'preset' ? string = 'slaveonly' with match(SELF, '^(masterslave|(master|slave)only)$')
    @{multicast for both sync and delay requests - use hybrid for unicast delay requests}
    'ip_mode' ? string = 'multicast' with match(SELF, '^(multicast|hybrid)$')
    @{when enabled, sniffing is used instead of sockets to send and receive packets}
    'use_libpcap' ? boolean = false
    @{go into panic mode for number of minutes instead of resetting the clock}
    'panic_mode' ? boolean = true
    'panic_mode_duration' ? long(0..) = 10
    @{uncomment this to enable outlier filters}
    'sync_outlier_filter_enable' ? boolean = true
    'delay_outlier_filter_enable' ? boolean = true
    @{wait 5 statistics intervals for one-way delay to stabilise}
    'calibration_delay' ? long(0..) = 5
    @{required if ip_mode is set to hybrid}
    'log_delayreq_interval' ? long(0..) = 0
    @{use DSCP 46 for expedited forwarding over ipv4 networks}
    # 6 bit
    'ip_dscp' ? long(0..63) = 46
} with {
    if (exists(SELF['ip_mode']) && SELF['ip_mode'] == 'hybrid' && (! exists(SELF['log_delayreq_interval']))) {
        error('ptpengine: log_delayreq_interval is requieed with ip_mode hybrid');
    };
    true;
};

type ptpd_service_global = {
    @{update online statistics every 5 seconds}
    'statistics_update_interval' ? long(0..) = 5
    @{log file, event log only. if timing statistics are needed, see statistics_file}
    'log_file' ? string  = '/var/log/ptpd2.log'
    @{log file in kB}
    'log_file_max_size' ? long(0..) = 5000
    @{rotate logs number of rotations}
    'log_file_max_files' ? long(0..) = 5
    @{provide an overview of ptpd's operation and statistics (via enviroment variable PTPD_STATUS_FILE, default /var/run/ptpd2.status}
    'log_status' ? boolean = true
    @{log a timing log like in previous ptpd versions}
    'statistics_file' ? string = '/var/log/ptpd2.stats'
    @{on multi-core systems it is recommended to bind ptpd to a single core}
    'cpuaffinity_cpucore' ? long(0..) = 0
};

type ptpd_service_clock = {
    @{store observed drift in a file}
    'drift_handling' ? string = 'file' with match(SELF, '^(file)$')
    'drift_file' ? string = '/var/log/ptpd2_kernelclock.drift'
    @{step clock on startup only if offset more than 1 second, ignoring panic mode and no_reset}
    'step_startup' ? boolean = false
    @{attempt setting the RTC when stepping clock}
    'set_rtc_on_step' ? boolean = false
};

type ptpd_service = {
    'ptpengine' : ptpd_service_ptpengine
    'global' ? ptpd_service_global
    'clock' ? ptpd_service_clock
};
