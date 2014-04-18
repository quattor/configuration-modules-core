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


Readonly::Array my @APPLY => qw(puppet apply --detailed-exitcodes -v -l);
Readonly::Array my @MODULE_UPGRADE => qw(puppet module upgrade);
Readonly::Array my @MODULE_INSTALL => qw(puppet module install);
Readonly::Scalar my $NODEFILES_PATH => '/etc/puppet/manifests';
Readonly::Scalar my $PUPPET_CONFIG_FILE => '/etc/puppet/puppet.conf';
Readonly::Scalar my $HIERA_CONFIG_FILE => '/etc/puppet/hiera.yaml';
Readonly::Scalar my $HIERA_DATA_FILE => '/etc/puppet/hieradata/quattor.yaml';
Readonly::Scalar my $PUPPET_LOGS => '/var/log/puppet/log';



local (*DTA);

sub Configure
{
    my ($self, $config) = @_;

    my $confighash = $config->getElement($self->prefix)->getTree();
    
    $self->tiny($confighash->{puppetconf},$PUPPET_CONFIG_FILE);
    
    $self->yaml($confighash->{hieraconf},$HIERA_CONFIG_FILE);
    
    $self->install_modules($confighash->{modules}) if(defined($confighash->{modules})); 
    
    $self->yaml($confighash->{hieradata},$HIERA_DATA_FILE) if(defined($confighash->{hieradata}));
    
    $self->nodefiles($confighash->{nodefiles});
    
    $self->apply($confighash->{nodefiles});
    
    return 0;
}

# For each "nodefiles" entry check the the content of the file (if given in the profile)
# arguments:
# $cfg: ref to the nodefiles nlist in the profile data structure
#
sub nodefiles {
    my ($self, $cfg) = @_;
 
    foreach my $file (sort keys %{$cfg}){
	if($cfg->{$file}->{contents}){
	    my $path=$NODEFILES_PATH."/".unescape($file);
	    $self->checkfile($path,$cfg->{$file}->{contents});
	}	
    }
    return 0;
}

# For each "nodefiles" entry run "puppet --apply <nodefile>"
# arguments:
# $cfg: ref to the nodefiles nlist in the profile data structure
#
sub apply {
    my ($self, $cfg) = @_;

    foreach my $file (sort keys %{$cfg}){

        my $out=CAF::Process->new([@APPLY,$PUPPET_LOGS,$NODEFILES_PATH."/".unescape($file)], log => $self)->output();
        my $exit_code=$?>>8;
	
	if (($exit_code != 0)&&($exit_code != 2)) {
	    $self->error("Apply command failed with code $exit_code. See $PUPPET_LOGS.\n");
	} else {
	    if($exit_code == 2){
		$self->info("Puppet apply performed some actions. See  $PUPPET_LOGS.\n");
	    }
	    $self->debug(1,"Apply command successfully executed. See  $PUPPET_LOGS.\n");
	}
    }
}

# Install/Updates the required puppet modules
# arguments:
# $cfg: ref to modules nlist in the profile data structure
#
sub install_modules {
    my ($self, $cfg) = @_;

    foreach my $mod (sort keys %{$cfg}){
        my $module=unescape($mod);
        my @args;
        if(defined($cfg->{$mod}->{version})){
            my $version="--version=".$cfg->{$mod}->{version};
            @args=($module,$version);
        }else{
            @args=($module);
        }


        my $out=CAF::Process->new([@MODULE_UPGRADE,@args],log => $self)->output();
        my $ok=!($?>>8);
        if (!$ok){
            $out=CAF::Process->new([@MODULE_INSTALL,@args],log => $self)->output();
            $ok=!($?>>8);
            if ($ok){
                $self->debug(1,"Module install command successfully executed. Output: $out\n");
            }else{
                $self->error("Both Upgrade and Install command failed on module $module. Output: $out\n");
            }
        }else{
            $self->debug(1,"Module upgrade command successfully executed. Output: $out\n");
        }
    }
    return 0;
}

# Create a Config::Tiny configuration file based on a hash
# arguments:
# $cfg: ref to the hash with the configuration parameters and values
# $file: file location
#
sub tiny {
    my ($self, $cfg, $file) = @_;

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

# Create a YAML file based on a hash
# arguments:
# $cfg: ref to the hash with the configuration parameters and values
# $file: file location
#
sub yaml {
    my ($self, $cfg, $file) = @_;

    $self->checkfile($file,YAML::XS::Dump($self->unescape_keys($cfg)));    

    return 0;
}

# Unescape all the hash keys of a given data structure
# Returns: reference to the unescaped data structure
# arguments:
# $cfg: reference to the data structure
#
sub unescape_keys {
    my ($self, $cfg) = @_;
    
    my $res;

    if(ref($cfg) eq ref({})){
	$res={};

	while (my ($k, $v) = each(%$cfg)) {
	
	    if((ref($v) eq ref({}))||(ref($v) eq ref([]))){
		$res->{unescape($k)}= $self->unescape_keys($v);
	    }else{
		$res->{unescape($k)}=$v;
	    }
	}
    }else{
	$res=[];

	foreach my $v (@$cfg) {
	
	    if((ref($v) eq ref({}))||(ref($v) eq ref([]))){
		push @$res, $self->unescape_keys($v);
	    }else{
		push @$res, $v;
	    }
	}
    }

    return $res;
}

# Wrapper of CAF::FileWriter. Ensure that a file has a given content
# arguments:
# $file: file location
# $content: content string
#
sub checkfile {
    my ($self, $file, $content) = @_;
 
    my %opts  = ( log => $self);
    my $fh = CAF::FileWriter->new($file, log => $self);
    print  $fh $content;

    return 0;
}

1;    # Required for PERL modules
