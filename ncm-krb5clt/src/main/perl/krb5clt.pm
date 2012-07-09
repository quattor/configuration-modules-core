# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

package NCM::Component::krb5clt;

#
# a few standard statements, mandatory for all components
#

use strict;
use LC::Check;
use NCM::Check;
use NCM::Component;
use Parse::RecDescent;
use Data::Dumper;
use NCM::Template;
use LC::Sysinfo;
use Fcntl;
use EDG::WP4::CCM::Element;

use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

my $mypath='/software/components/krb5clt';

my $configfile = '/etc/krb5.conf';
my $OSname=LC::Sysinfo::os()->name;
if ($OSname=~ /Solaris/) {
  $configfile='/etc/krb5/krb5.conf';
}

# this temporary path is referenced from the template file.
my $kdc_temp = "/var/ncm/tmp/krb5clt-cern_kdc";


#my $hash;
$main::cdb = {};
$main::out = '';


##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  if($config->elementExists($mypath."/default_realm")) {
    $self->Configure_conf_new($config);
  } else {
    $self->Configure_conf_old($config);
  }
  #*** Do not configure the firewall in Solaris
  if ($OSname=~ /Linux/) {
  	$self->Configure_firewall($config);
  }
}

##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;
  if ($OSname=~ /Linux/) {
    $self->Unconfigure_firewall($config);
  }
  return;
}


##########################################################################
sub Configure_conf_new {
##########################################################################
  my ($self,$config)=@_;
  my @weights;
  my @kdc;

  if( ! -e $configfile){
    $self->error("No $configfile file found.");
    return;
  }

  # some weird stuff to get the KDC list ordered correctly -- we will
  # write the KDCs to a (named) temp file and <INCLUDE:> that in the
  # template
  #

  if( -f $kdc_temp) {
    if(! unlink($kdc_temp)) {
      $self->error("Cannot remove previous temp file $kdc_temp: $!");
      return;
    }
  }

  if(! sysopen(KDCFILE, "$kdc_temp", O_WRONLY|O_CREAT|O_EXCL, 0600)) {
    $self->error("Cannot open temp file $kdc_temp for writing: $!");
    return;
  }

  if($config->elementExists($mypath."/cern_kdc_list")) {
    @kdc = ();
    foreach my $k ($config->getElement($mypath."/cern_kdc_list")->getList()) {
      push (@kdc, $k->getStringValue);
    }
  } else {
    # default: safeguard against "no more login for root"
    @kdc = ("afsdb1.cern.ch","afsdb2.cern.ch","afsdb3.cern.ch");
  }
  if($config->elementExists($mypath."/cern_kdc_weights")) {
    foreach my $w ($config->getElement($mypath."/cern_kdc_weights")->getList()) {
      push (@weights, $w->getValue());
    }
  }
  my @newservers = $self->semirandom_rotate_list(\@kdc, \@weights);
  print KDCFILE map("  kdc = $_\n", @newservers);
  close KDCFILE;


  # make sure nobody has overwritten our delimiters...
  my $result = $self->SetDelimiters('<', '>');
  if(! $result) {
    $self->error("cannot reset template delimiters??");
    # do not continue here, would prevent all logins
    return 0;
  }

  # actual configuration via template file
  $result = $self->Substitute($config,
				 "$configfile",
				 "krb5clt",
				 "/usr/lib/ncm/config/krb5clt/etc_krb5.conf.tpl");
  $self->error("trouble with template processing for $configfile") unless $result;

  if (unlink($kdc_temp) != 1) {
    $self->warn("cannot remove $kdc_temp: $!");
  }

}

