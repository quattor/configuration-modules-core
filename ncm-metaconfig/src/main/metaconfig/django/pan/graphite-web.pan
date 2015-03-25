unique template metaconfig/django/graphite-web;

include 'metaconfig/django/schema';

bind "/software/components/metaconfig/services/{/opt/graphite/webapp/graphite/local_settings.py}/contents" = django_main;

prefix "/software/components/metaconfig/services/{/opt/graphite/webapp/graphite/local_settings.py}";
"daemon/0" = "httpd";
"module" = "django/main";
