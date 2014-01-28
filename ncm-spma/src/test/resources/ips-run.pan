object template ips-run;

prefix "/software/components/spma";

"run" = "yes";
"active" = true;
"dispatch" = true;
"userpkgs" = "no";
"packager" = "ips";
"pkgpaths" = list("/software/catalogues", "/software/requests");
"uninstpaths" = list("/software/uninstall");
"register_change" = list("/software/catalogues", "/software/requests",
                         "/software/uninstall");
"cmdfile" = "/var/tmp/spma-commands.test.$$";
"flagfile" = "/var/tmp/spma-run-flag.test.$$";
"ips/imagedir" = "/var/tmp/.ncm-spma-image.test.$$";

#
# Subscribe to a catalogue
#
prefix "/software/catalogues";
"{pkg:/entire}/latest" = "";