##########################################################################
sub Configure_conf_old {
##########################################################################
  my ($self,$config)=@_;

#  if("want to debug parser")) {
#    $| =1;
#    $::RD_TRACE =1;
#    $::RD_HINT =1;
#  }

  if(! $self->init()) {
     $self->error("initialization failed");
     return 0;
  }

  $self->debug(2,"converting CDB info into hash entries");
  my $cdbhash = $self->convert_cdb_to_hash($config, $mypath);

  $main::cdb = $cdbhash->{'krb5clt'}; # export to global var for visibility in the parser

  # we will only deal with the following well-known entries
  # anything else triggers a warning.
  # List is from krb5.conf (MIT + Heimdal) man pages:
  my @allowed_entries = ('login','logging','libdefaults','realms','domain_realm',
			 'appdefaults','capaths','kdc','kadmin');
  # the following entries are (optional) standard entries as per
  # http://quattor.org/documentation/PanUserConventions.pdf
  # we don't warn for these..
  my @known_extra_entries=('active','dispatch','register_change','dependencies');

  # use precompiled regexps to speed up the match.
  my $allowed_match= '^'.join('|',@allowed_entries);
  my $known_nowarn_match = '^'.join('|',@known_extra_entries);
  for my $key (keys(%$main::cdb)) {
    next if ( $key =~ m/$allowed_match/o );
    if ( $key !~ m/$known_nowarn_match/o ) {
      $self->warn("ignoring unknown config entry $key");
    } else {
      $self->debug(3,"ignoring known_but_uninteresting config entry $key");
    }
    delete($main::cdb->{$key});
  }

  # now traverse the configuration. Validate each entry against CDB
  # hash. Update if found, throw away CDB entry. Add remaining CDB
  # entries at the end.

  # this is done by the parser grammar rules, actually.


  $self->debug(2,"reading and parsing $configfile");

  my @oldconfig;
  if (! open(FD, "<$configfile")) {
    $self->warn("will start from scratch, cannot open $configfile: $!");
  } else {
    @oldconfig = <FD>;
  }

  my $newconfig = $self->{parser}->file(join('', @oldconfig), 1, $self);

  if (!defined($newconfig)) {
    $self->error("cannot parse existing config file or create a new one");
    return 0;
  }

  unless ( $newconfig =~ /;.*ncm-krb5clt/) {
    $newconfig = "; this file partially controlled by ncm-krb5clt\n".$newconfig;
  }
  $self->debug(3, "this would be the new config file:\n".$newconfig);

  #
  # compare, overwrite if required. Would be very nice if we could
  # stick in a comment+timestamp at the top, but only if the file is
  # actually modified. Comment character is ';', btw
  #
  $self->debug(2,"writing back $configfile if required");

  return(LC::Check::file($configfile,
			 "contents"    => $newconfig
			)
	);
}


#
# initialize the parser.
#

