object template base;

include 'common';

prefix '/software/components/sindes_getcert';
"active" = true;
"aii_gw" = "test.ugent.be";
"ca_cert" = "ca-test.ugent.be.crt";
"ca_cert_rpm" = "SINDES-ca-certificate-test";
"cert_dir" = "/etc/sindes/certs";
"client_cert" = "client_cert.pem";
"client_cert_key" = "client_cert_key.pem";
"client_key" = "client_key.pem";

'/system/network/hostname' = 'test12';
