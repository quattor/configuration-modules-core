# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

#*** Modified and commented by Juan Antonio Lopez Perez <Juan.Lopez.Perez@cern.ch>
#*** Modifications and comments begin by "#***"


package NCM::Component::etcservices;
#
# a few standard statements, mandatory for all components
#

use strict;        #*** This give warnings when non-defined variables are found
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

#***######################################################################
sub escape ($) {
#***######################################################################
#***   This sub just puts a "\" before the characters .,^,$,*,+ and ? 
#*** in the given string. We will get the following error if one of those 
#*** characters are found without the "\": "Nested quantifiers in regex".

  my $str=shift;

  $str =~ s!(\.|\^|\$|\*|\+|\?)!\\$1!g;
  return $str;
}


##########################################################################
sub Configure($$) {
##########################################################################
#***    This sub compares the file /etc/services with the Quattor CDB
#*** and makes sure that all the lines in the CDB are also in the file,
#*** adding them if necessary. It also checks if the line exist but is 
#*** commented (then it is uncommented) and if it has comments at the end
#*** or not (then, the comments at the CDB line are added).
#***    We must take into account that /etc/services is just a link to
#*** /etc/inet/services so the one we should modify is that one.

  my ($self,$config)=@_;

  $self->info("this component configures /etc/services");
  my $path;

  # get automounter files
  $path='/software/components/etcservices/entries';
  my $etcservices_entries=$config->getElement($path);

  #***    In that $etcservices_entries will be stored the Quattor CDB lines
  #*** that we will compare with the /etc/services ones.

  unless (defined $etcservices_entries) {
    $EC->ignore_error();
    $self->error('cannot access config path: '.$path);
    return undef;
  } 
  #read the file

  my $need2modify=0;
  my $file="/etc/services";
  my @lines;
  unless ($NoAction) {
    unless(open(SERV,"$file")) {
      $self->error ("cannot open $file");
      return;
    } 
    @lines = <SERV>;
    unless(close(SERV)) {
      $self->error("cannot close $file");
      return;
    }
  }
  #read the entries to be checked
  my ($entry, $entry_value, $line);
  my ($found1, $found2, $csf, $nl);

  #*** Here we are going to compare each $entry_value containing each involved Quattor CDB
  #*** line with all the /etc/services lines. 
  #***    After all the modifications, the variable $line is $entry_value in which 
  #***        we have put a "\" before the characters .,^,$,*,+,? and 
  #***        we have substituted the white spaces by "(\s*)", even in the comments.
  #***    $csf contains the same as $line but without the possible comments at the end.

  while ($etcservices_entries->hasNextElement()) {
    $entry=$etcservices_entries->getNextElement();
    $entry_value = $entry->getValue();
    $line =  $entry_value;
    $csf = "$1 $2" if ($line =~ /(\S+)\s+(\S+)/);
    $csf=&escape($csf);
    $csf =~ s/(\s+)/(\\s\*)/g;
    $line=&escape($line);
    $line =~ s/(\s+)/(\\s\*)/g;
    $nl=0;
    $found1=0; $found2=0;

    #***   CASE 1
    #***   If we found a commented line at /etc/services, i.e. beginning with "#", 
    #*** and it is equal to the one in the CDB with which we are comparing then 
    #*** we take the comment character out provided that the line at the 
    #*** CDB is not commented.

    foreach (@lines) {
      $lines[$nl] =~ s/\#// and $found1=1 and $need2modify++ if (/^\#$line/); 
      $found1=1 if (/^$line/);
      $found2=1 if (/^$csf/);
      $nl++;
    }
    $nl=0;

    #***    CASE 2
    #***    If we did NOT find the whole CDB line (don't mind if equal or commented)
    #*** BUT we found that line without the comments at the end (as we have at $csf)
    #*** THEN we change the whole line (except the \n or "new line" character) 
    #*** by the one stored at the CDB, i.e. we add that final comment.

    if (! $found1 && $found2) {
      foreach (@lines) {
        $lines[$nl] =~ s/.*/$entry_value/ and $found1=1 and $need2modify++ if (/^$csf/); 
        $nl++;
      }
    }

    #***    CASE 3 (Added by Juan Lopez)
    #***    In other cases (i.e. we have not found the current CDB entry at /etc/services 
    #*** equal, commented, with or without the final comments) we must also check if 
    #*** the port given at the CDB is different and correct it if necessary.

    #    We place here the first and second words of the current CDB line, i.e. the name 
    # of the service and the related port:
    my $first_cdb_word="$1" if ($entry_value =~ /^(\S+)\s+(\S+)/);
    my $second_cdb_word="$2" if ($entry_value =~ /^(\S+)\s+(\S+)/);
    # $third_cdb_word matches the protocol part of the entry (udp or tcp).  This
    # avoids the code below erroneously replacing the tcp with udp entries, and
    # vice-versa. - 2010-07-06, James Thorne <james.thorne@stfc.ac.uk>
    my $third_cdb_word="$3" if ($entry_value =~ /^(\S+)\s+(\S+)\/(\S+)/);

    $nl=0;

    if (! $found1) {
      foreach (@lines) {

         # And here the ones we are checking at the current /etc/services line:
         my $first_etc_word="$1" if ($lines[$nl] =~ /^(\S+)\s+(\S+)/);
         my $second_etc_word="$2" if ($lines[$nl] =~ /^(\S+)\s+(\S+)/);
	 # $third_etc_word matches the protocol part of the /etc/services line
	 # (udp or tcp) for the same reasons as $third_cdb_word above
	 # - 2010-07-06, James Thorne <james.thorne@stfc.ac.uk>
	 my $third_etc_word="$3" if ($lines[$nl] =~ /^(\S+)\s+(\S+)\/(\S+)/);

	 #    Sometimes the lines are empty so those variables will not be initialised
	 # and we will got an error. We avoid that with the following:
	 # $third_*_word added by James Thorne, 2010-07-06
	 if ((defined $first_cdb_word) and (defined $second_cdb_word) and (defined $third_cdb_word) and
	     (defined $first_etc_word) and (defined $second_etc_word) and (defined $third_etc_word)) {

            # If the port has changed we replace the /etc/services line by the CDB one
	    # We also check that we are doing this for the correct protocol with:
            # ($third_cdb_word eq $third_etc_word)
	    # - 2010-07-06, James Thorne <james.thorne@stfc.ac.uk>
	    if (($first_cdb_word eq $first_etc_word) and
	        ($third_cdb_word eq $third_etc_word) and
                ($second_cdb_word ne $second_etc_word)) {

	       $lines[$nl] =~ s/.*/$entry_value/;
	       $found1=1;
	       $need2modify++; 
	   }
	}
      $nl++;
      }
    }

    #***    ANY OTHER CASE
    #***    In any other case (i.e. if we didn't found the CDB line at /etc/services
    #*** as is, commented, with or without the final comment or with the port changed
    #*** and corrected) then we just add the line stored at the CDB.
    #***    Notice that also in case 2 and 3 we set $found1=1 if a modification have
    #*** been done.

    push (@lines, $entry_value) and $need2modify++ unless ($found1);
  }
  # write the file if there are some modifications
  if ($need2modify) {
    unless(open(SERV,">$file.$$")) {
      $self->error ("cannot open $file.$$");
      return;
    }
    foreach $_ (@lines) {
      chomp;
      print SERV "$_\n";
    }
    unless(close(SERV)) {
      $self->error("cannot close $file.$$");
      return;
    }
    unless (rename ("$file.$$",$file)) {
      $self->error("cannot rename temporary $file.$$ to $file");
      return;
    }
  }

  #*** Eliminate duplicate lines, if any
  system("sort -u /etc/services -o /etc/services");

}

1; # Perl module requirement.


