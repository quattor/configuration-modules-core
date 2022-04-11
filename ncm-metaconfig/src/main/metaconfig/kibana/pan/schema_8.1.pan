declaration template metaconfig/kibana/schema_8.1;

include 'pan/types';

type kibana_service_server = {
    "port" ? type_port = 5601
    "host" ? type_hostname = "localhost.localdomain" # not insecure shipped default "0.0.0.0"
    "basePath" ? absolute_file_path
    "maxPayloadBytes" ? long = 1048576
    "ssl.enabled" ? boolean = false
    "server.ssl.certificate" ? absolute_file_path
    "server.ssl.key" ? absolute_file_path
};

type kibana_service_elasticsearch = {
    "hosts" : type_absoluteURI = "http://localhost:9200"
    "ssl.certificate" ? absolute_file_path
    "ssl.key" ? absolute_file_path
    "ssl.certificateAuthorities" ? list = list ("/path/to/your/CA.pem")
    "ssl.verificationMode" ? string = "full"
    "pingTimeout" ? long = 1500
    "requestTimeout" ? long = 30000
    "requestHeadersWhitelist" ? list = list("authorization")
    "customHeaders" ? dict
    "shardTimeout" ? long = 0
    "startupTimeout" ? long = 5000
    "serviceAccountToken" : string
};


type kibana_service_kibana = {
    "index" : string = ".kibana"
    "defaultAppId" ? string = "home"
};

type kibana_service_logging = {
    "dest" ? string = "stdout"
    "silent" ? boolean = false
    "quiet" ? boolean = false
};


# Set the value of this setting to true to log all events, including system usage information
# and all requests.
#logging.verbose: false

type kibana_service = {
    "server"  ? kibana_service_server
    "elasticsearch" : kibana_service_elasticsearch
    "kibana" ? kibana_service_kibana
    "pid.file" ? string = '/var/run/kibana.pid'
    "logging" ? kibana_service_logging
};
