BEGIN {
    our $TQU = <<'EOF';
[load]
prefix=NCM::Component::
modules=ceph,Ceph::Luminous,Ceph::Jewel
EOF
}
use Test::Quattor::Unittest qw(nopod);
