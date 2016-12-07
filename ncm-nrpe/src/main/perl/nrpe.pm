#${PMpre} NCM::Component::nrpe${PMpost}

use CAF::FileWriter;
use CAF::Service;

use parent qw(NCM::Component);
use Readonly;

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

Readonly my $FILE => '/etc/nagios/nrpe.cfg';

sub Configure
{
    my ($self, $config) = @_;
    my $st = $config->getElement ($self->prefix()."/options")->getTree;

    my $mode = $config->getElement($self->prefix()."/mode")->getValue();
    my $owner = "root";
    my $group = $st->{nrpe_group};

    # Open file
    my $fw = CAF::FileWriter->open ($FILE,
                                    mode => $mode,
                                    owner => $owner,
                                    group => $group,
                                    log => $self);

    # Output caution header
    print $fw "# $FILE\n";
    print $fw "# written by ncm-nrpe. Do not edit!\n";

    # Output unreferenced options sorted
    foreach my $key (sort(keys %{$st})) {
        my $value = $st->{$key};
        print $fw "$key=$value\n" unless (ref($value) eq "ARRAY" || ref($value) eq "HASH");
    }

    # Output allowed_hosts array as a comma separated string
    print $fw "allowed_hosts=" . join (",", @{$st->{allowed_hosts}}) . "\n";

    # Output nrpe_commands sorted
    foreach my $cmdname (sort(keys %{$st->{command}})) {
        my $cmdline = $st->{command}->{$cmdname};
        print $fw "command[$cmdname]=$cmdline\n";
    }

    # Output external files' includes
    foreach my $fn (@{$st->{include}}) {
        print $fw "include=$fn\n";
    }

    # Output directory includes
    foreach my $dn (@{$st->{include_dir}}) {
        print $fw "include_dir=$dn\n";
    }

    # Close the output file
    if ($fw->close()) {
        CAF::Service->new(['nrpe'], log => $self)->restart();
        return $? ? 0 : 1;
    }

    return 1;
}

1;
