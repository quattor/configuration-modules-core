# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;
use NCM::Component;
use vars qw(@ISA $EC);
use base qw(NCM::Component);
$EC  = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element qw(unescape);

use CAF::Process;
use CAF::FileWriter;

use Config::Tiny;
use YAML::XS;

our $NoActionSupported = 1;

use Readonly;

Readonly::Scalar my $MODULE_INSTALL => 'puppet module upgrade %s %s||puppet module install %s %s';
Readonly::Scalar my $NODEFILES_PATH => '/etc/puppet/manifests';
Readonly::Scalar my $PUPPET_CONFIG_FILE => '/etc/puppet/puppet.conf';
Readonly::Scalar my $HIERA_CONFIG_FILE => '/etc/puppet/hiera.yaml';
Readonly::Scalar my $HIERA_DATA_FILE => '/etc/puppet/hieradata/quattor.yaml';
Readonly::Scalar my $APPLY => 'puppet apply --detailed-exitcodes -v -l /var/log/puppet/log %s;test $? == 2;';

local (*DTA);

sub Configure
{
    my ($self, $config) = @_;

    my $confighash = $config->getElement($self->prefix)->getTree();
    
    # Update the config file
    $self->tiny($confighash->{puppetconf},$PUPPET_CONFIG_FILE);
    
    $self->yaml($confighash->{hieraconf},$HIERA_CONFIG_FILE);
    
    # Install/Upgrade modules
    $self->install_modules($confighash) if(defined($confighash->{modules})); 
    
    $self->yaml($confighash->{hieradata},$HIERA_DATA_FILE) if(defined($confighash->{hieradata}));
    
    # Prepare the node files
    $self->nodefiles($confighash);
    
    # Run puppet apply
    $self->apply($confighash);
    
    return 0;
}

sub nodefiles {
    my $self=shift;
    my $confighash=shift;

    foreach my $file (sort keys %{$confighash->{nodefiles}}){
	if($confighash->{nodefiles}->{$file}->{contents}){
	    my $path=$NODEFILES_PATH."/".unescape($file);
	    $self->checkfile($path,$confighash->{nodefiles}->{$file}->{contents});
	}
	
    }
    return 0;
}



sub apply {
    my $self=shift;
    my $confighash=shift;

    foreach my $file (sort keys %{$confighash->{nodefiles}}){

	$self->cmd_exec(sprintf($APPLY,$NODEFILES_PATH."/".unescape($file)))
    }
}

sub install_modules {
    my $self=shift;
    my $confighash=shift;

    foreach my $mod (sort keys %{$confighash->{modules}}){
	my $module=unescape($mod);
	my $version='';
	if(defined($confighash->{modules}->{$mod}->{version})){
	    $version="--version=".$confighash->{modules}->{$mod}->{version};
	}
	my $cl = sprintf($MODULE_INSTALL,$module,$version,$module,$version);
	$self->cmd_exec($cl);
    }
    return 0;
}

sub cmd_exec {
    my $self=shift;
    my $cl=shift;

    my $cmd_output;

    my $cmd = CAF::Process->new([$cl], log => $self,
                                shell => 1,
                                stdout => \$cmd_output,
				stderr => "stdout");
    $cmd->execute();

    if ( $? ) {
	$self->error("Command failed. Command output: $cmd_output\n");
    } else {
	$self->debug(1,"Command output: $cmd_output\n");
    }

    return $cmd_output;

}




sub tiny {
    my $self=shift;
    my $cfg=shift;
    my $file=shift;

    my $c = Config::Tiny->new();

    while (my ($k, $v) = each(%$cfg)) {
        if (ref($v)) {
            $c->{$k} = $v;
        } else {
            $c->{_}->{$k} = $v;
        }
    }

    $self->checkfile($file,$c->write_string());
    
    return 0;
    
}


sub yaml {
    my $self=shift;
    my $cfg=shift;
    my $file=shift;

    $self->checkfile($file,YAML::XS::Dump($self->unescape_keys($cfg)));    

    return 0;
}

sub unescape_keys {
    my $self=shift;
    my $cfg=shift;

    my $res={};

    while (my ($k, $v) = each(%$cfg)) {
	
	if(ref($v) eq ref({})){
	    $res->{unescape($k)}= $self->unescape_keys($v);
	}else{
	    $res->{unescape($k)}=$v;
	}
    }
    
    return $res;
};

sub checkfile {
    my $self=shift;
    my $file=shift;
    my $content=shift;

    my %opts  = ( log => $self);
    my $fh = CAF::FileWriter->new($file, %opts);
    print  $fh $content;

    return 0;
}



1;    # Required for PERL modules
