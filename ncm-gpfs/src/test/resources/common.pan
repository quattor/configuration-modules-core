unique template common;

function pkg_repl = { null; };
include 'components/gpfs/config';
"/software/components/gpfs/dependencies/pre" = null;

prefix '/software/components/gpfs';

"base" = dict(
    "baseurl", "https://test.ugent.be:446/test",
    "rpms", list(
        "gpfs.base-4.2.1-0.x86_64.rpm",
        "gpfs.docs-4.2.1-0.noarch.rpm",
        "gpfs.gpl-4.2.1-0.noarch.rpm",
        "gpfs.msg.en_US-4.2.1-0.noarch.rpm",
        "gpfs.ext-4.2.1-0.x86_64.rpm"
    ),
    "useccmcertwithcurl", false,
    "usecurl", true,
    "useproxy", false,
    "usesindesgetcertcertwithcurl", true,
    "useyum", true
);
"cfg" = dict(
    "sdrrestore", true,
    "subnet", "test.gent.vsc",
    "url", "https://test.ugent.be:446/test/mmsdrfs",
    'keyData', "https://test.ugent.be:446/test/keydata2",
    "useccmcertwithcurl", false,
    "usecurl", true,
    "usesindesgetcertcertwithcurl", true
);

