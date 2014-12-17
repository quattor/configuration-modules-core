structure template location;

"set_header/X-Real-IP" = "$remote_addr";
"set_header/X-Forwarded-For" = "$proxy_add_x_forwarded_for";
"set_header/X-Forwarded-Host" = "$host";
"set_header/X-Forwarded-Proto" = "https";
"next_upstream" = "off";
"cache/valid/0/codes" = list(200, 202, 302);
"cache/valid/0/period" = 60;
"cache/valid/1/codes/0" = 404;
"cache/valid/1/period" = 5;
