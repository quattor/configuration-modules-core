# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# NCM component for symlink daemon
#
#
# ** Generated file : do not edit **
#
#######################################################################

package NCM::Component::symlink;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use EDG::WP4::CCM::Element;

use File::Path;
use File::Copy;
use File::Basename;
use File::stat;

local(*DTA);

my %context_vars;
my $exists_def = 0;
my %replace_opts_def = (
    "dir", 0,
    "dirempty", 0,
    "file", 0,
    "link", 0,
    );
my %replace_bck_ext_def;
my $saved_ext_def = undef;
my $saved_dir_ext_def = ".ncm-symlink_saved";
# order of @valid_replace_opts determine option precedence
my @valid_replace_opts = ("all", "none", "dir", "dirempty", "file", "link");

my $true = 1;
my $false = 0;
my $ambiguous = -1;    # Special value to indicate that this is neither true, nor false...

##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;
    my $base = $self->prefix();

    # If the list of links exists, actually do something!
    if ($config->elementExists("$base/links")) {

        # Retrieve global options
        if ($config->elementExists("$base/options")) {
            $self->process_global_options($config);
        }

        # Retrieve contextual variables
        if ($config->elementExists("$base/context")) {
            my @vars = $config->getElement("$base/context")->getList();
            foreach my $element (@vars) {
                my %hash = $element->getHash();
                my $rc = $self->process_vars(\%hash);
            }
        }

        # Get the list of path entries; should be a list.
        my $link_definition_path = "$base/links";
        my %links;
        if ($config->elementExists($link_definition_path)) {
            my $links = $config->getElement($link_definition_path);
            while ( $links->hasNextElement() ) {
                my %link_options = $links->getNextElement()->getHash();
                my $link_name = $link_options{name}->getValue();
                
                if ( exists($links{$link_name}) ) {
                    $self->debug(1,"Link $link_name already defined. Replacing previous definition...");
                }
                $links{$link_name} = \%link_options;
            }

            foreach my $link (keys(%links)) {
                my $rc = $self->process_link($link,$links{$link});
            }
        }
    }

    return 1;
}

# The C<expand_cmds> function interprets all substrings that start and end with 
# C<@@> as a command, and expands the C<value> with the respecitive output.
sub expand_cmds {

    my ($self, $value) = @_;
    my @toks = split /@@/, $value;
    my $newval = "";

    my $i = 0;
    while ( $i < @toks ) {
        $newval = join "", $newval, $toks[$i];
        $i++;
        if ( $i < @toks ) {
            my $expanded_tok = qx/$toks[$i]/;
            chomp $expanded_tok;
            $newval = join "", $newval, $expanded_tok;
            $i++;
        }    
    }

    return $newval;
}


# The C<expand_vars> function interprets all substrings that start with C<{> and end with 
# C<}> as a variable in the global C<context_vars> environment, and expands the C<value> 
# with the resp value.
sub expand_vars {

    my ($self, $value) = @_;
    (my $newval, my @toks) = split /\{/, $value;

    for my $tok (@toks) {
        if ( index($tok,'}') == -1 ) {
            $self->error("syntax error in value '$value' : missing closing }");
            return undef;
        }
        (my $var_name, my $literal) = split /\}/, $tok;
        if ( ! exists($context_vars{$var_name}) ) {
            $self->error("contextual variable '$var_name' not defined");
            return undef;
        }
        $newval = join "", $newval, $context_vars{$var_name}, $literal;
    }

    return $newval;
}

# Ambigous argument value causes a specific value to be returned, interpreted
# as true. Used by some specific options like replace.
sub getPanBoolean {

    my ($self, $value) = @_;

    if ( ($value =~ /true/i ) || ($value =~ /yes/i ) ) {
        return $true;
    } elsif ( ($value =~ /false/i ) || ($value =~ /no/i ) ) {
        return $false;
    } else {
        return $ambiguous;
    }

}


