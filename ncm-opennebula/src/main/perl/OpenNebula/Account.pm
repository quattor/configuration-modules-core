use NCM::Component::OpenNebula::Server;

=head1 NAME

NCM::Component::OpenNebula::Account adds and modifies C<OpenNebula> user 
and groups accounts.

=head2 Public methods

=over


=item manage_users_groups

Add/remove/update regular users/groups and assign users to groups
only if the user/group has the Quattor flag set.

=cut

sub manage_users_groups
{
    my ($self, $one, $type, $data, %protected) = @_;
    my ($new, $template, @rmdata, @datalist);
    my $getmethod = "get_${type}s";
    my $createmethod = "create_${type}";
    my %temp;

    foreach my $account (sort keys %{$data}) {
            if ($account eq $SERVERADMIN_USER && exists $data->{$account}->{password}) {
                $self->change_opennebula_passwd($account, $data->{$account}->{password});
            } elsif ($account eq $ONEADMIN_USER && exists $data->{$account}->{ssh_public_key}) {
                $temp{$account}->{$account} = $data->{$account};
                $template = $self->process_template($temp{$account}, $type);
                $new = $self->update_something($one, $type, $account, $template);
            };
            push(@datalist, $account);
    }

    my @existsdata = $one->$getmethod();
    my %newaccounts = map { $_ => 1 } @datalist;

    foreach my $t (@existsdata) {
        # Remove the user/group only if the QUATTOR flag is set
        my $quattor = $self->check_quattor_tag($t,1);
        if (exists($protected{$t->name})) {
            $self->info("This $type is protected and can not be removed: ", $t->name);
        } elsif (exists($newaccounts{$t->name})) {
            $self->verbose("$type required by Quattor. We can't remove it: ", $t->name);
        } elsif (!$quattor) {
            $self->verbose("QUATTOR flag not found. We can't remove this $type: ", $t->name);
        } else {
            push(@rmdata, $t->name);
            $t->delete();
        }
    }

    if (@rmdata) {
        $self->info("Removed ${type}s: ", join(',', @rmdata));
    }

    foreach my $account (sort keys %{$data}) {
        if (exists($protected{$account})) {
            $self->info("This $type is protected and can not be created/updated: ", $account);
        } else {
            $temp{$account}->{$account} = $data->{$account};
            $template = $self->process_template($temp{$account}, $type);
            my $used = $self->detect_used_resource($one, $type, $account);
            if (!$used) {
                $self->info("Creating new $type: ", $account);
                if (exists $data->{$account}->{password}) {
                    # Create new user
                    $one->$createmethod($account, $data->{$account}->{password}, $CORE_AUTH_DRIVER);
                    $self->change_user_group($one, $account, $data->{$account}->{group}) if (exists $data->{$account}->{group});
                } else {
                    # Create new group
                    $one->$createmethod($account);
                };
                # Add Quattor flag
                $new = $self->update_something($one, $type, $account, $template);
            } elsif ($used == -1) {
                # User/group is already there and we can modify it
                $self->info("Updating $type with a new template: ", $account);
                $new = $self->update_something($one, $type, $account, $template);
                if ((exists $data->{$account}->{group}) and ($type eq "user")) {
                    $self->change_user_group($one, $account, $data->{$account}->{group});
                };
            }
        }
    }
}

=item change_user_group

Sets user primary group.

=cut

sub change_user_group
{
    my ($self, $one, $name, $group) = @_;

    $self->info("User: $name must belong to this primary group: ", $group);
    my $group_id = $self->get_resource_id($one, "group", $group);

    if (defined($group_id)) {
        my @users = $one->get_users(qr{^$name$});
        $self->warn("Detected administration group change for regular user: $name") if ($group_id == 0);
        foreach my $usr (@users) {
            my $out = $usr->chgrp($group_id);
            if (defined($out)) {
                $self->info("Changed user: $name primary group to: ", $group);
            } else {
                $self->error("Not able to change user: $name group to: ", $group);
            };
        }
    } else {
        $self->error("Requested OpenNebula group for user $name does not exist: ", $group);
    };
}

=pod

=back

=cut

1;