sub init ( $ ) {
  my $self = shift;
  $self->{section} = {};
  $self->{sectionnumber} = {};
  $self->{data} = {};
  $self->{count} = 0;

  $main::out = $self; # horrible hack to use the "debug" functions.

  # this is the real magic. BNF with rules to actually implement the
  # required configuration changes, each returns the new file content.

  # the parser has it's own namespace, which makes passing in arguments
  # or calling functions a pain (tried local rule var and "my" in namespace)

  # each rule can get arguments (and is really picky about undef
  # values), we use this to pass a handle to the current entry in the
  # CDB hash. Every rule deletes elements from this hash that are
  # catered for, and some add remaining CDB config entries once the
  # parser finds nothing for the relevant subtree in the existing file.

  # rules give back in $return whatever should appear in the file if
  # the rule matches. "file" rule therefore gives new config file.

  my $grammar = q(

        file:  ( section | comment )(s?)
           {
             $return = join('',@{$item[1]});
             main::debug(3,"file: got the following from rules:\n$return");
             # anything still remaining from CDB info?
             foreach my $key (keys(%{ $main::cdb })) {
               if ( %{$main::cdb->{$key}} ) {
                  main::debug(3,"adding complete CDB section [$key]");
                  $return .= "[".$key."]\n";
                  # need to skip over the key here and go directly to the children
                  foreach my $subkey ( keys( %{ $main::cdb->{$key}} ) ) {
                      $return .= main::recursive_print_cdb($subkey, $main::cdb->{$key}->{$subkey}, 0 );
                      delete($main::cdb->{$key}->{$subkey});
                  }
               }
               main::debug(3,"applied all of $key CDB section");
               delete($main::cdb->{$key});
             }
             main::debug(3,"file: will return $return");
             1;
           }

        section: "[" /([^]]+)/ "]" body[ $item[2] && $main::cdb->{$item[2]} ? $main::cdb->{$item[2]} :'' , 1 ]
          {
            my $header = $item[2];
            my $body = $item[4];
            $return = "[".$header."]\n";
            main::debug(3,"header: subtree body is $body");
            $return .= $body;
            # add remaining CDB info, special treatment because of the uncommon 'section' syntax
            foreach my $key (keys(%{ $main::cdb->{$header}})) {
               if ( $main::cdb->{$header}->{$key} ) {
                 main::debug(3,"adding item $key from $header CDB section");
                 my $secreturn = main::recursive_print_cdb($key,
                                                           $main::cdb->{$header}->{$key}, 1);
                 $return .= $secreturn if ($secreturn);
                 main::debug(3,"throwing away $key from $header CDB section");
                 delete($main::cdb->{$header}->{$key});

               }
            };
            main::debug(3,"section: will return $return");
            1;
          }

        body:  ( subsection | pair )[ ($arg[0] ? $arg[0] : ''), $arg[1] ](s?)
           {
            $return = join('',@{$item[1]});  # this is an array ref..
            main::debug(3,"body at depth ".$arg[1].": will return $return");
            1;
           }

        pair:    /[[:alnum:][:punct:]]+/ '=' /[^{\n]+/
          {
            my $depth = $arg[1];
            my $key = $item[1];
            my $value = $item[3];
            $return = (" " x $depth) . $key." = ";
            if ($arg[0] && $arg[0]->{$key}) {
              # we have some CDB value for this, keep or update
              if ($arg[0]->{$key} ne $value) {
                 main::debug(1,"updating $key with ".$arg[0]->{$key}.", old was $value");
              } else {
                 main::debug(2,"keeping $key unchanged (is $value)");
              }
              # overwrite anyway, since we have to return something
              $return .= $arg[0]->{$key}."\n";

              # throw away CDB data.
              main::debug(3,"throwing away key to ".$arg[0]->{$key});
              delete($arg[0]->{$key});
            } else {
              # this is something not in CDB
              main::debug(2,"keeping non-CDB config $key = $value");
              $return .= $value."\n";
            }
            main::debug(3,"pair: will return $return");
            1;
          }

        subsection:    /[[:alnum:][:punct:]]+/ "=" "{"
                         body[ ($arg[0] && $arg[0]->{$item[1]} ? $arg[0]->{$item[1]} : ''), ($arg[1] + 1) ]
                       "}"
          {
            my $key = $item[1];
            my $body = $item[4];
            my $depth = $arg[1];
            $return = (" " x $depth). "$key = {\n$body";
            if ($arg[0] && $arg[0]->{$key}) {
              main::debug(3,"adding items from CDB $key subsection");
              my $subresult = main::recursive_print_cdb($key, $arg[0]->{$key}, $depth );
              $return .= $subresult if $subresult;
              main::debug(3,"throwing away key to ".$arg[0]->{$key});
              delete($arg[0]->{$key});
            }
            $return .= (" " x $depth) . "}\n";
            main::debug(3,"subsection: will return $return");
            1;
          }

         comment: /;.*/
          {
           my $comment = $item[1];
           main::debug(3,"keeping toplevel comment: $comment");
           $return = "$comment\n";
           1;
          }
        );
  $self->{parser} = new Parse::RecDescent($grammar);
  if (! $self->{parser}) {
    self->error("bad grammar for Parse::RecDescent");
    return 0;
  }
  return 1;
}