sub process_vars {

    my ($self, $href) = @_;
    my %record = %$href;

    # Pull out the variable name and check that it really is defined. 
    my $name;
    if (exists($record{name})) {
        $name = $record{name}->getValue();
    } else {
        $self->error("contextual variable entry with undefined name");
        return 0;
    }

    # Pull out the variable value and check that it really is defined. 
    my $value;
    if (exists($record{value})) {
        $value = $record{value}->getValue();
    } else {
        $self->error("contextual variable entry ($name) with undefined value");
        return 0;
    }

    $value = $self->expand_cmds($value);
    if ( !defined($value) ) {
        return 0;
    }

    $context_vars{$name} = $value;

    return 1;

}


sub process_global_options {

    my ($self, $config) = @_;
    my $base = $self->prefix();

    if ( $config->elementExists("$base/options/exists") ) {
        $exists_def = $self->getPanBoolean($config->getElement("$base/options/exists")->getValue());
    }

    if ( $config->elementExists("$base/options/savedext") ) {
        $saved_ext_def = $config->getElement("$base/options/savedext")->getValue();
    }

    # Initialize each file type backup extension to default
    # in case the option is enabled later in link specific options.
    # Default is undef in which case existing file/link will not be renamed,
    # except for a non empty dir that should always be renamed.

    for my $opt (@valid_replace_opts) {
        if ( $opt eq "dir" ) {
            $replace_bck_ext_def{$opt} = $saved_dir_ext_def;
        } else {
            $replace_bck_ext_def{$opt} = $saved_ext_def;
        }
    }

    if ( $config->elementExists("$base/options/replace") ) {
        for my $opt (@valid_replace_opts) {
            next if ! $config->elementExists("$base/options/replace/$opt");
            my $opt_val = $config->getElement("$base/options/replace/$opt")->getValue();
            my $opt_saved_ext = $saved_ext_def;
            my $opt_enabled = $self->getPanBoolean($opt_val);
            # if value is an extension, interpreted as true
            if ( $opt_enabled && ($opt_enabled != $true) ) {
                $opt_saved_ext = $opt_val;
                $opt_enabled = 1;
            }

            $self->debug(1,"global replace option name=$opt, enabled=$opt_enabled, value=$opt_val");

            if ( $opt eq "none" ) {
                if ( $opt_enabled ) {
                    for my $key (keys(%replace_opts_def)) {
                        $replace_opts_def{$key} = 0;
                        $self->debug(1,"global option for $key replacement disabled");
                    }
                }
            } elsif ( $opt eq "all" ) {
                if ( $opt_enabled ) {
                    for my $key (keys(%replace_opts_def)) {
                        $replace_opts_def{$key} = 1;
                        # Following condition means that a backup extension has been provided
                        if ( $opt_enabled != $true ) {
                            $replace_bck_ext_def{$key} = $opt_saved_ext;
                        }
                        $self->debug(1, "global option for $key replacement enabled, ".(defined($replace_bck_ext_def{$key})?"bck ext=".$replace_bck_ext_def{$key}:"no backup"));
                    }
                }
            } else {
                if ( exists($replace_opts_def{$opt}) ) {
                    if ( $opt_enabled ) {
                        $replace_opts_def{$opt} = 1;
                        # Following condition means that a backup extension has been provided
                        if ( $opt_enabled != $true ) {
                            $replace_bck_ext_def{$opt} = $opt_saved_ext;
                        }
                        $self->debug(1,"global option for $opt replacement enabled, ".(defined($replace_bck_ext_def{$opt})?"bck ext=".$replace_bck_ext_def{$opt}:"no backup"));
                        # If directory replacement is enabled, enable also empty
                        # directory replacement
                        if ( $opt eq "dir" ) {
                            $replace_opts_def{dirempty} = 1;
                            if ( ! defined($replace_bck_ext_def{dirempty}) ) {
                                $replace_bck_ext_def{dirempty} = $replace_bck_ext_def{$opt};
                            }
                            $self->debug(1,"global option for dirempty replacement enabled, ".(defined($replace_bck_ext_def{dirempty})?"bck ext=".$replace_bck_ext_def{dirempty}:"no backup"));
                        }
                    } else {
                        # If empty directory replacement is disabled, disable also non empty
                        # directory replacement
                        if ( $opt eq "dirempty" ) {
                          $replace_opts_def{dir} = 0;
                        }
                        $replace_opts_def{$opt} = 0;
                        $self->debug(1,"global option for $opt replacement disabled");
                    }
                } else {
                    $self->error("Invalid replacement options ignored ($opt)");
                }
            }
        }
    }

}


