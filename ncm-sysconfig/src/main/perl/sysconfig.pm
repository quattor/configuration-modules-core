#${PMcomponent}

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use LC::Check;

use File::Path;
use File::Basename;


sub Configure
{

  my ($self, $config) = @_;

  # Define paths for convenience.
  my $base = "/software/components/sysconfig";

  # The base directory for sysconfig files.
  my $sysconfigdir = "/etc/sysconfig";

  # Load configuration into a hash
  my $sysconfig_config = $config->getElement($base)->getTree();

  # Ensure that sysconfig directory exists.
  mkpath($sysconfigdir,0,0755) unless (-e $sysconfigdir);
  if (! -d $sysconfigdir) {
      $self->error("$sysconfigdir isn't a directory or can't be created");
      return 1;
  }

  # This will be a list of the configuration files managed by this component.
  my %newcfg;

  # Read first the list of sysconfig files which have been
  # previously managed by this component.  These will have to
  # be deleted if no longer in the configuration.
  my %oldcfg;
  if (-f "$sysconfigdir/ncm-sysconfig") {
      open CONF, "<", "$sysconfigdir/ncm-sysconfig";
      while (<CONF>) {
          chomp;
          $oldcfg{$_} = 1;
      }
  }

  # Loop over all of the defined files, writing each as necessary.
  if ( $sysconfig_config->{files} ) {
      for my $file (sort keys %{$sysconfig_config->{files}}) {

          my $pairs = $sysconfig_config->{files}->{$file};

          # Start with an empty file.
          my $contents = '';

          # Add the prologue if it exists.
          if (defined($pairs->{"prologue"})) {
              $contents .= $pairs->{"prologue"} . "\n";
          }

          # Loop over the pairs adding the information to the file.
          for my $key (sort keys %{$pairs}) {
              if ($key ne 'prologue' && $key ne 'epilogue') {
                  $contents .= $key . '=' . $pairs->{$key} . "\n";
              }
          }

          # Add the epilogue if it exists.
          if (defined($pairs->{"epilogue"})) {
              $contents .= $pairs->{"epilogue"} . "\n";
          }

          # Now actually update the file, if needed.

          my $result = LC::Check::file("$sysconfigdir/$file",
                                       backup => ".old",
                                       contents => $contents,
              );
          unless ( $result >= 0 ) {
              $self->error("Error updating file $sysconfigdir/$file");
          }

          # Remove this file from the list of old configuration
          # files add to the new configuration files.
          delete($oldcfg{"$sysconfigdir/$file"});
          $newcfg{"$sysconfigdir/$file"} = 1;
      }
  }

  # Remove any old configuration files which haven't been updated.
  for my $file (keys %oldcfg) {
      unlink $file if (-e $file);
  }

  # Write the list of managed configuration files.
  if(open CONF, ">", "$sysconfigdir/ncm-sysconfig") {
      for my $file (keys %newcfg) {
          print CONF $file . "\n";
      }
      close CONF;
  } else {
      $self->error("error writing file $sysconfigdir/ncm-sysconfig");
      return 1;
  }

  return 0;
}

1;      # Required for PERL modules
