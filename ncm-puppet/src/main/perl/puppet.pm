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

Readonly::Scalar my $MODULE_UPGRADE => 'puppet module upgrade %s %s';
Readonly::Scalar my $MODULE_INSTALL => 'puppet module install %s %s';
Readonly::Scalar my $NODEFILES_PATH => '/etc/puppet/manifests';
Readonly::Scalar my $PUPPET_CONFIG_FILE => '/etc/puppet/puppet.conf';
Readonly::Scalar my $HIERA_CONFIG_FILE => '/etc/puppet/hiera.yaml';
Readonly::Scalar my $HIERA_DATA_FILE => '/etc/puppet/hieradata/quattor.yaml';
Readonly::Scalar my $APPLY => 'puppet apply --detailed-exitcodes -v -l /var/log/puppet/log %s;';

local (*DTA);

sub Configure
{
    my ($self, $config) = @_;

    my $confighash = $config->getElement($self->prefix)->getTree();
    
    $self->tiny($confighash->{puppetconf},$PUPPET_CONFIG_FILE);
    
    $self->yaml($confighash->{hieraconf},$HIERA_CONFIG_FILE);
    
    $self->install_modules($confighash) if(defined($confighash->{modules})); 
    
    $self->yaml($confighash->{hieradata},$HIERA_DATA_FILE) if(defined($confighash->{hieradata}));
    
    $self->nodefiles($confighash->{nodefiles});
    
    $self->apply($confighash);
    
    return 0;
}

# For each "nodefiles" entry check the the content of the file (if given in the profile)
# arguments:
# $confighash: ref to the hash with the profile data structure
#
sub nodefiles {
    my ($self, $confighash) = @_;
 
    foreach my $file (sort keys %{$confighash}){
	if($confighash->{$file}->{contents}){
	    my $path=$NODEFILES_PATH."/".unescape($file);
	    $self->checkfile($path,$confighash->{$file}->{contents});
	}
	
    }
    return 0;
}

# For each "nodefiles" entry run "puppet --apply <nodefile>"
# arguments:
# $confighash: ref to the hash with the profile data structure
#
sub apply {
    my ($self, $confighash) = @_;

    foreach my $file (sort keys %{$confighash->{nodefiles}}){

	my ($exit_code,$output)=$self->cmd_exec(sprintf($APPLY,$NODEFILES_PATH."/".unescape($file)));
	
	if ( ($exit_code != 0) && ($exit_code != 2)) {
	    $self->error("Apply command failed. Output: $output\n");
	} else {
	    $self->debug(1,"Apply command successfully executed. Output: $output\n");
	}
    }
}

# Install/Updates the required puppet modules
# arguments:
# $confighash: ref to the hash with the profile data structure
#
sub install_modules {
    my ($self, $confighash) = @_;

    foreach my $mod (sort keys %{$confighash->{modules}}){
	my $module=unescape($mod);
	my $version='';
	if(defined($confighash->{modules}->{$mod}->{version})){
	    $version="--version=".$confighash->{modules}->{$mod}->{version};
	}

	my ($exit_code,$output)= $self->cmd_exec(sprintf($MODULE_UPGRADE,$module,$version));
	if ( $exit_code != 0){
	    ($exit_code,$output)= $self->cmd_exec(sprintf($MODULE_INSTALL,$module,$version));
	    if ( $exit_code != 0){
		$self->debug(1,"Install upgrade command successfully executed. Output: $output\n");
	    }else{
		$self->error("Both Upgrade and Install command failed on module $module. Output: $output\n");
	    }
	}else{
	    $self->debug(1,"Module upgrade command successfully executed. Output: $output\n");
	}	
    }
    return 0;
}

# Wrapper of CAF::Process: execute a shell command line.
# Returns the array (EXIT_CODE,OUTPUT_STRING)
# arguments:
# $cl: command line string
#
sub cmd_exec {
    my ($self, $cl) = @_;

    my $cmd_output;

    my $cmd = CAF::Process->new([$cl], log => $self,
                                shell => 1,
                                stdout => \$cmd_output,
				stderr => "stdout");
    $cmd->execute();

#    if ( $? ) {
#	$self->error("Command failed. Command output: $cmd_output\n");
#    } else {
#	$self->debug(1,"Command output: $cmd_output\n");
#    }

    return ($?,$cmd_output);
    
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
# arguments:
# $cfg: reference to the data structure
#
sub unescape_keys {
    my ($self, $cfg) = @_;
 
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
