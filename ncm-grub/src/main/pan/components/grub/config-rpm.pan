# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/grub/config-rpm;

include {'components/grub/schema'};

include {'pan/functions'};

# Package to install.
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


# standard component settings
"/software/components/grub/active" ?=  true ;
"/software/components/grub/dispatch" ?=  true ;
"/software/components/grub/dependencies/pre" = push( "spma" );
"/software/components/grub/register_change/0" = "/system/kernel/version";

# component specific settings
"/system/kernel/version" ?=  undef ;
# you may need to set /software/components/grub/prefix if not using
# /boot ...

