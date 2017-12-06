#${PMpre} NCM::Component::OpenNebula::Image${PMpost}

=head1 NAME

C<NCM::Component::OpenNebula::Image> adds C<OpenNebula> C<VM> images 
support to C<NCM::Component::OpenNebula>.

=head2 Public methods

=over

=item get_images

Gets the image template from C<TT> file
and gathers the image names (C<<fqdn>_<vdx>>)
and datastore names to store the new images.

=cut

sub get_images
{
    my ($self, $config) = @_;
    my $all_images = $self->process_template_aii($config, "imagetemplate");
    my %res;

    my @tmp = split(qr{^DATASTORE\s+=\s+(?:"|')(\S+)(?:"|')\s*$}m, $all_images);

    while (my ($image, $datastore) = splice(@tmp, 0, 2)) {
        my $imagename = $1 if ($image =~ m/^NAME\s+=\s+(?:"|')(.*?)(?:"|')\s*$/m);
        if ($datastore && $imagename) {
            $self->verbose("Detected imagename $imagename with datastore $datastore");
            $res{$imagename}{image} = $image;
            $res{$imagename}{datastore} = $datastore;
            $self->debug(3, "This is image template $imagename: $image");
        } else {
            # Shouldn't happen; fields are in TT
            $self->error("No datastore and/or imagename for image data $image.");
        };
    }
    return %res;
}

=item remove_or_create_vm_images

Creates new C<VM> images and it detects if the image is 
already available or not. 
Also it removes images if the remove flag is set.

=cut

sub remove_or_create_vm_images
{
    my ($self, $one, $createimage, $imagesref, $permissions, $remove) = @_;
    my (@rimages, @nimages, @qimages);

    foreach my $imagename (sort keys %$imagesref) {
        my $imagedata = $imagesref->{$imagename};
        $self->info ("Checking image: $imagename");
        push(@qimages, $imagename);
        if ($remove) {
            $self->remove_vm_images($one, $imagename, \@rimages);
        } elsif ($createimage) {
            $self->create_vm_images($one, $imagename, $imagedata, $permissions, \@nimages);
        };
    }
    # Check created/removed image lists
    if ($remove) {
        my $diff = $self->check_vm_images_list(\@rimages, \@qimages);
        if ($diff) {
            # if diff some of the requested images were not removed
            $self->error("Removing these VM images: ", join(', ', @qimages));
        }
    } else {
        my $diff = $self->check_vm_images_list(\@nimages, \@qimages);
        if ($diff) {
             # if diff some of the requested images were not created
            $self->error("Creating these VM images: ", join(', ', @qimages));
        }
    }
}

=item create_vm_images

Creates new C<VM> images.

=cut

sub create_vm_images
{
    my ($self, $one, $imagename, $imagedata, $permissions, $ref_nimages) = @_;

    my $newimage;
    if ($self->is_one_resource_available($one, "image", $imagename)) {
        $self->warn("Image: $imagename is already available from OpenNebula. ",
                    "Please remove this image first if you want to generate a new one from scratch.");
        return;
    } else {
        if ($self->is_one_resource_available($one, "datastore", $imagedata->{datastore})) {
            $newimage = $one->create_image($imagedata->{image}, $imagedata->{datastore});
        } else {
            $self->error("Not found requested datastore: ", $imagedata->{datastore});
        }
    }
    if ($newimage) {
        $self->info("Created new VM image ID: ", $newimage->id);
        if ($permissions) {
            $self->change_permissions($one, "image", $newimage, $permissions);
        };
        push(@$ref_nimages, $imagename);
    } else {
        $self->error("VM image: $imagename is not available");
    }
}

=item remove_vm_images

Removes C<VM> images.
Updates C<$ref_rimages> to track the removed images.

=cut

sub remove_vm_images
{
    my ($self, $one, $imagename, $ref_rimages) = @_;

    foreach my $img ($one->get_images(qr{^$imagename$})) {
        if ($img->{extended_data}->{TEMPLATE}->[0]->{QUATTOR}->[0]) {
            # It's safe, we can remove the image
            $self->info("Removing VM image: $imagename");
            my $id = $img->delete();
            $self->is_timeout($one, "image", $imagename);

            if ($id) {
                push(@{$ref_rimages}, $imagename);
            } else {
                $self->error("VM image: $imagename was not removed");
            }
        } else {
            $self->info("No QUATTOR flag found for VM image: $imagename");
        }
    }
}

=item check_vm_images_list

Checks the difference between two image lists
to detect if the images were correctly created/removed.

=cut

sub check_vm_images_list
{
    my ($self, $myimages, $qimages) = @_;

    my $required = Set::Scalar->new(@{$qimages});
    my $current = Set::Scalar->new(@{$myimages});
    return $required->symmetric_difference($current);
}


=pod

=back

=cut

1;
