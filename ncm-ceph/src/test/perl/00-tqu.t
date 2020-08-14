BEGIN {
    our $TQU = <<'EOF';
[load]
prefix=NCM::Component::
modules=ceph,Ceph::Luminous
EOF
}
use Test::Quattor::Unittest qw(nopod);
