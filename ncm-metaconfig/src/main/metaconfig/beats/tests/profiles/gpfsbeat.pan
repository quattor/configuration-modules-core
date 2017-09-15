object template gpfsbeat;

# configuration of the service
include 'metaconfig/beats/gpfsbeat';

prefix "/software/components/metaconfig/services/{/etc/gpfsbeat/gpfsbeat.yml}/contents/gpfsbeat";
"period" = "3600s";
"devices" = list("all");
"mmrepquota" = "/usr/lpp/mmfs/bin/mmrepquota";
"mmlsfs" = "/usr/lpp/mmfs/bin/mmlsfs";
"mmdf" = "/usr/lpp/mmfs/bin/mmdf";

variable GPFSBEAT_TARGET_HOST_LIST ?= list("tangela1.ugent.be:5043", "tangela2.ugent.be:5043");
prefix "/software/components/metaconfig/services/{/etc/gpfsbeat/gpfsbeat.yml}/contents/output/logstash";
"hosts" = GPFSBEAT_TARGET_HOST_LIST;
"loadbalance" = true;
"ssl/certificate_authorities" = list("/etc/pki/CA/certs/terena-bundle.pem");
"ssl/certificate" = "/etc/pki/tls/certs/gpfsbeat_cert.pem";
"ssl/key" = "/etc/pki/tls/private/gpfsbeat_cert_pkcs8.key";

prefix "/software/components/metaconfig/services/{/etc/gpfsbeat/gpfsbeat.yml}/contents/logging";
"level" = "info";
"to_files" = true;
"to_syslog" = false;
#"metrics/period" = 3600;  # log changed metrics every hour, same as the period in which we measure
"files/path" = "/var/log/beats";
"files/name" = "gpfsbeat.log";
"files/rotateeverybytes" = 104857600;
"files/keepfiles" =  3;
