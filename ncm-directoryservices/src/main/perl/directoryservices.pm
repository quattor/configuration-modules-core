# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# NCM component for directoryservices on darwin
#
#
# ** Generated file : do not edit **
#
#######################################################################

package NCM::Component::directoryservices;


#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use LC::Check;
use CAF::Process;
use Proc::Killall; # From Proc::ProcessTable
use EDG::WP4::CCM::Element qw(STRING LONG DOUBLE BOOLEAN LIST NLIST);
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

our $dscl = "/usr/bin/dscl";
our $plutil = "/usr/bin/plutil";

sub Configure {
    my ($self, $config) = @_;
    my $cfgpath = $self->prefix;
    my $path = $config->getElement("$cfgpath/search")->getTree();

    # Test the proposed search path
    my $errors = 0;
    my @path = ();
    foreach my $p (@$path) {
        if ($p =~ m{^/([^/]*)/(.*)}) {
            my $style = lc($1);
            my $node = $2;
            my $fn = "check_$style";
            if (!$self->can($fn)) {
                $self->error("no support for $style directory");
                $errors++;
                next;
            }
            $self->$fn($config, $node);
            push(@path, $p);
        }
    }
    return 0 if ($errors);

    # Find the current value of the search path
    my $proc = CAF::Process->new([$dscl, qw{/Search -read / CSPSearchPath}], log => $self);
    my $output = $proc->output;
    my ($orig) = ($output =~ m{:\s+(.*)$});

    if ($orig ne join(" ", @path)) {
        my $proc = CAF::Process->new([$dscl, qw{/Search -create / CSPSearchPath}], log => $self);
        $proc->pushargs(@path);
        my $out = $proc->output;
        if ($? >> 8) {
            $self->error("failed to set search path to '" . join(" ", @path) . "': $out");
            return 0;
        }
    }
} 

sub check_local {
    my ($self, $config, $node) = @_;

    my $dir = "/var/db/dslocal/nodes/$node";
    # Construct the framework for our local directory
    LC::Check::directory($dir); # an exception here will be sufficient, we don't check
    # Lion requires 'users' and 'computers'
    LC::Check::directory("$dir/users");
    LC::Check::directory("$dir/groups");

}

sub check_ldapv3 {
    my ($self, $config, $node) = @_;
    my $inf = $config->getElement($self->prefix . "/ldapv3/$node");

    # the end-file is a binary plist - we don't want to
    # write out the text version of the file into the same directory location 
    # because that will break opendirectory. 
    # So we write to an alternate location and check that file.
    my $binfile = "/Library/Preferences/OpenDirectory/Configurations/LDAPv3/$node.plist";
    my $txtfile = "/var/lib/ncm-directoryservices/ldapv3-$node.plist";
    LC::Check::directory("/Library/Preferences/OpenDirectory/Configurations/LDAPv3");
    LC::Check::directory("/var/lib/ncm-directoryservices");

    my $plist = $self->element_to_plist($inf);
    my $body = '<?xml version="1.0" encoding="UTF-8"?>';
    $body .= '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">';
    $body .= '<plist version "1.0">' . $plist . '</plist>';

    my $result = LC::Check::file($txtfile, contents => $body, owner => 'root', 'mode' => '0444');
    # really should also compare mtime on binfile/txtfile
    if ($result) {
        $self->log("updated $txtfile, will convert");
        my $proc = CAF::Process->new([$plutil, qw{-convert binary1 -o}], log => $self);
        $proc->pushargs($binfile);
        $proc->pushargs($txtfile);
        my $out = $proc->output();
        if ($? >> 8) {
            $self->error("failed to convert plist to binary ($binfile): $out");
            unlink($txtfile); # Make sure we try again next time!
            # XXX: put the original file back
            return 0;
        }

        # restart opendirectory: killall opendirectoryd, it'll be restarted automatically
        $self->log("restarting opendirectoryd");
        if (!killall('INT', '/usr/libexec/opendirectoryd')) {
            $self->warn("failed to restart opendirectoryd ($!)");
        }
        sleep(3);
    }
}


# This is in common for both directoryservices and mcx, but I'm not sure
# how to make this into a reasonable library for quattor. Possibly a new
# dependency on a perl library...
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
                $name = $self->unescape($1);
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

