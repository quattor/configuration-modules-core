# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::ccm;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use CAF::Process;
use LC::File;
use POSIX qw(:wait_h);

local(*DTA);


##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/ccm";
    my $tfile = "/usr/lib/ncm/config/ccm/ccm.template";

    # Fill template and get results.  Template substitution is simple
    # value replacement.  If a value doesn't exist, the line is not
    # output to the file.  
    my $contents = fill_template($config, $base, $tfile);

    # Will return undefined value on an error. 
    if (!defined($contents)) {
	$self->error("error filling template $tfile");
	return 1;
    }

    # Get the configuration file name.
    my $fname;
    if ($config->elementExists("$base/configFile")) {
        $fname = $config->getValue("$base/configFile");
    } else {
	$self->error("configuration file name not specified");
	return 1;
    }

    # Create the new configuration file.
    my $rc = LC::Check::file("$fname.test", contents => $contents);
    if ($rc < 0) {
        $self->error("cannot construct $fname.test: $!");
        return 0;
    }

    # Check that ccm-fetch can work with the new file.
    my $errs = "";
    my $test = CAF::Process->new(["/usr/sbin/ccm-fetch", "-config", "$fname.test"], stderr => \$errs);
    $test->execute();
    if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
        $self->error("failed to ccm-fetch with new config: $errs");
        return 0;
    }

    # Result must have been OK.  Move the file into place.
    if (LC::File::move("$fname.test", $fname)) {
        $self->log("$fname updated");
    } else {
        $self->error("failed to install ccm config");
    }

    return 1;
}

# Do a simple template substitution.  The following tags are recognized:
#
# <%path|default%>
# <%"path|default"%>
#
# For paths which don't exist the given default value is used.  However,
# if the path doesn't exist and the default is not specified, then the
# line is not printed at all.  The only difference between the first and
# second forms is that the second will create a double-quoted string with
# any embedded double quotes properly escaped. 
#
sub fill_template {

    my ($config, $base, $template) = @_;

    my $translation = "";

    if (-e "$template") {
	open TMP, "<$template";
	while (<TMP>) {
            my $err = 0;

            # Special form for date.
            s/<%!date!%>/localtime()/eg;

            # Need quoted result (escape embedded quotes).
            s!<%"\s*(/[\w/]+)\s*(?:\|\s*(.+?))?\s*"%>!quote(fill($config,$1,$2,\$err))!eg;
            s!<%"\s*([\w]+[\w/]*)(?:\|\s*(.+?))?\s*"%>!quote(fill($config,"$base/$1",$2,\$err))!eg;

            # Normal result OK. 
            s!<%\s*(/[\w/]+)\s*(?:\|\s*(.+?))?%>!fill($config,$1,$2,\$err)!eg;
            s!<%\s*([\w]+[\w/]*)\s*(?:\|\s*(.+?))?%>!fill($config,"$base/$1",$2,\$err)!eg;

            # Add the output line unless an error was signaled.  An
            # error occurs when an element doesn't exist.  In this
            # case it is assumed that the value is optional and the
            # line is omitted.  
            $translation .= $_ unless $err;
	}
	close TMP;
    } else {
	$translation = undef;
    }

    return $translation;
}


# Escape quotes in a string value.
sub fill {
    my ($config,$path,$default,$errorRef) = @_;

    my $value = "";

    if ($config->elementExists($path)) {
        $value = $config->getValue($path);
    } elsif (defined $default) {
        $value = $default;
    } else {
        # Flag an error and return empty string.
        $$errorRef = "1";
    }
    return $value;
}


# Escape quotes and double quote the value. 
sub quote {
    my ($value) = @_;

    $value =~ s/"/\\"/g;  # escape any embedded quotes
    $value = '"'.$value.'"';
    return $value;
}

1;      # Required for PERL modules