#############################################################
# convert CDB (hashed) data to the config file format.
sub main::recursive_print_cdb {
  my $key = shift;
  my $ref = shift;
  my $depth = shift;  # for prettyprinting
  my $return;
  if(ref($ref) eq 'HASH') {
    $return .= "{\n";
    foreach my $subkey (keys(%{$ref})) {
      $return .= main::recursive_print_cdb($subkey, $ref->{$subkey}, $depth + 1);
    }
    $return .= (' ' x $depth)."}\n";
  } elsif (ref($ref)) {
    die "unknown non-Hash passed to recursive_print_cdb";
  } else {
    $return .= "$ref\n";
  }

  # sometimes we get an empty tree. throw away.
  if ($return =~ m/^[ {}\n\t]*$/s ) {
    main::debug(4, "recursive_print_cdb($key) returns nothing (empty tree)");
    $return = '';
  } else {
    $return = (' ' x $depth)."$key = ".$return;
    main::debug(4, "recursive_print_cdb($key) returns\n$return");
  }
  return ($return);
}

# idiot helper function to use the 'debug()' functions from the parser.
sub main::debug( $@ ) {
  my $level = shift;
  $main::out->debug($level,@_);
}


################################################################################


# traverse CDB subtree and convert into a hash. Only works well with
# nlists.  leaf elements are either values or plain lists (will end up
# in a single entry). Special handling to overcome the deficiency of
# PAN regarding element names - work around is to use (NAME=>string,
# DATA=>nlist|string). horrors.
# gives back name,value to be added to the config hash tree

my $cdb_recurse_depth= 0;

sub convert_cdb_to_hash ( $$$ ) {

  my ($self, $config, $path) = @_;
  my $value;
  $cdb_recurse_depth++;

  $self->debug(2, (' ' x $cdb_recurse_depth ) . "cdb_to_hash start for $path");

  unless($config->elementExists($path)) {
    $self->error("cannot get configuration info for $path");
    return;
  }

  my $node = $config->getElement($path);
  my $type = $node->getType();
  my $name = $node->getName();

  if ($node->isResource()) {
    $self->debug(3,"cdb_to_hash $path isResource");

    if ($node->isType(EDG::WP4::CCM::Element::NLIST)) {

      if ($config->elementExists($path.'/NAME')) {
	# "wrapper" for elements with funny names. Ignore the bogus path name,
        #  use NAME instead for the stuff under DATA
	$name = $config->getElement($path.'/NAME')->getValue();
	$path .= '/DATA';
	$self->debug(3,"cdb_to_hash $path is NLIST with NAME=$name");

	my $tempvalue = $self->convert_cdb_to_hash($config, $path);

	$value = $tempvalue->{'DATA'}; #ignore the bogus DATA key, keep the result it points to

      } else {
	# regular NLIST: recurse

	$self->debug(3,"cdb_to_hash $path isNLIST");

	while ($node->hasNextElement()) {
	  my $next = $node->getNextElement();
	  my $nextname = $next->getName();
	  $self->debug(3,"cdb_to_hash $path going down $nextname");
	  my $nextvalue = $self->convert_cdb_to_hash($config, $path.'/'.$nextname);
	  # accumulate all subkeys into $value, cannot use $nextname since a NAME may have changed the key
	  foreach my $subkey (keys(%$nextvalue)) {
	    $value->{$subkey} = $nextvalue->{$subkey};
	  }
	}
      } # end NLISTs

    } elsif ($node->isType(EDG::WP4::CCM::Element::LIST)) {
      # LIST: accumulate elements, honor _RANDOM_WEIGHTS
      $value = $self->cdb_get_list($config, $path, $node);

    } else {
      self->error ("unexpected non-(nlist-with-NAME/nlist/list) config resource $type at $path");
      return 0;
    }
  } else {  # final element
    # workaround: ignore _RANDOM_WEIGHTS entries pertaining to some list, see above
    if ($name =~ /_RANDOM_WEIGHTS$/) {
      $self->debug(3,"ignoring key $name, belongs to some weighted list");
      return {};
    }

    $value = $node->getValue();
    $self->debug(3,"setting final $name to $value");
  }

  $self->debug(5,"convert_cdb_to_hash returning :".Dumper({$name, $value}));
  $cdb_recurse_depth--;
  return {$name, $value};
}

######################################################################
sub Configure_firewall ( $$ ) {
  my ($self,$config)=@_;

  # nothing to do for now, since default "ESTABLISHED" rule is
  # sufficient for authentication (no callback etc). Otherwise open port 88 TCP+UDP

}

