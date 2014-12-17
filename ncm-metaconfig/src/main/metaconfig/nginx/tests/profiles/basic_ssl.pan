structure template basic_ssl;

"options" = list("-OptRenegotiate", "+StrictRequire", "+StdEnvVars");
"active" = true;
"ciphersuite" = list("TLSv1");
"certificate" = "/etc/mycert";
"key" = "/etc/mykey";
"ca" = "/etc/myca";
