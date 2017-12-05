#${PMpre} NCM::Component::Ceph::Cfgfile${PMpost}

use 5.10.1;

use parent qw(CAF::Object);
use Readonly;
use EDG::WP4::CCM::TextRender;
Readonly my $CEPH_CFGFILE => '/etc/ceph/ceph.conf';

sub _initialize
{
    my ($self, $config, $log, $prefix, $cfgfile ) = @_;

    $self->{log} = $log;
    $self->{prefix} = "$prefix/config";
    $self->{config} = $config->getTree($self->{prefix}, convert_list =>
        [$EDG::WP4::CCM::TextRender::ELEMENT_CONVERT{arrayref_join_comma}]);

    $self->{cfgfile} = $cfgfile || $CEPH_CFGFILE;

    return 1;
}

sub write_cfgfile
{
    my ($self) = @_;

    my $rgw = delete $self->{config};
    my $newtree = {%{$self->{config}}, %{$rgw||{}}};

    $self->debug(5, "Config to write:", Dumper($newtree));
    my $trd = EDG::WP4::CCM::TextRender->new(
        $newtree, 'tiny', log => $self
    );
    my $fh = $trd->filewriter($self->{cfgfile});
 
    $fh->close();
       
    $self->debug(2,"content written to config file $self->{cfgfile}");

}

sub configure
{
    my ($self) = @_;
    
    if (!$self->write_cfgfile()) {
        $self->error('Could not write cfgfile');
        return;
    }

    return 1;
}

1;
