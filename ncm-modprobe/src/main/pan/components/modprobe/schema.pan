# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/modprobe/schema;
include 'quattor/schema';

type module_type = {
    "name" : string # name of the loadable modules"
    "alias" ? string # alias for the loadable module"
    "options" ? string # options for the loadable module"
    "install" ? string # command to run when loading module"
    "remove" ? string # command to run when removing module"
    "blacklist" ? string # ignored, only the name of the module is used"
};

type component_modprobe_type = {
    include structure_component
    "file" : string = "/etc/modprobe.d/quattor.conf"
    "modules" : module_type[1..] # modules to load"
};

bind "/software/components/modprobe" = component_modprobe_type;
