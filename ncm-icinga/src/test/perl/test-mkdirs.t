use strict;
use warnings;
use Test::More;

use Test::Quattor;

use myIcinga;

use Readonly;
Readonly my $DIR => "target/test/icinga/dirs";


my $cmp = NCM::Component::icinga->new('icinga');

$cmp->{ERROR} = 0;

$cmp->make_dirs({check_result_path => $DIR});

ok(-d $DIR, "Directory created");
is($cmp->{ERROR}, 0, "Created directory structure under test location $DIR");

# Make a test that fails directory creation, also if run by root.
# (using empty $t={} would create /var/incinga/spool 
#  when as root (or as icinga user))
# So lets make a file first, and create a directory with same path. Even root can't do that.
my $afile = "$DIR/afile";
open(FH, '>', $afile);
close(FH);
ok(-f $afile, "Created test file $afile");

$cmp->{ERROR} = 0;
$cmp->make_dirs({check_result_path => $afile});
is($cmp->{ERROR}, 1, "Errors reported when creating the directories");

done_testing();
