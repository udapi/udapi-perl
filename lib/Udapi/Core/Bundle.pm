package Udapi::Core::Bundle;
use strict;
use warnings;
use Carp;
use List::Util qw(first any);
use Udapi::Core::Node;
use Udapi::Core::Node::Root;

my ($TREES, $ID, $NUMBER, $DOC);
BEGIN {
    ($TREES, $ID, $NUMBER, $DOC) = (0..10);
}

use Class::XSAccessor::Array {
    constructor => 'new',
    setters => {
        set_id => $ID,
        _set_document => $DOC,
        _set_number => $NUMBER,
    },
    getters => {
        id => $ID,
        document => $DOC,
        number => $NUMBER,
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
        $zone = '';
        $root->_set_zone($zone);
    } else {
        confess "'$zone' is not a valid zone name (/^[a-z-]*(_[A-Za-z0-9-])?\$/)" if $zone !~ /^[a-z-]*(_[A-Za-z0-9-])?$/;
        confess "'all' cannot be used as a zone name" if $zone eq 'all';
    }
    confess "Tree with zone '$zone' already exists in bundle " . $self->id
        if any {$zone eq $_->zone} @{$self->[$TREES]};

    $root->_set_bundle($self);
    push @{$self->[$TREES]}, $root;
    return;
}

sub _remove_tree {
    my ($self, $root) = @_;
    $self->[$TREES] = [grep {$_ != $root} @{$self->[$TREES]}];
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

sub remove {
    my ($self) = @_;
    $self->[$DOC]->_remove_bundle($self->[$NUMBER]);
    $self->destroy();
    return;
}

1;
