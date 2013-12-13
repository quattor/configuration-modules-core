object template ips-core;

prefix "/software/components/spma";

"run" = "no";
"active" = true;
"dispatch" = true;
"userpkgs" = "no";
"packager" = "ips";
"pkgpaths" = list("/software/catalogues", "/software/requests");
"uninstpaths" = list("/software/uninstall");
"register_change" = list("/software/catalogues", "/software/requests",
                         "/software/uninstall");
"flagfile" = "/var/tmp/spma-run-flag";

#
# Subscribe to some catalogues
#
prefix "/software/catalogues";
"{pkg:/entire}/{0.5.11,5.11-0.175.1.12.0.5.0:20131009T142054Z}" = "";
"{pkg:/local/consolidation/local-incorporation}/{11.1.1.20,5.11:20131128T172825Z}" = "";

#
# Grouping package versions constrained by local-incorporation
#
prefix "/software/requests";
"{pkg:/local/group/system/solaris-large-server}" = nlist();
"{pkg:/local/group/aquilon/core-os}" = nlist();

#
# Packages we do NOT want
#
prefix "/software/uninstall";

"{pkg:/system/fault-management/smtp-notify}" = nlist();
"{pkg:/service/network/smtp/sendmail}" = nlist();
"{pkg:/system/management/ocm}" = nlist();
"{pkg:/library/print/cups-libs}" = nlist();
"{pkg:/library/desktop/gtk2/gtk-backend-cups}" = nlist();
"{pkg:/print/cups}" = nlist();
"{pkg:/print/cups/hal-cups-utils}" = nlist();
"{pkg:/print/cups/filter/foomatic-db}" = nlist();
"{pkg:/print/cups/filter/foomatic-db-engine}" = nlist();
"{pkg:/print/filter/a2ps}" = nlist();
"{pkg:/print/filter/hplip}" = nlist();
"{pkg:/print/lp/filter/foomatic-rip}" = nlist();
"{pkg:/system/network/ppp}" = nlist();
"{pkg:/system/network/ppp/tunnel}" = nlist();

