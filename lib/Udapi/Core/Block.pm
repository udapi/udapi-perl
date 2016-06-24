package Udapi::Core::Block;
use Udapi::Core::Common;

has_ro zones => ( default => 'all' );

has_ro bundles => ( default => 'all',
    doc  => 'apply process_bundle only on the specified bundles,'
          . ' e.g. "1-4,6,8-12". The default is "all". Useful for debugging.',
);
has_ro _is_bundle_selected => (writer=>'_set_is_bundle_selected');

sub BUILD {
    my ($self) = @_;
    if ( $self->bundles ne 'all' ) {
        confess 'bundles=' . $self->bundles . ' does not match /^\d+(-\d+)?(,\d+(-\d+)?)*$/'
            if $self->bundles !~ /^\d+(-\d+)?(,\d+(-\d+)?)*$/;
        my %selected;
        foreach my $span ( split /,/, $self->bundles ) {
            if ( $span =~ /(\d+)-(\d+)/ ) {
                @selected{ $1 .. $2 } = ( $1 .. $2 );
            }
            else {
                $selected{$span} = 1;
            }
        }
        $self->_set_is_bundle_selected( \%selected );
    }
    return;
}

sub process_start {}
sub process_end {}
sub before_process_document {}
sub after_process_document {}
sub before_process_bundle {}
sub after_process_bundle {}

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
    return 1 if $self->bundles eq 'all';
    return 1 if $self->_is_bundle_selected->{$bundle->number};
    return 0;
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

    $self->before_process_bundle($bundle);
    my @trees = $bundle->trees();
    foreach my $tree (@trees) {
        next if !$self->_should_process_tree($tree);
        $self->process_tree( $tree );
    }
    $self->after_process_bundle($bundle);
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
