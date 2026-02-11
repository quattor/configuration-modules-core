object template dnf_ssl_all;

include 'dnf_base_config';

prefix "/software/repositories/0";
"name" = "ssl_full_repo";
"owner" = "test@example.com";
"protocols/0/name" = "https";
"protocols/0/url" = "https://secure.example.com/repo";
"protocols/0/verify" = true;
"protocols/0/cacert" = "/etc/pki/CA/ca-bundle.crt";
"protocols/0/clientcert" = "/etc/pki/tls/certs/client.pem";
"protocols/0/clientkey" = "/etc/pki/tls/private/client.key";
