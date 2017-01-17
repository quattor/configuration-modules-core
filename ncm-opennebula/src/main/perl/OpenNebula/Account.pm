#${PMpre} NCM::Component::OpenNebula::Account${PMpost}

use NCM::Component::OpenNebula::Server qw($SERVERADMIN_USER $ONEADMIN_USER);
use Readonly;

Readonly my $CORE_AUTH_DRIVER => "core";

=head1 NAME

C<NCM::Component::OpenNebula::Account> adds and modifies C<OpenNebula> user 
and groups accounts.

=head2 Public methods

=over

=item manage_users_groups

Add/remove/update regular users/groups and assign users to groups
only if the user/group has the QUATTOR flag set.

=cut

sub manage_users_groups
{
    my ($self, $one, $type, $data, %protected) = @_;
    my $getmethod = "get_${type}s";
    my $createmethod = "create_${type}";
    my %temp;

    my @datalist;
    foreach my $account (sort keys %$data) {
        if ($account eq $SERVERADMIN_USER && exists $data->{$account}->{password}) {
            $self->change_opennebula_passwd($account, $data->{$account}->{password});
        } elsif ($account eq $ONEADMIN_USER && exists $data->{$account}->{ssh_public_key}) {
            $temp{$account}->{$account} = $data->{$account};
            my $template = $self->process_template($temp{$account}, $type);
            $self->update_something($one, $type, $account, $template);
        };
        push(@datalist, $account);
    }

    my @accounts = $one->$getmethod();
    my %newaccounts = map { $_ => 1 } @datalist;
    my @rmdata;
    foreach my $account (@accounts) {
        # Remove the user/group only if the QUATTOR flag is set
        my $quattor = $self->check_quattor_tag($account, 1);
        if (exists($protected{$account->name})) {
            $self->info("This $type is protected and cannot be removed: ", $account->name);
        } elsif (exists($newaccounts{$account->name})) {
            $self->verbose("$type required by Quattor. We cannot remove it: ", $account->name);
        } elsif (!$quattor) {
            $self->verbose("QUATTOR flag not found. We cannot remove this $type: ", $account->name);
        } else {
            push(@rmdata, $account->name);
            $account->delete();
        }
    }

    if (@rmdata) {
        $self->info("Removed ${type}s: ", join(',', @rmdata));
    }

    foreach my $account (sort keys %$data) {
        if (exists($protected{$account})) {
            $self->info("This $type is protected and can not be created/updated: ", $account);
        } else {
            $temp{$account}->{$account} = $data->{$account};
            my $template = $self->process_template($temp{$account}, $type);
            my $used = $self->detect_used_resource($one, $type, $account);
            if (!$used) {
                $self->info("Creating new $type: ", $account);
                if (exists $data->{$account}->{password}) {
                    # Create new user
                    $one->$createmethod($account, $data->{$account}->{password}, $CORE_AUTH_DRIVER);
                    $self->set_user_primary_group($one, $account, $data->{$account}->{group}) if (exists $data->{$account}->{group});
                } else {
                    # Create new group
                    $one->$createmethod($account);
                };
                # Add QUATTOR flag
                $self->update_something($one, $type, $account, $template);
            } elsif ($used == -1) {
                # User/group is already there and we can modify it
                $self->info("Updating $type with a new template: ", $account);
                $self->update_something($one, $type, $account, $template);
                if ((exists $data->{$account}->{group}) and ($type eq "user")) {
                    $self->set_user_primary_group($one, $account, $data->{$account}->{group});
                };
            }
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
