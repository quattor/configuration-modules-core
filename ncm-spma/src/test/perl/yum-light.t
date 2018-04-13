use strict;
use warnings;

use Test::More;
use Test::Quattor qw(light);

my $cfg = get_config_for_profile("light");

my $compstree = $cfg->getTree("/software/components");
#diag explain $compstree;

my $expected = {
  'accounts' => {
    'active' => 1,
    'dependencies' => {
      'pre' => [
        'pre1',
        'spmalight', # spma pre dep replaced with spmalight
        'pre2'
      ]
    },
    'dispatch' => 1,
  },
  'pre1' => {},
  'pre2' => {},
  'spma' => {
    'active' => 1,
    'dependencies' => {
      'pre' => [
        'accounts' # accounts added as pre dep
      ]
    },
    'dispatch' => 1,
    'fullsearch' => 0,
    'packager' => 'yum',
    'process_obsoletes' => 0,
    'register_change' => [
      '/software/groups',
      '/software/packages',
      '/software/repositories'
    ],
    'run' => 'yes',
    'userpkgs' => 'no', # spma has userpkgs
    'userpkgs_retry' => 1
  },
  'spmalight' => { # spmalight has no userpkgs
    'active' => 1,
    'dependencies' => {
      'post' => [
        'spma' # spma as post dep
      ]
    },
    'dispatch' => 1,
    'filter' => '(a|b|^ncm-(accounts|spma)$)', # SPMALIGHT_FILTERS join worked
    'fullsearch' => 0,
    'ncm-module' => 'spma', # use spma module
    'packager' => 'yum',
    'process_obsoletes' => 0, # this is set by schema default, signifying the type is bound
    'register_change' => [
      '/software/groups',
      '/software/packages',
      '/software/repositories'
    ],
    'run' => 'yes',
    'userpkgs_retry' => 1
  }
};

diag explain $compstree;
foreach my $attr (qw(kept_groups kept_users preserved_accounts remove_unknown version)) {
    delete $compstree->{accounts}->{$attr};
}

is_deeply($compstree, $expected, "configuration as expected");

done_testing();
