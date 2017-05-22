BEGIN {
    our $TQU = <<'EOF';
[tt]
# still requires custom 01-tt tests
version = regular
EOF
}

use Test::Quattor::Unittest qw(nopod);
