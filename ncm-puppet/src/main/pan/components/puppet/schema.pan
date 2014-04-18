# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

type ${project.artifactId}_module = {
        "version" ? string
};

type ${project.artifactId}_nodefile = {
        "contents" ? string
};

type ${project.artifactId}_puppetconf_main = extensible {
        "logdir" : string = "/var/log/puppet"
        "rundir" : string = "/var/run/puppet"
};



type ${project.artifactId}_puppetconf = extensible {
        "main" : ${project.artifactId}_puppetconf_main
};

type puppet_hieraconf_yaml = extensible {
        "_3adatadir" : string = "/etc/puppet/hieradata"
};

type puppet_hieraconf = extensible {
        "_3abackends" : string[] = list("yaml")
        "_3ayaml" : puppet_hieraconf_yaml
        "_3ahierarchy" : string[] = list("quattor")
};

type ${project.artifactId}_hieradata = extensible {};

type ${project.artifactId}_component = {
  include structure_component
  "modules" ? ${project.artifactId}_module{}
  "nodefiles" : ${project.artifactId}_nodefile{}= nlist(escape("quattor_default.pp"),nlist("contents","hiera_include('classes')"))
  "puppetconf" : ${project.artifactId}_puppetconf = nlist("main",nlist("logdir","/var/log/puppet","rundir","/var/run/puppet"))
  "hieraconf" : ${project.artifactId}_hieraconf = nlist(escape(":backends"),list("yaml"),escape(":yaml"),nlist(escape(":datadir"),"/etc/puppet/hieradata"),escape(":hierarchy"),list("quattor"))
  "hieradata" ? ${project.artifactId}_hieradata
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
