#${PMcomponent}

use parent qw(NCM::Component);

use LC::Exception;
use LC::Find;
use LC::File qw(copy makedir);

use EDG::WP4::CCM::TextRender;
use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use File::Basename;
use File::Path;
use Readonly;

Readonly::Array my @RESTART => qw(/sbin/service postfix condrestart);
Readonly::Hash my %FILES => {
    main => {
        file => "/etc/postfix/main.cf",
        template => "main.tt",
    },
    master => {
        file => "/etc/postfix/master.cf",
        template => "master.tt",
    },
    dbs => {
        ldap => {
            template => "ldap.tt",
        }
    }
};

Readonly::Scalar my $DBS_BASE => "/etc/postfix/";
Readonly::Scalar my $PATH => "/software/components/postfix";

our $EC = LC::Exception::Context->new->will_store_all;


# Restart the process.
sub restart_postfix {
    my ($self) = @_;
    CAF::Process->new(\@RESTART, log => $self)->run();
    return !$?;
}

# Fills a configuration file from the profile subtree $tree. The file
# and templates
sub handle_config_file
{
    my ($self, $tree, $files) = @_;

    my $ok=1;
    my $trd = EDG::WP4::CCM::TextRender->new($files->{template}, $tree, relpath => 'postfix', log => $self);
    if ($trd) {
        my $fh = $trd->filewriter($files->{file}, log => $self);
        $fh->close();
    } else {
        $self->error("Unable to process template for $files->{file}: $trd->{fail}");
        $ok = undef;
    }

    return $ok;
}

sub handle_databases
{
    my ($self, $tree) = @_;

    my $ok = 1;

    foreach my $dbtype (sort keys %$tree) {
        $self->verbose("Generating configuration for databases of type $dbtype");
        my $tpl = $FILES{dbs}->{$dbtype}->{template};
        my $dbs = $tree->{$dbtype};
        foreach my $db (sort keys %$dbs) {
            $self->verbose("Configuring access to database $dbtype: $db");

            my $trd = EDG::WP4::CCM::TextRender->new($tpl, $dbs->{$db}, relpath => 'postfix', log => $self);
            if ($trd) {
                my $fh = $trd->filewriter($DBS_BASE . $db, log => $self);
                $fh->close();
            } else {
                $self->error("Unable to process template for database $db: $trd->{fail}");
                $ok = undef;
            }
        }
    }
    return $ok;
}

sub Configure {
    my ($self, $config) = @_;

    my $ok = 1;
    my $t = $config->getTree($self->prefix());

    $self->handle_config_file($t, $FILES{master}) or $ok = 0;
    $self->handle_config_file($t->{main}, $FILES{main}) or $ok = 0;

    if (exists($t->{databases})) {
        $self->handle_databases($t->{databases}) or $ok = 0;
    }
    $self->restart_postfix() or $ok = 0;

    return $ok;
}

1; # Required for perl module!
