#${PMcomponent}

=head1 NAME

ncm-${project.artifactId}: Configure services whose config format can be
rendered via C<EDG::WP4::CCM::TextRender>.

=head1 CONFIGURATION MODULES

The following formats can be rendered via C<EDG::WP4::CCM::TextRender>:

=over 4

=item * general

Uses Perl's L<Config::General>. This leads to configuration files
similar to this one:

    <nlist>
      <another nlist>
        scalar value
        another scalar value
      </another nlist>
    </nlist>
    list_element 0
    list_element 1
    list_element 2

=item * tiny

Uses Perl's L<Config::Tiny>, typically for C<key = value> files or
INI-like files with sections separated by C<[section]> headers.

=item * yaml

Uses Perl's L<YAML::XS> for rendering YAML configuration files.

=item * json

Uses L<JSON::XS> for rendering JSON configuration files.

=item * jsonpretty

Uses L<JSON::XS> pretty for rendering JSON configuration files.

=item * properties

Uses L<Config::Properties> for rendering Java-style configuration
files.

=item * Any other string

Uses L<Template::Toolkit> for rendering configuration files in formats
supplied by the user.

The name of the template is given by this field. It B<must> be a path
relative to C<metaconfig/>, and the component actively sanitizes this
field.

=back

=head1 EXAMPLES

=head2 Configuring /etc/ccm.conf

The well-known /etc/ccm.conf can be defined like this:

=head3 Define a valid structure for the file

    type ccm_conf_file = {
        "profile" : type_absoluteURI
        "debug" : long(0..5)
        "force" : boolean = false
        ...
    };

    bind "/software/components/metaconfig/services/{/etc/ccm.conf}/contents" = ccm_conf_file;

=head3 Fill in the contents

    prefix "/software/components/metaconfig/services/{/etc/ccm.conf}"

    "contents/profile" = "http://www.google.com";
    "module" = "general";

=head3 And that's it

Now, just compile and deploy. You should get the same results as with
old good ncm-ccm.

=head2 Generating an INI-like file

We can generate simple INI-like files with the C<Config::Tiny> module.

=head3 Example schema

Let's imagine the file has two sections with one key each:

    # This is the first section, labeled "s1"
    type section_1 = {
       "a" : long
    };

    # This is the second section, labeled "s2"
    type section_2 = {
       "b" : string
    };

    # This is the full file structure
    type my_ini_file = {
       "s1" : section_1
       "s2" : section_2
    };

    bind "/software/components/metaconfig/services/{/etc/foo.ini}/contents" = my_ini_file;

=head3 Describing the file

We'll define the permissions, who renders it and which daemons are associated to it.

    prefix "/software/components/metaconfig/services/{/etc/foo.ini}";

    "mode" = 0600;
    "owner" = "root";
    "group" = "root";
    "module" = "tiny";
    "daemons/foo" = "restart";
    "daemons/bar" = "reload";

And we'll ensure the module that renders it is installed (Yum-based
syntax here):

    "/software/packages/{perl-Config-Tiny}" = nlist();

=head3 Describing the file's contents

And now, we only have to specify the contents:

    prefix "/software/components/metaconfig/services/{/etc/foo.ini}/contents";
    "s1/a" = 42;
    "s2/b" = "hitchicker";

=head3 And that's it

That's it!  When you deploy your configuration you should see your
/etc/foo.ini in the correct location.

=cut

use parent qw(NCM::Component);

use LC::Exception;
use EDG::WP4::CCM::TextRender 18.6.1;
use CAF::Service;
use CAF::ServiceActions;
use EDG::WP4::CCM::Path qw(unescape);
use Readonly;

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

# Generate C<$file>, configuring C<$srv> using CAF::TextRender with
# contents C<$contents> (if C<$contents>  is not defined,
# C<$srv->{contents}> is used).
# Also tracks the actions that need to be taken via the
# C<$sa> C<CAF::ServiceActions> instance.
# Returns undef in case of rendering failure, 1 otherwise.
sub handle_service
{
    my ($self, $file, $srv, $contents, $sa) = @_;

    $contents = $srv->{contents} if (! defined($contents));

    my $trd = EDG::WP4::CCM::TextRender->new($srv->{module},
                                             $contents,
                                             log => $self,
                                             eol => 0,
                                             element => $srv->{convert},
                                             );

    my %opts = (
        log => $self,
    );

    $opts{mode} = $srv->{mode} if exists($srv->{mode});
    $opts{owner} = scalar(getpwnam($srv->{owner})) if exists($srv->{owner});
    $opts{group} = scalar(getgrnam($srv->{group})) if exists($srv->{group});

    $opts{backup} = $srv->{backup} if exists($srv->{backup});

    $opts{header} = "$srv->{preamble}\n" if $srv->{preamble};

    # This in combination with eol=0 is what the original code does
    # TODO: switch to eol=1 and remove this footer?
    $opts{footer} = "\n";

    my $fh = $trd->filewriter($file, %opts);

    if (!defined($fh)) {
        $self->error("Failed to render $file ($trd->{fail}). Skipping");
        return;
    }

    if ($fh->close()) {
        $self->info("File $file updated");
        $sa->add($srv->{daemons}, msg => "for file $file");
    } else {
        $self->verbose("File $file up-to-date");
    };

    return 1;
}

sub _configure_files
{
    my ($self, $config, $root) = @_;

    my $t = $config->getElement($self->prefix)->getTree();

    my $sa = CAF::ServiceActions->new(log => $self);

    foreach my $esc_filename (sort keys %{$t->{services}}) {
        my $srvc = $t->{services}->{$esc_filename};
        my $cont_el = $config->getElement($self->prefix()."/services/$esc_filename/contents");
        my $filename = ($root || '') . unescape($esc_filename);
        $self->handle_service($filename, $srvc, $cont_el, $sa);
    }

    return $sa;
}

sub Configure
{
    my ($self, $config) = @_;

    my $sa = $self->_configure_files($config);

    $sa->run();

    return 1;
}

# Generate the files relative to metaconfig subdirectory
# under the configuration cachemanager cache path.
# No daemons will be restarted.
sub aii_command
{
    my ($self, $config) = @_;

    my $root = $config->{cache_path};
    if ($root) {
        $self->_configure_files($config, "$root/metaconfig");
        return 1;
    } else {
        $self->error("No cache_path found for Configuration instance");
        return;
    }
}

1; # Required for perl module!
