---
layout: documentation
title: fmonagent
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

NCM::fmonagent - NCM Lemon Monitoring Agent configuration component

### SYNOPSIS

- Configure()

    Creates configuration file(s) and restarts the lemon-agent service.
    In case of the single file configuration the files
    is defined in the CDB template as file and in case of split file as 
    a directory where the following structure is expected:

    	top_dir/general.conf
    	top_dir/transport/
    	top_dir/metrics/
    	top_dir/sensors/

    Component will try in this case to modify the top\_dir/general.conf,
    top\_dir/transport/udp.conf, top\_dir/metrics/default.conf and for each 
    sensor top\_dir/sensors/sensor\_name.conf files.

- Unconfigure()

    Not available.

### RESOURCES

- `/software/components/fmonagent/active`     : boolean

    activates/deactivates the component.

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

#### Warning

This version of NCM::fmonagent will not work with sensorAlarm!

#### Required programs.

Requires lemon-agent rpm to be installed.

### BUGS

none known.

Miroslav Siket <miroslav.siket@cern.ch>, Dennis Waldron <>

### SEE ALSO

ncm-ncd(1)
