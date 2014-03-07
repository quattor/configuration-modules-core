# ${license-info}
# ${developer-info}
# ${author-info}

# This program is free software; you can redistribute it and/or modify
# it under the terms of the EU DataGrid Software License.  You should
# have received a copy of the license with this program, and the license
# is published at http://eu-datagrid.web.cern.ch/eu-datagrid/license.html.
#
# THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER MATERIALS
# CONTRIBUTED IN CONNECTION WITH THIS PROGRAM.
#
# THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
# DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS
# SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING
# THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE
# TERMS THAT MAY APPLY.
#
###############################################################################


#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################
#
# pam - Morgan Stanley Component
#
###############################################################################

package NCM::Component::pam;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element qw(BOOLEAN);

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my $prefix = "/software/components/pam";
  # Now do something...
  if (!$config->elementExists("$prefix")) {
      return 0;
  }
  my $inf = $config->getElement("$prefix")->getTree;


  foreach my $service (sort keys %{$inf->{services}}) {
      my $sinfo = $inf->{services}->{$service};

      my $body = "#%PAM-1.0\n";
      $body .= "# Generated by ncm-pam\n";
      my $spacer = "";
      foreach my $type (sort keys %$sinfo) {
	  $body .= $spacer;
	  my $pos = 0;
	  foreach my $spec (@{$sinfo->{$type}}) {
	      my $modpath = $inf->{modules}->{$spec->{module}}->{path};
	      my $opts = "";

	      # See if we have any ACLs defined for pam_filelist, get those
	      # installed before we change any pam definitions.
	      if ($spec->{module} eq 'filelist') {
		  if (exists $spec->{allow}) {
		      $self->make_acl_file($spec->{allow});
		  }
		  if (exists $spec->{deny}) {
		      $self->make_acl_file($spec->{deny});
		  }
	      }

	      if (exists $spec->{options}) {
		  my @o = ();
		  foreach my $kv (sort keys %{$spec->{options}}) {
		      if ($config->getElement("$prefix/services/$service/$type/$pos/options/$kv")->isType(BOOLEAN)) {
			  push(@o, $kv) if $spec->{options}->{$kv};
		      } else {
			  push(@o, "$kv=$spec->{options}->{$kv}");
		      }
		  }
		  $opts = join(" ", @o);
	      }
	      $body .= sprintf("%-11s %-13s %s %s\n", $type, $spec->{control}, $modpath, $opts);
	      $pos++;
	  }
	  $spacer = "\n";
      }

      my $file = "$inf->{directory}/$service";
      $file =~ s{//+}{/}g;
      my $mode = $inf->{services}->{$service}->{perm} || "0444";
      my $result = LC::Check::file($file, 
				   backup => ".OLD",
				   contents => $body,
				   owner => "root",
				   group => "root",
				   mode => $mode,
				  );
      if ($result) {
	  $self->log("updated $file");
      }
  }

  return 1;
}

sub make_acl_file {
    my ($self, $acl) = @_;
    my $content = join("\n", sort @{$acl->{items}});
    my $mode = $acl->{mode} || "0444";
    my $result = LC::Check::file($acl->{filename},
				 backup => ".OLD",
				 contents => $content,
				 owner => "root",
				 group => "root",
				 mode => $mode,
				);
      if ($result) {
	  $self->log("updated ACL $acl->{filename}");
      }
}

1; #required for Perl modules
