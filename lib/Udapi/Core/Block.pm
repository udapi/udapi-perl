package Udapi::Core::Block;
use Udapi::Core::Common;

has zones => ( is => 'ro', default => 'all' );

sub process_start {
}

sub process_end {
}

sub process_document {
    my ($self, $doc) = @_;

    my $bundleNo = 1;
    foreach my $bundle ( $doc->bundles() ) {
        if ($self->_should_process_bundle($bundle, $bundleNo)){
            $self->process_bundle($bundle, $bundleNo);
        }
        $bundleNo++;
    }
    return;
}

sub _should_process_bundle {
    my ($self, $bundle, $bundleNo) = @_;
    # TODO: if ( !$self->select_bundles || $self->_is_bundle_selected->{$bundleNo} );
    return 1;
}

sub _should_process_tree {
    my ($self, $tree) = @_;
    return 1 if $self->zones eq 'all';
    return 1 if any {$tree->zone eq $_} split /,/, $self->zones; # TODO allow regexes in zones, any {$tree->zone =~ /^$_$/}
    return 0;
}

sub process_bundle {
    my ( $self, $bundle, $bundleNo ) = @_;

    my @trees = $bundle->trees();
    foreach my $tree (@trees) {
        next if !$self->_should_process_tree($tree);
        $self->process_tree( $tree, $bundleNo );
    }
    return;
}

sub process_tree {
    my ( $self, $tree, $bundleNo ) = @_;

    foreach my $node ($tree->descendants()){
        $self->process_node($node, $bundleNo);
    }
    return;
}

sub process_node {
    my ( $self, $node, $bundleNo ) = @_;
    confess "Block $self does not implement (override) any of the process_* methods";
}

1;