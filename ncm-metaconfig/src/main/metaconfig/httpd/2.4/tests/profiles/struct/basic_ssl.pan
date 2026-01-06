structure template struct/basic_ssl;

"options" = list("-OptRenegotiate", "+StrictRequire", "+StdEnvVars");
"engine" = true;
"ciphersuite" = list(
    "ECDHE-ECDSA-AES128-GCM-SHA256",
    "ECDHE-RSA-AES128-GCM-SHA256",
    "ECDHE-ECDSA-AES256-GCM-SHA384",
    "ECDHE-RSA-AES256-GCM-SHA384",
    "ECDHE-ECDSA-CHACHA20-POLY1305",
    "ECDHE-RSA-CHACHA20-POLY1305",
    "DHE-RSA-AES128-GCM-SHA256",
    "DHE-RSA-AES256-GCM-SHA384",
    "DHE-RSA-CHACHA20-POLY1305"
);
"certificatefile" = "/etc/cert_file";
"certificatekeyfile" = "/etc/key_file";
"cacertificatefile" = "/etc/ca_file";