sub Unconfigure_firewall ( $$ ) {
  my ($self,$config)=@_;

}

###############################
# helper function to choose correct servers

sub semirandom_rotate_list ( $$;$ ) {
  my $self = shift;
  my $servers = shift; # ref to list to rotate
  my $numservers = $#$servers;
  my $weights = shift; # optional: weight per entry

  # equal distribution if unspecified
  if (! $weights || $#$weights < 0) {
    my $j = 0;
    while ($j <= $numservers) {
      $weights->[$j++] = 1;
    }
  }
  # sum up weights
  my $total=0;
  map { $self->error("semirandom_rotate_list: negative weight $_") if ($_ < 0); $total += $_} @$weights;
  $self->debug(5,"semirandom_rotate_list: total=$total");

  # 'random' criteria: last IP octet reversed
  # this has a bias for the regions 0+delta, 128+delta for the common case
  # where we have half-empty /8 subnets
  my @ifconfig = `ifconfig 2>/dev/null`;
  my @addr = grep {(/inet addr:([\d.]+)/ && $1 ne "127.0.0.1") and $_=$1;} @ifconfig;
  $self->debug(5,"semirandom_rotate_list:addr=@addr");
  my ($a1,$a2,$a3,$thisaddr) = split('\.',$addr[0]) if ($#addr>=0);
  $thisaddr = 0 unless (defined($thisaddr) && $thisaddr); # safeguard against failing ifconfig
  $self->debug(5,"semirandom_rotate_list:thisaddr=$thisaddr");
  # reverse it (bitstring)
  my $bin = sprintf( "%08b", $thisaddr);
  $self->debug(5,"semirandom_rotate_list:bin=$bin");
  my $rev= reverse($bin);
  $self->debug(5,"semirandom_rotate_list:rev=$rev");
  my $num = oct("0b$rev");
  $self->debug(5,"semirandom_rotate_list:num=$num");

  # scale it
  my $val = $num*$total/256;
  $self->debug(5,"semirandom_rotate_list:val=$val");
  # find in histogram:

  my $sum=0;
  my $i = 0;
  for my $w (@$weights) {
    $sum += $w;
    last if ($sum > $val);
    $self->debug(5,"semirandom_rotate_list: $val not in bucket $i (<= $sum)");
    $i++;
  }

  # start server is $i
  # rearrange server list
  my @newservers;
  if ($i > 0) {
    @newservers = ( @$servers[$i .. $numservers], @$servers [0 .. $i-1]);
  } else {
    @newservers =  @$servers ;
  }
  return @newservers;
}

######
# helper function to extract lists from CDB
# add-on: reorder based on weight.

sub cdb_get_list ( $$$$ ) {
  my $self = shift;
  my $config = shift;
  my $path = shift;
  my $node = shift;

  my @elements;
  my @weights;

  if ($config->elementExists($path.'_RANDOM_WEIGHTS')) {
    my $weights = $config->getElement($path.'_RANDOM_WEIGHTS')->getValue();
    @weights = split(m/[ ,;]+/,$weights);
    $self->debug(3, "will randomize entries for $path with weights ".join(',',@weights));
  }

  while ($node->hasNextElement()) {
    my $next = $node->getNextElement();
    $self->debug(3, "cdb_get_list: looking at ".$next->getName());

    if (! $next->isProperty()) {
      # we only expect "real" elements in here
      $self->error("unexpected non-final/non-weight list element under $path");
      return 0;
    }

    # ordinary list elements
    my $nextvalue = $next->getValue();
    push(@elements, $nextvalue);
    $self->debug(3,"added $nextvalue to LIST");

  }

  if($#weights >= 0) {
    # either binary entry (1 -> equal distribution) or one per element
    if ($#weights ne $#elements && $#weights > 0) {
      $self->warn("number of weights (".$#weights.") does not match number of list entries (".$#elements.")");
    } else {
      my @newelements = $self->semirandom_rotate_list(\@elements, \@weights);
      @elements = @newelements;
    }
  }
  return join(' ',@elements);
}

# good return code. keep perl happy.
1;

### Local Variables: ///
### mode: perl ///
### End: ///
