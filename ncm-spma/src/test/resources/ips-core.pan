object template ips-core;

prefix "/software/components/spma";

"run" = "no";
"active" = true;
"dispatch" = true;
"userpkgs" = "no";
"packager" = "ips";
"pkgpaths" = list("/software/catalogues", "/software/requests");
"uninstpaths" = list("/software/uninstall");
"register_change" = list(
    "/software/catalogues",
    "/software/requests",
    "/software/uninstall",
);
"cmdfile" = "/var/tmp/spma-commands.test.$$";
"flagfile" = "/var/tmp/spma-run-flag.test.$$";
"ips/imagedir" = "/var/tmp/.ncm-spma-image.test.$$";

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
"{pkg:/local/group/system/solaris-large-server}" = dict();
"{pkg:/local/group/aquilon/core-os}" = dict();

#
# Packages we do NOT want
#
prefix "/software/uninstall";

"{pkg:/system/fault-management/smtp-notify}" = dict();
"{pkg:/service/network/smtp/sendmail}" = dict();
"{pkg:/system/management/ocm}" = dict();
"{pkg:/library/print/cups-libs}" = dict();
"{pkg:/library/desktop/gtk2/gtk-backend-cups}" = dict();
"{pkg:/print/cups}" = dict();
"{pkg:/print/cups/hal-cups-utils}" = dict();
"{pkg:/print/cups/filter/foomatic-db}" = dict();
"{pkg:/print/cups/filter/foomatic-db-engine}" = dict();
"{pkg:/print/filter/a2ps}" = dict();
"{pkg:/print/filter/hplip}" = dict();
"{pkg:/print/lp/filter/foomatic-rip}" = dict();
"{pkg:/system/network/ppp}" = dict();
"{pkg:/system/network/ppp/tunnel}" = dict();
