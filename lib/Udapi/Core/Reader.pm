package Udapi::Core::Reader;
use Udapi::Core::Common;
use Udapi::Core::Files;
extends 'Udapi::Core::Block';
with 'Udapi::Core::Role::Reader';

has_ro zone => (
    default => 'keep',
    doc => 'What should be the zone of the new trees.'
         . ' Default="keep" means keep the zone saved in the input file (or use "und" if no zone is specified).'
);

has_ro bundles_per_doc => (
    default => 0,
    doc => 'Create a new document after each N bundles read. Default=0 means unlimited.'
);

has_rw from => (
    doc => 'space or comma separated list of filenames to be loaded',
    default => '-',
);

has_ro _files => (
    writer => '_set_files',
    handles => [qw(filehandle filename file_number next_filehandle)],
);

has_ro encoding => ( default  => 'utf8' );

has_rw _buffer => ();

sub BUILD {
    my ($self) = @_;
    $self->_set_files(Udapi::Core::Files->new(string=>$self->from, encoding=>$self->encoding));
    return;
}

sub read_tree {
    confess 'Method "read_tree" must be implemented in descendants of Udapi::Core::Reader';
}

sub is_multizone_reader {
    return 1;
}

sub process_document {
    my ($self, $doc) = @_;

    my @orig_bundles = $doc->bundles();
    my $self_zone = $self->zone;
    my $self_bpd = $self->bundles_per_doc;
    my $bundle;
    my $last_bundle_id = '';

    # There may be a tree left in the buffer when reading the last doc.
    if ($self->_buffer) {
        $bundle = @orig_bundles ? shift @orig_bundles : $doc->create_bundle();
        $bundle->add_tree($self->_buffer);
        $self->_set_buffer(undef);
    }

    $self->next_filehandle;

    while (my $root = $self->read_tree($doc)){
        my $add_to_the_last_bundle = 0;

        my $sent_id = $root->sent_id;
        if (defined $sent_id) {
            my ($bundle_id, $zone) = split /\//, $sent_id;
            if (defined $zone){
                confess "'$zone' is not a valid zone name (from sent_id='$sent_id')"
                    if $zone !~ /^[a-z-]+(_[A-Za-z0-9-]+)?$/;
                $root->_set_zone($zone);
            }
            $add_to_the_last_bundle = 1 if $bundle_id eq $last_bundle_id;
            $last_bundle_id = $bundle_id;
            $root->set_id(undef);
        }

        if ($self_zone ne 'keep'){
            $root->_set_zone($self_zone);
        }

        # assign new/next bundle to $bundle if needed
        if (!$bundle || !$add_to_the_last_bundle){
            if ($self_bpd && $bundle && $self_bpd == $bundle->number){
                $self->_set_buffer($root);
                warn "bundles_per_doc=$self_bpd but the doc already contained "
                      . scalar(@orig_bundles) . ' bundles' if @orig_bundles;
                return;
            }

            if (@orig_bundles){
                $bundle = shift @orig_bundles;
                if ($last_bundle_id && $last_bundle_id ne $bundle->bundle_id){
                    warn 'Mismatch in bundle IDs: '.$bundle->bundle_id. " vs. $last_bundle_id. Keeping the former one.";
                }
            } else {
                $bundle = $doc->create_bundle();
                $bundle->set_id($last_bundle_id) if $last_bundle_id ne '';
            }
        }

        $bundle->add_tree($root);

        # If bundles_per_doc is set and we have read the specified number of bundles,
        # we should end the current document and return.
        # However, if the reader supports reading multiple zone, we can never know
        # if the current bundle has ended or there will be another tree for this bundle.
        # So in case of multizone readers we need to read one extra tree
        # and store it in the buffer (and include it into the next document).
        return if $self_bpd && $self_bpd == $bundle->number && !$self->is_multizone_reader;
    }

    return;
}

1;
