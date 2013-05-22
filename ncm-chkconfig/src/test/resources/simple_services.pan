object template simple_services;

prefix "/software/components/chkconfig/service";

"test_on" = nlist("on",true);
"test_off" = nlist("off",true);
"test_add" = nlist("add",true);
"test_del" = nlist("del",true);

"test_on_rename" = nlist("on",true,"name","othername");
