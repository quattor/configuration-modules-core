object template config_2.3;

include 'metaconfig/ptpd/config';
"/system/network/interfaces/eth0/ip" = "1.2.3.4";
"/software/components/metaconfig/services/{/etc/ptpd2.conf}/contents/ptpengine/interface" = 'eth0';

# based on
# grep 'ptpengine:' /etc/ptpd2.conf | sed "s/^ptpengine:\(.*\)=/'\1' = /;s/$/;/" | grep -v '\--'


prefix "/software/components/metaconfig/services/{/etc/ptpd2.conf}/contents/ptpengine";
'domain' = 0;
'preset' = 'slaveonly';
'ip_mode' = 'multicast';
'use_libpcap' = false;
'panic_mode' = true;
'panic_mode_duration' = 10;
'sync_outlier_filter_enable' = true;
'delay_outlier_filter_enable' = true;
'calibration_delay' = 5;
'ip_dscp' = 46;

prefix "/software/components/metaconfig/services/{/etc/ptpd2.conf}/contents/global";
'statistics_update_interval' = 5;
'log_file' = '/var/log/ptpd2.log';
'log_file_max_size' = 5000;
'log_file_max_files' = 5;
'log_status' = true;

prefix "/software/components/metaconfig/services/{/etc/ptpd2.conf}/contents/clock";
'drift_handling' = 'file';
'drift_file' = '/var/log/ptpd2_kernelclock.drift';
