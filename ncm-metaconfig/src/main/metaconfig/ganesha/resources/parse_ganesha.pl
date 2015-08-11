#!/usr/bin/perl


use strict;
use warnings;

use File::Find;

# # 
# This script searches for configuration settings in the ganesha source folder. 
# It will use this to print out pan types for the schema. 
# The types and the attributes are printed out sorted, with their default values
# Mandatory or optional is also given by ':' and '?'

my $CONF = {};
my $DEF = {};
my $TYPES_MAP = {
    STR => "string",
    FSID => "string",
    PATH => "string",
    BOOL => "boolean",
    UI16 => "long(0..)",
    UI32 => "long(0..)",
    UI64 => "long(0..)",
    I16 => "long",
    I32 => "long",
    I64 => "long",
    BLOCK => "type_BLOCK",
    IPV4_ADDR => "type_ip",
};

sub parse_file
{
    if (-T && (m/\.c$/ || $_ eq "config_parsing.h")) {
       # Read file, look for magic string
       my $file = $_;
       my $text;
       open FH, $file;
       while (<FH>) {
	   $text .= $_;
       }
       close FH;
       
       if ($text) {
	   
	   while($text =~ m/^\s*(?:#define\s+)?CONF_(ITEM|MAND|UNIQ|RELAX)_(\w+)\(([^)]+)\)/mg) {
	       my $cat = $1;
	       my $type = $2;
	       my $args = $3;
	       $args =~ s/\s+//g;
	       my @args = split(',', $args);
	       if ($file eq "config_parsing.h") {
		   my %index;
		   @index{@args} = (0..$#args);

		   my $defindex = $index{_def_};
		   $DEF->{$cat}->{$type} = \%index;

		   #print $File::Find::name," $cat $type $defindex\n";
	       } else {
		   #$CONF->{$cat}->{$type} = \@args;
		   $CONF->{$file}->{$args[0]} = { 
                cat => $cat,
		        type => $type,
		        args => \@args
            }
		   #print $File::Find::name," $cat $type $args[0] $args[1] $args\n";
	       }
	   }
       } else {
	   #print $File::Find::name," empty file\n";
       }

    }
}

sub print_config
{
    foreach my $file (sort keys %$CONF) {
        my $params = $CONF->{$file};
        $file =~ s/\.c$//;
        print "type ganesha_v2_$file = {\n";
        foreach my $name (sort keys %$params) {
            my $attrs = $params->{$name};
            print "    $name ";
            my $cat = $attrs->{cat};
            my $type = $attrs->{type};
            if ($cat eq 'MAND'){
                print ":";
            } elsif ($cat eq 'ITEM'){
                print "?"; 
            } else {
                print $cat;
            }
            if ($TYPES_MAP->{$type}) {
                print " $TYPES_MAP->{$type}";
            } else {
                print " $type";
            }
            if ($DEF->{$cat}->{$type}->{_def_}){
                my $default =  $attrs->{args}[$DEF->{$cat}->{$type}->{_def_}];
                print " = $default";
            }
            print "\n";
        }
        print "}\n";
    }
}


find(\&parse_file, @ARGV);


use Data::Dumper;

#print Dumper($CONF);
#print Dumper($DEF);
print_config();

