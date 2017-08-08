#${PMcomponent}

=head1 NAME

C<NCM::Component::syslog> configures entries in /etc/(r)syslog.conf

=head1 Methods

=over

=cut

use parent qw(NCM::Component);

use CAF::FileWriter;
use CAF::FileEditor 16.12.1;
use CAF::Service;
use Readonly;

# Daemontype has a pan default value;
# these 2 readonly are only used with pre 17.2 schema versions
Readonly my $SYSLOG_DEFAULT_DAEMONTYPE => 'syslog';
Readonly my $SYSLOG_DEFAULT_FILENAME => '/etc/syslog.conf';

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;


=item sysconfig

Modify/add C<SYSLOGD> and/or C<KLOGD> options
in the C<$sysconfig> file.

Returns if file changed.

=cut

sub sysconfig
{
    my ($self, $tree, $sysconfig) = @_;

    my $fh = CAF::FileEditor->new($sysconfig, log => $self);

    foreach my $key (qw(syslogd klogd)) {
        my $options = $tree->{"${key}options"};
        next if ! defined($options);
        # wrap in double quotes is whitespace is present and no quotes yet
        $options = '"'.$options.'"' if ($options =~ m/\s/ && $options !~ m/^['"]/);

        my $cfgkey = uc($key).'_OPTIONS';
        $fh->add_or_replace_sysconfig_lines($cfgkey, $options);
    }

    return $fh->close() ? 1 : 0;
};

=item render

Create the complete (r)syslog config file.

This method is used when C<fullcontrol> is enabled.

Returns if file changed.

=cut

# Directives get the ' # ncm-syslog' suffix so they can be recognised as such by edit
# TODO: print template
# TODO: use textrender
sub render
{
    my ($self, $tree, $fn) = @_;

    $self->debug(2, "render: fullcontrol is true");

    my $fh = CAF::FileWriter->new($fn, log => $self);

    foreach my $dr (@{$tree->{directives} || []}) {
        $self->debug(2,"Directive $dr requested");
        print $fh sprintf("%-40s # ncm-syslog\n", $dr);
    };

    foreach my $rule (@{$tree->{config} || []}) {
        my $comment = $rule->{comment};
        if ($comment) {
            # re-wrap comment
            $comment =~ s/^\n?#*\s*(.*?)\n?$/\n# $1\n/;
            print $fh $comment;
        }

        my $template = $rule->{template} ? ';'.$rule->{template} : "";

        print $fh join(';', map { "$_->{facility}.$_->{priority}" } @{$rule->{selector} || []});
        print $fh "\t$rule->{action}\n";
    }

    return $fh->close() ? 1 : 0;
}

=item edit

Edit the (r)syslog config file, leaving entries from
other sources intact.

This method is used when C<fullcontrol> is disabled.

Returns if file changed.

=cut

# This code is based on the legacy code
# TODO: config entries without selectors are ignored by edit (not warned or anything)
sub edit
{
    my ($self, $tree, $fn) = @_;

    my %directive_found;

    my @syslogcontents = ();

    # old style, we accept entries from other sources in syslog.conf
    $self->debug(2, "edit: fullcontrol is not defined or false");

    # Parse existing file
    my $fhr = CAF::FileReader->new($fn, log => $self);
    foreach my $line (split(/\n/, "$fhr")) {
        if ($line =~ m/# ncm-syslog/) {
            # (r)syslog directives
            $line =~ s/\s*# ncm-syslog.*//;
            $directive_found{$line}=1;
        } else {
            # no newlines
            push @syslogcontents, $line;
        }
    }
    $fhr->close();

    my $fh = CAF::FileWriter->new($fn, log => $self);

    # Accumulate the directives such as templates, modload etc.
    foreach my $dr (@{$tree->{directives} || []}) {
        if (exists($directive_found{$dr})) {
            $self->debug(2, "Directive $dr already present in $fn");
            delete $directive_found{$dr};
        } else {
            $self->debug(2, "Directive $dr is new");
        }
        print $fh sprintf("%-40s # ncm-syslog\n", $dr);
    }

    # These were not withheld
    foreach my $dr (sort keys %directive_found) {
        $self->debug(2, "Directive $dr deleted from $fn");
    }

    # Accumulate the config rules
    foreach my $rule (@{$tree->{config} || []}) {
        my $action = $rule->{action};
        # action might contain some regex characters (this is not complete)
        my $maction = $action;
        # escape the $, otherwise it's seen as $]
        $maction =~ s/([.*+\$])/\\$1/g;

        # TODO: template code in legacy code was ignored
        #       making this clear by commenting it
        #my $template = $rule->{template} ? ';'.$rule->{template} : "";

        # do not consider actions that appear in comment lines
        my $action_known = grep { m/^[^#].*\s${maction}/ } @syslogcontents;

        # get selectors
        my $line = "";
        my $seperator = "";
        foreach my $selector (@{$rule->{selector} || []}) {
            my $facility = $selector->{facility};
            my $priority = $selector->{priority};

            # accept entries from other sources? Then we need some checks...

            # does the action exist already?
            if ($action_known) {
                $self->debug(2, "action $action is known already");
                # check whether this action has an entry for this facility
                # escape the '*'
                my $mfacility = $facility eq '*' ? '\*' : $facility;
                my $mpriority = $priority eq '*' ? '\*' : $priority;

                # the facility may alreay start at column1, so cannot use "^[^#]" to veto comments
                if (grep { /^.*${mfacility}\..*\s+${maction}/ } @syslogcontents) {
                    $self->debug(2, "facility $facility already uses action $action");
                    # this facility used this action already, but is the priority correct?
                    if ( ! grep { /^.*${mfacility}\.${mpriority}.*${maction}/ } @syslogcontents ){
                        $self->debug(2, "have to fix priority for facility $facility");
                        my @newsyslogcontents;
                        foreach my $line (@syslogcontents) {
                            $line =~ s/${mfacility}\.[\w\*]+/${facility}\.${priority}/ if $line =~ m/^[^#].*$maction/;
                            push(@newsyslogcontents, $line);
                        };
                        @syslogcontents = @newsyslogcontents;
                    }
                } else {
                    $self->debug(2, "facility $facility is not yet using action $action");
                    # this facility has not yet used this action, simply add it to this action
                    my @newsyslogcontents;
                    foreach my $line (@syslogcontents) {
                        $line =~ s/\s*${maction}/;${facility}\.${priority}\t${action}/ unless $line =~ m/^#/;
                        push(@newsyslogcontents, $line);
                    };
                    @syslogcontents = @newsyslogcontents;
                }
            } else {
                $self->debug(2, "action $action is not yet known");
                # this action not known, just add
                push @syslogcontents, "$facility.$priority\t$action";
            }
        }
    }

    print $fh join("\n", @syslogcontents);
    print $fh "\n";

    return $fh->close() ? 1 : 0;
}


sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix);

    # Daemontype has a pan default value;
    # these 2 readonly are only used with pre 17.2 schema versions
    my $type = $tree->{daemontype} || $SYSLOG_DEFAULT_DAEMONTYPE;
    my $fn = $tree->{file} || (exists($tree->{daemontype}) ? "/etc/$type.conf" : $SYSLOG_DEFAULT_FILENAME);

    my $fullcontrol = $tree->{fullcontrol} ? 1 : 0;
    my $sysconfig = "/etc/sysconfig/$type";
    $self->verbose("daemontype $type with config filename $fn (fullcontrol $fullcontrol sysconfig $sysconfig)");

    my $changes = 0;

    my $method = $fullcontrol ? 'render' : 'edit';

    $changes += $self->$method($tree, $fn);

    $changes += $self->sysconfig($tree, $sysconfig);

    if ($changes) {
        CAF::Service->new([$type], log => $self)->restart();
    }

    return;

}

=pod

=back

=cut

1;
