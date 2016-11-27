use strict;
use warnings;

use Test::Quattor qw(simple);
use Test::More;

use NCM::Component::interactivelimits;
use CAF::Object;

use Readonly;

Readonly my $TEXT => <<'EOF';
#dom0                 typ0       i0              val0
dom3                 typ3       i3              val3
EOF

Readonly my $FINAL_TEXT => <<'EOF';
dom0                 typ0       i0              val0
dom3                 typ3       i3              val3
dom1                 typ1       i1              val1
EOF

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::interactivelimits->new("interactivelimits");

my $cfg = get_config_for_profile("simple");
set_file_contents('/etc/security/limits.conf', $TEXT);
$cmp->Configure($cfg);

my $fh = get_file('/etc/security/limits.conf');
is("$fh", $FINAL_TEXT, "limits changed as expected");

done_testing();
