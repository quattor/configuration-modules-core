object template exports;

include 'base';
prefix "/software/components/nfs/exports/0";
"path" = "/my/path0";
"hosts/{my.super.host}" = "opts1,opts2";
"hosts/{async.super.host}" = "async,opts1,opts2";
prefix "/software/components/nfs/exports/1";
"path" = "/my/path1";
"hosts/{my.super.host1}" = "opts1,opts2";
"hosts/{async.super.host1}" = "async,opts1,opts2";
