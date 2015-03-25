object template graphite-web;

include 'metaconfig/django/graphite-web';

prefix "/software/components/metaconfig/services/{/opt/graphite/webapp/graphite/local_settings.py}/contents/config";

"storage_finders" = list('cyanite.CyaniteFinder');
"cyanite_urls" = list('http://host:port');
"list2" = list('bla', 'bla', 'bla');
