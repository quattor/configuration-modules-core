#${PMpre} NCM::Component::Ceph::Cfgfile${PMpost}

use parent qw(CAF::Object);
use Readonly;
use EDG::WP4::CCM::TextRender;
Readonly my $CEPH_CFGFILE => '/etc/ceph/ceph.conf';

sub _initialize
{
    my ($self, $config, $log, $path, $cfgfile) = @_;

    $self->{log} = $log;
    $self->{path} = $path;
    $self->{tree} = $config->getTree($self->{path}, undef, convert_list =>
        [$EDG::WP4::CCM::TextRender::ELEMENT_CONVERT{arrayref_join_comma}]);

    $self->{cfgfile} = $cfgfile || $CEPH_CFGFILE;

    return 1;
}

sub write_cfgfile
{
    my ($self) = @_;

    my $rgw = delete $self->{tree}->{rgw} || {};
    my $newtree = {%{$self->{tree}}, %$rgw};

    my $trd = EDG::WP4::CCM::TextRender->new(
        'tiny', $newtree, log => $self
    );
    my $fh = $trd->filewriter($self->{cfgfile});
    if (!$fh) {
        $self->error("Could not write ceph config file $self->{cfgfile}: $trd->{fail}");
        return;
    };
    $fh->close();

    $self->debug(1, "done processing config file $self->{cfgfile}");

}

sub configure
{
    my ($self) = @_;

    return if (!$self->write_cfgfile());

    return 1;
}

1;
