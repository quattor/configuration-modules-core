#${PMpre} NCM::Component::OpenNebula::Account${PMpost}

use NCM::Component::OpenNebula::Server qw($SERVERADMIN_USER $ONEADMIN_USER);
use Readonly;

Readonly my $CORE_AUTH_DRIVER => "core";

=head1 NAME

C<NCM::Component::OpenNebula::Account> adds and modifies C<OpenNebula> users
 groups and clusters consumers.

=head2 Public methods

=over

=item manage_consumers

Add/remove/update regular users/groups/clusters.
Assign users to groups only if the user/group has
the QUATTOR flag set.

=cut

sub manage_consumers
{
    my ($self, $one, $type, $data, %protected) = @_;
    my $getmethod = "get_${type}s";
    my $createmethod = "create_${type}";
    my %temp;

    my @datalist;
    foreach my $consumer (sort keys %$data) {
        if ($consumer eq $SERVERADMIN_USER && exists $data->{$consumer}->{password}) {
            $self->change_opennebula_passwd($consumer, $data->{$consumer}->{password});
        } elsif ($consumer eq $ONEADMIN_USER && exists $data->{$consumer}->{ssh_public_key}) {
            $temp{$consumer}->{$consumer} = $data->{$consumer};
            my $template = $self->process_template($temp{$consumer}, $type);
            $self->update_something($one, $type, $consumer, $template);
        };
        push(@datalist, $consumer);
    }

    my @consumers = $one->$getmethod();
    my %newconsumers = map { $_ => 1 } @datalist;
    my @rmdata;
    foreach my $consumer (@consumers) {
        # Remove the user/group/cluster only if the QUATTOR flag is set
        my $quattor = $self->check_quattor_tag($consumer, 1);
        if (exists($protected{$consumer->name})) {
            $self->info("This $type is protected and cannot be removed: ", $consumer->name);
        } elsif (exists($newconsumers{$consumer->name})) {
            $self->verbose("$type required by Quattor. We cannot remove it: ", $consumer->name);
        } elsif (!$quattor) {
            $self->verbose("QUATTOR flag not found. We cannot remove this $type: ", $consumer->name);
        } else {
            push(@rmdata, $consumer->name);
            $consumer->delete();
        }
    }

    if (@rmdata) {
        $self->info("Removed ${type}s: ", join(',', @rmdata));
    }

    foreach my $consumer (sort keys %$data) {
        if (exists($protected{$consumer})) {
            $self->info("This $type is protected and can not be created/updated: ", $consumer);
        } else {
            $temp{$consumer}->{$consumer} = $data->{$consumer};
            my $template = $self->process_template($temp{$consumer}, $type);
            my $used = $self->detect_used_resource($one, $type, $consumer);
            if (!$used) {
                $self->info("Creating new $type: ", $consumer);
                if (exists $data->{$consumer}->{password}) {
                    # Create new user
                    $one->$createmethod($consumer, $data->{$consumer}->{password}, $CORE_AUTH_DRIVER);
                    $self->set_user_primary_group($one, $consumer, $data->{$consumer}->{group}) if (exists $data->{$consumer}->{group});
                } else {
                    # Create new group/cluster
                    $one->$createmethod($consumer);
                };
                # Add QUATTOR flag
                $self->update_something($one, $type, $consumer, $template);
            } elsif ($used == -1) {
                # Consumer is already there and we can modify it
                $self->info("Updating $type with a new template: ", $consumer);
                $self->update_something($one, $type, $consumer, $template);
                if ((exists $data->{$consumer}->{group}) and ($type eq "user")) {
                    $self->set_user_primary_group($one, $consumer, $data->{$consumer}->{group});
                };
            } else {
                $self->update_something($one, $type, $consumer, $template);
            };
        }
    }
}

=item set_user_primary_group

Sets user primary group.

=cut

sub set_user_primary_group
{
    my ($self, $one, $name, $group) = @_;

    $self->info("User $name must belong to this primary group $group");
    my $group_id = $self->get_resource_id($one, "group", $group);

    if (defined($group_id)) {
        my @users = $one->get_users(qr{^$name$});
        $self->warn("Detected administration group change for regular user $name") if ($group_id == 0);
        foreach my $usr (@users) {
            if (defined($usr->chgrp($group_id))) {
                $self->info("Changed user $name primary group to $group");
            } else {
                $self->error("Not able to change user $name group to $group");
            };
        }
    } else {
        $self->error("Requested OpenNebula group $group for user $name does not exist");
    };
}

=item get_permissions

Gets current resource permissions.

=cut

sub get_permissions
{
    my ($self, $config) = @_;

    my $tree = $config->getElement('/system/opennebula')->getTree();
    my $perm = $tree->{permissions};
    if ($perm) {
        $self->verbose("Found resource permissions ", join(" ", map {"$_=$perm->{$_}"} sort keys %$perm));
    } else {
        $self->verbose("No resource permissions set");
    };
    return $perm;
}

=item change_permissions

Changes resource permissions.

=cut

sub change_permissions
{
    my ($self, $one, $type, $resource, $permissions) = @_;

    my %chown = (one => $one);
    my $mode = $permissions->{mode};

    if(defined($mode)) {
        my $out = $resource->chmod($mode);
        if ($out) {
            $self->info("Changed $type mode id $out to: $mode");
        } else {
            $self->error("Not able to change $type mode to: $mode");
        };
    };
    $chown{uid} = defined($permissions->{owner}) ? $permissions->{owner} : -1;
    $chown{gid} = defined($permissions->{group}) ? $permissions->{group} : -1;

    my $msg = "user:group $chown{uid}:$chown{gid} for: " . $resource->name;
    if ($resource->chown(%chown)) {
        $self->info("Changed $type permissions $msg");
    } else {
        $self->error("Not able to change $type permissions $msg");
    };
}

=pod

=back

=cut

1;