sub process_link {

    my ($self, $link, $href) = @_;
    my %record = %$href;

    # Pull out the values and check that they really are defined. 

    # 'exists' flag : for create, target must exist; for delete, link must exist
    my $exists_flag = $exists_def;
    if (exists($record{exists})) {
        $exists_flag = $self->getPanBoolean($record{exists}->getValue());
    }

    # Delete rather than create

    my $delete_flag = 0;        # Default is false
    if (exists($record{delete})) {
        $delete_flag = $self->getPanBoolean($record{delete}->getValue());
    }
    if ( $delete_flag ) {
        if ( -l $link ) {
            my $status = unlink $link;
            if ( $status == 1 ) {
                $self->OK("symlink $link deleted");
            } else {
                $self->error("error deleting symlink $link");
                return 0;
            }
        } elsif ( $exists_flag ) {
            $self->error("error deleting symlink $link : symlink doesn't exist");
        }


    } else {    # Create

        # Link target : expand variables / shell expressions

        my $target;
        if (exists($record{target})) {
            $target = $record{target}->getValue();
        } else {
            $self->error("link entry ($link) with undefined target");
            return 0;
        }

        $target = $self->expand_vars($target);
        if ( !defined($target) ) {
            return 0;
        }
        $target = $self->expand_cmds($target);
        if ( ! defined($target) ) {
            return 0;
        }

        if ($target =~ /^([ &:#-\@\w.]+)$/) {
            $target = $1; #data is now untainted
        } else {
            $self->error("Invalid character(s) in target $target.");
            return 0;
        }

        # 'replace' flag : define existing file type that can be replaced

        # First copy global defaults

        my %replace_opts;
        my %replace_bck_ext;
        for my $key (keys(%replace_opts_def)) {
            $replace_opts{$key} = $replace_opts_def{$key};
        }

        # Process link specific replacement options

        if ( exists($record{replace}) ) {
            my %replace_params = $record{replace}->getHash();
            for my $opt (@valid_replace_opts) {
                next if ! exists($replace_params{$opt});
                my $opt_val = $replace_params{$opt}->getValue();
                my $opt_saved_ext;
                my $opt_enabled = $self->getPanBoolean($opt_val);
        
                $self->debug(1,"link replace option name=$opt, enabled=$opt_enabled, value=$opt_val");
        
                if ( $opt eq "none" ) {
                    if ( $opt_enabled ) {
                        for my $key (keys(%replace_opts)) {
                          $replace_opts{$key} = 0;
                          $self->debug(1,"replacement for $key disabled");
                        }
                    }
                } elsif ( $opt eq "all" ) {
                    if ( $opt_enabled ) {
                        for my $key (keys(%replace_opts)) {
                            $replace_opts{$key} = 1;
                            # $opt_val can contain an extension, interpreted as true
                            if ( $opt_enabled != $true ) {
                                $replace_bck_ext{$key} = $opt_val;
                            } else {
                                $replace_bck_ext{$key} = $replace_bck_ext_def{$key};
                            }
                            $self->debug(1,"replacement for $key enabled, ".(defined($replace_bck_ext{$key})?"bck ext=".$replace_bck_ext{$key}:"no backup"));
                        }
                    }
                } else {
                    if ( exists($replace_opts{$opt}) ) {
                        if ( $opt_enabled ) {
                            # If directory replacement is enabled, enable also empty
                            # directory replacement
                            if ( $opt eq "dir" ) {
                                $replace_opts{dirempty} = 1;
                            }
                            $replace_opts{$opt} = 1;
                            # $opt_val can contain an extension, interpreted as true
                            if ( $opt_enabled != $true ) {
                                $replace_bck_ext{$opt} = $opt_val;
                            } else {
                                $replace_bck_ext{$opt} = $replace_bck_ext_def{$opt};
                            }
                            $self->debug(1,"replacement for $opt enabled, ".(defined($replace_bck_ext{$opt})?"bck ext=".$replace_bck_ext{$opt}:"no backup"));
                            # If directory replacement is enabled, enable also empty
                            # directory replacement
                            if ( $opt eq "dir" ) {
                                $replace_opts{dirempty} = 1;
                                if ( ! defined($replace_bck_ext{dirempty}) ) {
                                    $replace_bck_ext{dirempty} = $replace_bck_ext{$opt};
                                }
                                $self->debug(1,"global option for dirempty replacement enabled, ".(defined($replace_bck_ext_def{dirempty})?"bck ext=".$replace_bck_ext_def{dirempty}:"no backup"));
                            }
                        } else {
                            # If empty directory replacement is disabled, disable also non empty
                            # directory replacement
                            if ( $opt eq "dirempty" ) {
                                $replace_opts{dir} = 0;
                            }
                            $replace_opts{$opt} = 0;
                            $self->debug(1,"replacement for $opt disabled");
                        }
        
                    } else {
                        $self->error("Internal error : invalid replacement options ignored ($opt)");
                    }
                }
            }
        }
    
        # Use global/default backup extension if none defined
        for my $key (keys(%replace_bck_ext_def)) {
            unless ( exists($replace_bck_ext{$key}) && defined($replace_bck_ext{$key}) ) {
                $replace_bck_ext{$key} = $replace_bck_ext_def{$key};
            }
        }

        # 'exists' flag : target must exist

        my $bck_ext = undef;

        if ( $exists_flag && ! -e $target ) {
            $self->error("link target ($target) doesn't exist");
            return 0;
        }

        if ( -l $link ) {
            unless ( $replace_opts{link} ) {
                $self->error("link $link already exists and replacement is not allowed");
                return 0;
            }
            $bck_ext = $replace_bck_ext{link};
        } elsif ( -d $link ) {
            unless ( $replace_opts{dir} || $replace_opts{dirempty} ) {
                $self->error("$link already exists as a directory and replacement is not allowed");
                return 0;
            }
            my $dir_empty = stat($link)->size == 0;
            if ( ! $dir_empty ) {
                if ( ! $replace_opts{dir} ) {
                    $self->error("$link already exists as a non empty directory and replacement allowed only for empty directories");
                    return 0;
                } else {
                    $bck_ext = $replace_bck_ext{dir};
                }
            } else {
                $bck_ext = $replace_bck_ext{dirempty};
            }
        } elsif ( -e $link ) {
            unless ( $replace_opts{file} ) {
                $self->error("$link already exists but is not a symlink and replacement is not allowed");
                return 0;
            }
            $bck_ext = $replace_bck_ext{file};
        }

        if ( -l $link || -e $link ) {
            my $status;
            my $operation;
            if ( defined($bck_ext) ) {
                $self->debug(1,"Renaming $link to $link$bck_ext");
                $operation = "renaming";
                $status = rename $link, "$link$bck_ext";
            } else {
                $self->debug(1,"Removing $link");
                $operation = "deleting";
                if ( -d $link && ! -l $link ) {
                    $status = rmdir $link;
                } else {
                    $status = unlink $link;
                }
            }
            unless ( $status == 1 ) {
                $self->error("Error $operation $link. Link not defined.");
                return 0;
            }
        }

        my $link_parent = dirname($link);
        if ( ! -d $link_parent ){
            eval (mkpath($link_parent));
            if ( $@ ) {
                $self->error("Error creating link $link parent directory ($@)");
                return 0;
            } else {
                $self->debug(1,"Link $ link parent directory created");
            }
        }

        my $status = symlink $target, $link;
        if ( $status == 1 ) {
            $self->OK("symlink $link defined as $target");
        } else {
            $self->error("error defining symlink $link as $target");
            return 0;
        }

    }

    return 1;
}


1;      # Required for PERL modules
