# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/${project.artifactId}/functions;

@documentation{
    desc = Convert path argument and return mount unit. Example: /a/b/c returns a-b-c.mount
    arg = Path to convert
}
function systemd_make_mountunit = {
    if (ARGC != 1) {
        error(format("systemd_make_mountunit takes exactly one argument, got %s", ARGC));
    };
    if (ARGV[0] == '/') {
        error("systemd_make_mountunit cannot convert /");
    };

    # strip leading and/or trailing /
    path = replace('(^/|/$)', '', ARGV[0]);
    format("%s.mount", replace('/', '-', path));
};
