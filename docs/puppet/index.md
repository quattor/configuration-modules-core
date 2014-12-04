---
layout: documentation
title: puppet
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

ncm-puppet: Component for running puppet standalone within quattor

### DESCRIPTION

puppet

### RESOURCES

#### `/software/components/puppet/puppetconf`

Defines the configuration for quattor. Each item is a section of the `/etc/puppet/puppet.conf` file. The section '\[main\]' is mandatory.
Other sectiond may be added

#### `/software/components/puppet/puppetconf/main`

Each item is a parameter in the '\[main\]' section of the puppet.conf file. Below the mandaroy parameters

- `logdir` : 

    Puppet log dir. Defaults to `/var/log/puppet.`

- `rundir` : string

    Puppet run dir. Defaults to `/var/log/puppet.`

#### `/software/components/puppet/hieraconf`

Defines the configuration for hiera. Each item is a key definition in the `/etc/puppet/hiera.yaml` file. Here are the default values.
The default is 

    ---
    :backends:
    - yaml
    :hierarchy:
    - quattor
    :yaml:
          :datadir: `/etc/puppet/hieradata`

#### `/software/components/puppet/nodefiles`

named list of node specific manifests. The component will run "puppet --apply `/etc/puppet/manifests`/<file>" for each item <file> of the nlist.
The parameters of each item are.

- `contents` : string

    content of the file

    The default for "nodefiles" is one file quattor\_default.pp with content "hiera\_include('classes')".

    #### `/software/components/puppet/hieradata`

    Data to be passed to the hiera config. Teh data will be written in `/etc/puppet/hieradata/quattor.yaml`. Note: the nlist keys will be unescaped by the component.

    #### `/software/components/puppet/modules`

    Named list of modules to be downloaded from the puppetlab forge. Each module has the following parameters

    - `version` ? string

        version of the module.

        = back
        = back 

        

        ### TODO

        Better way to place the defaults on hieraconf parameter.

        Downloading files from other sources than PuppetLabs forge.
