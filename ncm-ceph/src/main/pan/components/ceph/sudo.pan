# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


unique template components/${project.artifactId}/sudo;

include 'components/sudo/config';


"/software/components/sudo/privilege_lines" = { 
    sudolist = list(
        "/usr/bin/ceph-deploy", 
        "/usr/bin/python -c import sys;exec(eval(sys.stdin.readline()))", 
        "/usr/bin/python -u -c import sys;exec(eval(sys.stdin.readline()))", 
        "/bin/mkdir"
    );
    foreach (i; cmd; sudolist){
        nl = nlist("host", "ALL",
                   "options", "NOPASSWD:",
                   "run_as", "ALL",
                   "user", "ceph");
        nl["cmd"] = cmd;
        append(nl);
    };  
    SELF;
};

