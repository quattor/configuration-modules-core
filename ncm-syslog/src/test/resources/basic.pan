object template basic;

function pkg_repl = { null; };
include 'components/syslog/config';
# remove the dependencies
'/software/components/syslog/dependencies' = null;

prefix "/software/components/syslog";
"daemontype" = 'rsyslog';
"directives" = list("directive one", "directive three");
"syslogdoptions" = "a b c";
"klogdoptions" = "d e f";
"fullcontrol" = true;

"config" = append(dict(
    "selector", list(dict(
        "facility", '*',
        "priority", '*')),
    "action", 'super*powers',
    "comment", 'a comment',
    "template", "ignored"));

"config" = append(dict("action", "mooore"));

"config" = append(dict(
    "selector", list(
        dict("facility", 'user', "priority", 'crit'),
        dict("facility", 'mail', "priority", 'debug')),
    "action", 'awesome',
    "comment", "\n# already wrapped\n"));

"config" = append(dict(
    'selector', list(
        dict(
            'facility', 'uucp,news',
            'priority', 'crit',
        ),
    ),
    'action', '/var/log/spooler',
));
