package Udapi::Core::Bundle;
use strict;
use warnings;
use autodie;
use Carp;
use List::Util qw(any);
use Udapi::Core::Node;
use Udapi::Core::Node::Root;

my ($TREES, $ID, $DOC);
BEGIN {
    ($TREES, $ID, $DOC) = (0..10);
}

use Class::XSAccessor::Array {
    constructor => 'new',
    setters => {
        set_id => $ID,
        _set_document => $DOC,
    },
    getters => {
        id => $ID,
        document => $DOC,
    },
};

sub trees { return @{$_[0][$TREES]}; }

sub create_tree {
    my ($self, $zone) = @_;
    my $root = Udapi::Core::Node::Root->new($self);
    $root->_set_zone($zone);
    $self->add_tree($root);
    return $root;
}

sub add_tree {
    my ($self, $root) = @_;
    my $zone = $root->zone;
    if (!defined $zone){
        $zone = 'und';
        $root->_set_zone($zone);
    } else {
        confess "'$zone' is not a valid zone name" if $zone !~ /^[a-z-]+(_[A-Za-z0-9-])?$/;
        confess "'all' cannot be used as a zone name" if $zone eq 'all';
    }
    confess "Tree with zone '$zone' already exists in bundle " . $self->id
        if any {$zone eq $_->zone} @{$self->[$TREES]};

    $root->_set_bundle($self);
    push @{$self->[$TREES]}, $root;
    return;
}

sub get_tree {
    my ($self, $zone) = @_;
    return first {$zone eq $_->zone} @{$self->[$TREES]};
}

sub destroy {
    my ($self) = @_;
    foreach my $tree (@{$self->[$TREES]}){
        $tree->destroy();
    }
    undef @$self;
    return;
}

1;
