structure template struct/basic_ssl;

"options" = list("-OptRenegotiate", "+StrictRequire", "+StdEnvVars");
"engine" = true;
"ciphersuite" = list("TLSv1");
"certificatefile" = "/etc/cert_file";
"certificatekeyfile" = "/etc/key_file";
"cacertificatefile" = "/etc/ca_file";
