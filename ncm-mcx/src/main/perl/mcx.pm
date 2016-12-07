# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# NCM component for mcx on darwin
#
#
# ** Generated file : do not edit **
#
#######################################################################

package NCM::Component::mcx;


#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use LC::Check;
use CAF::Process;
use EDG::WP4::CCM::Element qw(STRING LONG DOUBLE BOOLEAN LIST NLIST);
use EDG::WP4::CCM::Path qw(unescape);
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

our $dscl = "/usr/bin/dscl";

sub Configure {
    my ($self, $config) = @_;
    my $cfgpath = $self->prefix;
    my $node = $config->getElement("$cfgpath/node")->getValue();
    my $dir = "/var/db/dslocal/nodes/$node";
    $self->{_dscl_node} = "/Local/$node";

    # Construct the framework for our local directory
    LC::Check::directory($dir); # an exception here will be sufficient, we don't check
    # Lion requires 'users' and 'computers'
    LC::Check::directory("$dir/users");
    LC::Check::directory("$dir/groups");

    # Ensure that any local MCX settings will be used by the directory server
    # Finer-grained control can be achieved by using the localdirectory component
    # At this point, the local node may not exist, so we can't use the 'dscl()' method
    # however once we've ensured that the local node is good, we can switch into
    # simpler $self->dscl() calls...
    my $proc = CAF::Process->new([$dscl, qw{/Search -read / CSPSearchPath}], log => $self);
    my $output = $proc->output;
    my ($search) = ($output =~ m{:\s+(.*)$});
    my @searchpaths = split(/\s+/, $search);
    if (!grep { $_ eq "/Local/$node" } @searchpaths) {
        $self->verbose("local search path for $node is missing (currently $search)");
        # We may have just created the directory and so opendirectory may not know about it
        # kill opendirectoryd; sleep 1s
        my $proc = CAF::Process->new([$dscl, qw{/Search -create / CSPSearchPath}], log => $self);
        $proc->pushargs(@searchpaths, "/Local/$node");
        my $out = $proc->output;
    }


    # And now run through the groups defined in our config, creating plists as we go
    if ($config->elementExists("$cfgpath/computer")) {
        LC::Check::directory("$dir/computer");
        # Check that the computer node exists
        my $object = $config->getElement("$cfgpath/computer/RealName")->getValue;
        my $existing = $self->dscl("-read /Computers/$object");
        if ($? >> 8) {
            my $mac = $config->getElement("$cfgpath/computer/ENetAddress")->getValue();
            return 0 unless $self->create_host($node, $object, $mac);
        }

        # Now process the MCX data
        my $mcx = $config->getElement("$cfgpath/computer/apps");
        my $plist = $self->element_to_plist($mcx);
        my $body = '<?xml version="1.0" encoding="UTF-8"?>';
        $body .= '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">';
        $body .= '<plist version "1.0">' . $plist . '</plist>';

        my $file = "$dir/computers/$object.plist.ncm";
        my $result = LC::Check::file($file,
            contents => $body,
            owner => 'root',
            mode  => '0444',
        );
        if ($result) {
            $self->log("updated computer properties for $object ($file)");
            # XXX: Bug? this is an incremental add, it does not delete the old values. Perhaps we want
            # to run mcxexport -o $export; mcximport -d $export ; mcximport $newfile.
            my $output = $self->dscl("-mcximport /Computers/$object $file");
            if ($? >> 8) {
                $self->error("failed to import MCX data: $output");
            }
        }
    }
    return 1;
}

sub dscl {
    my ($self, $string) = @_;
    my $command = [];
    if (ref $string) {
        $command = $string;
    } else {
        $command = [ split(/ +/, $string) ];
    }
    my $proc = CAF::Process->new([$dscl, $self->{_dscl_node}, @$command], log => $self);
    return $proc->output;
}

sub create_host {
    my ($self, $node, $object, $mac) = @_;

    my $out = $self->dscl("-create /Computers/$object");
    if ($? >> 8) {
        $self->error("failed to create computer node: $out");
        return 0;
    }

    $out = $self->dscl("-create /Computers/$object RealName $object");
    if ($? >> 8) {
        $self->error("failed to set name of computer node: $out");
        return 0;
    }

    # XXX: it would be nice to do this more internally, rather than
    # relying on external program?
    my $proc = CAF::Process->new(["/usr/bin/uuidgen"]);
    my $uuid = $proc->output;
    if ($? >> 8) {
        $self->error("failed to get uuid: $uuid");
        return 0;
    }
    $out = $self->dscl("-create /Computers/$object GeneratedUID $uuid");
    if ($? >> 8) {
        $self->error("failed to set uid of computer node: $out");
        return 0;
    }
    $out = $self->dscl("-create /Computers/$object ENetAddress $mac");
    if ($? >> 8) {
        $self->error("failed to set MAC of computer node: $out");
        return 0;
    }
    return 1;
}


sub element_to_plist {
    my ($self, $obj) = @_;
    if ($obj->isType(BOOLEAN)) {
        if ($obj->getValue eq 'true') {
            return '<true/>';
        } else {
            return '<false/>';
        }
    }

    if ($obj->isType(LONG)) {
        return "<integer>" . $obj->getValue . "</integer>";
    }

    if ($obj->isType(DOUBLE)) {
        return "<real>" . $obj->getValue . "</real>";
    }

    if ($obj->isType(STRING)) {
        if ($obj->getValue) {
            return "<string>" . $obj->getValue . "</string>";
        } else {
            return "<string/>";
        }
    }

    if ($obj->isType(NLIST)) {
        my $ret = "";
        while ($obj->hasNextElement) {
            my $el = $obj->getNextElement();
            my $name = $el->getName;
            if ($name =~ /^_(.*)/) {
                $name = unescape($1);
            }
            $ret .= "<key>$name</key>" . $self->element_to_plist($el);
        }
        if ($ret) {
            return "<dict>$ret</dict>";
        } else {
            return "<dict/>";
        }
    }

    if ($obj->isType(LIST)) {
        my $ret = "";
        while ($obj->hasNextElement) {
            my $el = $obj->getNextElement();
            $ret .= $self->element_to_plist($el);
        }
        if ($ret) {
            return "<array>$ret</array>";
        } else {
            return "<array/>";
        }
    }
}

1; #required for Perl modules
