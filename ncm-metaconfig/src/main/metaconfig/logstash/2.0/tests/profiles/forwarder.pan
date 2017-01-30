object template forwarder;

include 'metaconfig/logstash/forwarder';

prefix "/software/components/metaconfig/services/{/etc/logstash-forwarder.conf}/contents";

"network/servers/0" = dict("host", "myhost.example.com", "port", 12345);
"network/servers/1" = dict("host", "myhost2.example.com", "port", 12346);
"network/ssl_key" = "/my/key";
"network/ssl_certificate" = "/my/cert";
"network/ssl_ca" = "/my/ca";
"files/0/paths" = list("/path/0/0", "/path/0/1");
"files/0/fields" = dict("type", "type0");
"files/1/paths" = list("/path/1/0", "/path/1/1");
"files/1/fields" = dict("type", "type1");

