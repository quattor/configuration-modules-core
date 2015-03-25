@{
    Describes an nginx instance used as a caching proxy
}
structure template proxy-cache;

"proxy_cache_path/0/path" = "/var/lib/nginx/cache";
"proxy_cache_path/0/keys_zone/cache" = 20000;
"server/0/listen" = format("%s:80", FULL_HOSTNAME);
"server/0/name" = FULL_HOSTNAME;
