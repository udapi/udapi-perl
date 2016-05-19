package Udapi::Block::Util::FindBug;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';
use Storable qw(dclone);
use Udapi::Block::Write::CoNLLU;

has_ro block => (required=>1);

has_ro first_error_only => (default=>1);

sub process_document {
    my ($self, $doc) = @_;
    my $block_name = 'Udapi::Block::' . $self->block;
    eval "use $block_name; 1;" or confess "Can't use block $block_name !\n$@\n";
    my %params = (); # TODO params
    my $block;
    eval {
        $block = $block_name->new( \%params );
        1;
    } or confess "Error when initializing block $block_name\n\nEVAL ERROR:\t$@";

    my $doc_copy = dclone($doc);

    my @bundles = $doc_copy->bundles;
    foreach my $bundle_no (0..$#bundles){
        my $bundle = $bundles[$bundle_no];
        my $ok = eval {
            $block->process_bundle($bundle);
            1;
        };
        if (!$ok) {
            warn "Util::FingBug found a problem in bundle $bundle_no in block $block_name:\n<<$@>>\n";
            warn "Printing a minimal example to '".$self->filename . "'\n";
            my $writer = Udapi::Block::Write::CoNLLU->new(to=>'-');
            my @orig_bundles = $doc->bundles;
            foreach my $tree ($orig_bundles[$bundle_no]->trees){
                $writer->process_tree($tree);
            }
            return if $self->first_error_only;
        }
    }

    return;
}

1;

__END__
