object template config;

include 'metaconfig/nginx/config';

variable SERVER = 'myserver.my.domain';
variable FULL_HOSTNAME = 'myhost.my.domain';

prefix "/software/components/metaconfig/services/{/etc/nginx/nginx.conf}/contents/http/0";

"server" = {
    s = dict();
    s["name"] = list(FULL_HOSTNAME);

    s["listen"][0]["addr"] = format("%s:8443", FULL_HOSTNAME);

    s["location"][0]["name"] = '^/\d+/.*repodata';
    s["location"][0]["operator"] = "~";
    s["location"][0]["proxy"] = create("pkg-cache",
        "pass", "https://restricted-packages");

    s["location"][1]["name"] = "repodata";
    s["location"][1]["operator"] = "~";
    s["location"][1]["proxy"] = create("pkg-cache",
        "pass", "https://restricted-packages",
        "cache", null);
    s["location"][2]["name"] = "/";
    s["location"][2]["proxy"] = create("pkg-cache",
        "pass", "https://restricted-packages");


    s["listen"][0]["ssl"] = true;
    s["ssl"] = create("basic_ssl", "options", null);
    s["ssl"]["verify_client"] = "none";

    append(s);

    # add 2nd one
    append(s);
    SELF;
};

"server/1/listen/0/addr" = format("%s:443", FULL_HOSTNAME);
"server/1/listen/1/addr" = format("%s:1443", FULL_HOSTNAME);

"upstream/restricted-packages/host/0" = format("%s:443", SERVER);

"server/1/location" = {
    l = dict();
    l["name"] = "/(secure|share)";
    l["proxy"] = create("location");
    l["proxy"]["pass"] = "https://secure";
    l["proxy"]["cache"]["cache"] = "cache";
    l["proxy"]["cache"]["valid"][0]["period"] = 10;
    l["operator"] = "~";
    prepend(l);
};

"server/1/location" = append(dict(
    "name", "/",
    "operator", "=",
    "return", dict("code", 301, "url", "https://$host/default"),
    ));

"upstream/secure/host/0" = format("%s:446", SERVER);

# 80 -> 443 redirect
"server/2" = dict(
    "listen", list(dict("addr", "80", "default", true)),
    "name", list("_"),
    "return", dict("code", 301, "url", "https://$host$request_uri"),
);
# Disable max body size limit
"client_max_body_size" = 0;
