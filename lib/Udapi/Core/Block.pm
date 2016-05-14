package Udapi::Core::Block;
use Udapi::Core::Common;

has zones => ( is => 'ro', default => 'all' );

sub process_start {
}

sub process_end {
}

sub process_document {
    my ($self, $doc) = @_;

    foreach my $bundle ( $doc->bundles() ) {
        if ($self->_should_process_bundle($bundle)){
            $self->process_bundle($bundle);
        }
    }
    return;
}

sub _should_process_bundle {
    my ($self, $bundle) = @_;
    # TODO: if ( !$self->select_bundles || $self->_is_bundle_selected->{$bundle->number} );
    return 1;
}

sub _should_process_tree {
    my ($self, $tree) = @_;
    return 1 if $self->zones eq 'all';
    return 1 if any {$tree->zone eq $_} split /,/, $self->zones; # TODO allow regexes in zones, any {$tree->zone =~ /^$_$/}
    return 1 if $self->zones eq '' && $tree->zone eq '';
    return 0;
}

sub process_bundle {
    my ( $self, $bundle ) = @_;

    my @trees = $bundle->trees();
    foreach my $tree (@trees) {
        next if !$self->_should_process_tree($tree);
        $self->process_tree( $tree );
    }
    return;
}

sub process_tree {
    my ( $self, $tree ) = @_;

    foreach my $node ($tree->descendants()){
        $self->process_node($node);
    }
    return;
}

sub process_node {
    my ( $self, $node ) = @_;
    confess "Block $self does not implement (override) any of the process_* methods";
}

1;