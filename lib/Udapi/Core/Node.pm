package Udapi::Core::Node;
use strict;
use warnings;
use Carp qw(confess cluck);

my @ATTRS;
my (
    $ORD, $ROOT, $PARENT, $FIRSTCHILD, $NEXTSIBLING, $MISC, # both root and node
    $FORM, $LEMMA, $UPOS, $XPOS, $FEATS, $DEPREL, $DEPS,    # node only
);

# The following variables are used in "use Class::XSAccessor::Array {...}",
# so they must be initialized within an BEGIN block (but defined outside).
BEGIN {
    @ATTRS = qw(ord root parent firstchild nextsibling misc
                form lemma upos xpos feats deprel deps);
    ($ORD, $ROOT, $PARENT, $FIRSTCHILD, $NEXTSIBLING, $MISC) = (0..5);
    ($FORM, $LEMMA, $UPOS, $XPOS, $FEATS, $DEPREL, $DEPS)    = (6..12);
}

my %INDEX_OF_ATTR = (
    ord    => $ORD,
    form   => $FORM,
    lemma  => $LEMMA,
    upos   => $UPOS,
    xpos   => $XPOS,
    feats  => $FEATS,
    deprel => $DEPREL,
    deps   => $DEPS,
    misc   => $MISC,
);

use Class::XSAccessor::Array {
    setters => { map {('set_'.$ATTRS[$_] => $_)} ($MISC..$DEPS) },
    getters => { map {(       $ATTRS[$_] => $_)} (0..12) },
};

# Some methods need access to $self->[$ROOT][$DESCENDANTS],
# but we cannot use $self->[$ROOT]->descendants() which returns an array,
# we need the internal hashref, so we can modify it.
# $self->[$ROOT][$BUNDLE] is faster than $self->[$ROOT]->bundle;
my ($DESCENDANTS, $BUNDLE, $ZONE) = (6..8);


sub new {
    my ($class, %h) = @_;
    my $array = [ map {$h{$_}} @ATTRS];
    return bless $array, $class;
}

sub set_parent {
    my ($self, $parent, $args) = @_;
    confess('set_parent(undef) not allowed') if !defined $parent;

    # Check cycles
    # if ($self == $parent || $parent->is_descendant_of($self)) {...}
    # but we can do it faster without extra sub call.
    if ($self == $parent){
        return if $args && $args->{cycles} eq 'skip';
        my $b_id = $self->bundle->bundle_id;
        my $n_id = $self->ord;
        confess "Bundle $b_id: Attempt to set parent of $n_id to itself (cycle).";
    }
    if ($self->[$FIRSTCHILD]){
        my $grandpa = $parent->[$PARENT];
        while ($grandpa) {
            if ($grandpa == $self){
                return if $args && $args->{cycles} eq 'skip';
                my $b_id = $self->bundle->bundle_id;
                my $n_id = $self->ord;
                my $p_id = $parent->ord;
                confess "Bundle $b_id: Attempt to set parent of $n_id to the node $p_id, which would lead to a cycle.";
            }
            $grandpa = $grandpa->[$PARENT];
        }
    }

    # Disconnect the node from its original parent
    my $origparent = $self->[$PARENT];
    if ($origparent){
        my $node = $origparent->[$FIRSTCHILD];
        if ($self == $node) {
            $origparent->[$FIRSTCHILD] = $self->[$NEXTSIBLING];
        } else {
            while ($node && $self != $node->[$NEXTSIBLING]){
                $node = $node->[$NEXTSIBLING];
            }
            $node->[$NEXTSIBLING] = $self->[$NEXTSIBLING] if $node;
        }
    }

    # If the node was not part of any tree (create_child() uses internally set_parent()),
    # attach it to its parent's tree (set the root, ord and add it as the last node of the tree).
    if (!$self->[$ROOT]){
        my $root = $parent->[$ROOT];
        $self->[$ROOT] = $root;
        # push returns the new number of elements in the array,
        # We need $root->[$DESCENDANTS][$n][$ORD] == $n+1, for any $n.
        $self->[$ORD] = push @{$root->[$DESCENDANTS]}, $self;
    }

    # Attach the node to its parent and linked list of siblings.
    $self->[$PARENT] = $parent;
    $self->[$NEXTSIBLING] = $parent->[$FIRSTCHILD];
    $parent->[$FIRSTCHILD] = $self;
    return;
}

sub remove {
    my ($self, $arg_ref) = @_;
    my $root = $self->[$ROOT];
    my $parent = $self->[$PARENT];
    if ($arg_ref && $self->[$FIRSTCHILD]){
        my $what_to_do = $arg_ref->{children} || '';
        if ($what_to_do =~ /^rehang/){
            foreach my $child (Udapi::Core::Node::children($self)){
                Udapi::Core::Node::set_parent($child, $parent);
            }
        }
        if ($what_to_do =~ /warn$/){
            warn $self->address . " is being removed by remove({children=>$what_to_do}), but it has (unexpected) children";
        }
    }

    my @to_remove = sort {$a->[$ORD] <=> $b->[$ORD]} ($self, Udapi::Core::Node::_descendantsF($self));
    my ($first_ord, $last_ord) = ($to_remove[0]->[$ORD], $to_remove[-1]->[$ORD]);
    my $all_nodes = $root->[$DESCENDANTS];

    # Remove the nodes from $root->[$DESCENDANTS].
    # projective subtrees can be deleted faster
    if ($last_ord - $first_ord + 1 == @to_remove){
        splice @$all_nodes, $first_ord - 1, $last_ord - $first_ord + 1;
    }
    # non-projective subtrees must iterated
    else {
        my $remove_i = 1;
        my @new_all_nodes = @$all_nodes[0..$first_ord-2];
        for my $all_i ($first_ord .. $#{$all_nodes}){
            if (($to_remove[$remove_i]||0) == $all_nodes->[$all_i]){
                $remove_i++;
            } else {
                push @new_all_nodes, $all_nodes->[$all_i];
            }
        }
        $root->[$DESCENDANTS] = $all_nodes = \@new_all_nodes
    }

    # Update ord of the following nodes in the tree
    for my $i ($first_ord-1..$#{$all_nodes}){
        $all_nodes->[$i]->[$ORD] = $i+1;
    }

    # Disconnect the node from its parent (& siblings) and delete all attributes
    #$self->cut();
    my $node = $parent->[$FIRSTCHILD];
    if ($self == $node) {
        $parent->[$FIRSTCHILD] = $self->[$NEXTSIBLING];
    } else {
        while ($node && $self != $node->[$NEXTSIBLING]){
            $node = $node->[$NEXTSIBLING];
        }
        $node->[$NEXTSIBLING] = $self->[$NEXTSIBLING] if $node;
    }

    # By reblessing we make sure that
    # all methods called on removed nodes will result in fatal errors.
    foreach my $node (@to_remove){
        undef @$node;
        bless $node, 'Udapi::Core::Node::Removed';
    }
    return;
}

sub children {
    my ($self, $args) = @_;
    my @children = ();
    my $child = $self->[$FIRSTCHILD];
    while ($child) {
        push @children, $child;
        $child = $child->[$NEXTSIBLING];
    }
    if ($args) {
        push @children, $self if $args->{add_self};
        if ($args->{first_only}){
            my $first = pop @children;
            foreach my $node (@children) {
                $first = $node if $node->[$ORD] < $first->[$ORD];
            }
            return $first;
        }
        if ($args->{last_only}){
            my $last = pop @children;
            foreach my $node (@children) {
                $last = $node if $node->[$ORD] > $last->[$ORD];
            }
            return $last;
        }
    }
    @children = sort {$a->[$ORD] <=> $b->[$ORD]} @children;
    return @children;
}

# No $args, no sort, fastest
sub _childrenF {
    #my ($self) = @_;
    my @children = ();
    my $child = $_[0][$FIRSTCHILD];
    while ($child) {
        push @children, $child;
        $child = $child->[$NEXTSIBLING];
    }
    return @children;
}

sub create_child {
    my $self = shift;
    my $child = Udapi::Core::Node->new(@_); #ref($self)->new(@_);
    Udapi::Core::Node::set_parent($child, $self);
    return $child;
}

# No $args, no sort, fastest
sub _descendantsF {
    #my ($self) = @_;
    my @stack = $_[0][$FIRSTCHILD] || return;
    my @descs = ();
    while (@stack) {
        my $node = pop @stack;
        push @descs, $node;
        push @stack, $node->[$NEXTSIBLING] || ();
        push @stack, $node->[$FIRSTCHILD] || ();
    }
    return @descs;
}

# The official API method, used e.g. my @d = $n->descendants({add_self=>1, first_only=>1}).
sub descendants {
    #my ($self, $args) = @_;
    goto &Udapi::Core::Node::_descendants if !$_[1]; # !$args (most common case)
    @_ = ($_[0], $_[1]{add_self}, $_[1]{first_only}, $_[1]{last_only}, $_[1]{except});
    goto &Udapi::Core::Node::_descendants;
}

sub _descendants {
    my ($self, $add_self, $first_only, $last_only, $except) = @_;

    $except ||= 0;
    return () if $self == $except;
    my @descs = ();
    my @stack = $self->[$FIRSTCHILD] || ();
    my $node;
    while (@stack) {
        $node = pop @stack;
        push @stack, $node->[$NEXTSIBLING] || ();
        next if $node == $except;
        push @descs, $node;
        push @stack, $node->[$FIRSTCHILD] || ();
    }

    push @descs, $self if $add_self;
    if ($first_only){
        my $first = pop @descs;
        foreach my $node (@descs) {
            $first = $node if $node->[$ORD] < $first->[$ORD];
        }
        return $first;
    }
    if ($last_only){
        my $last = pop @descs;
        foreach my $node (@descs) {
            $last = $node if $node->[$ORD] > $last->[$ORD];
        }
        return $last;
    }

    @descs = sort {$a->[$ORD] <=> $b->[$ORD]} @descs;
    return @descs;
}

sub is_descendant_of {
    return 0 if !$_[1][$FIRSTCHILD];
    my $parent = $_[0][$PARENT];
    while ($parent) {
        return 1 if $parent == $_[1];
        $parent = $parent->[$PARENT];
    }
    return 0;
}

sub zone { $_[0]->[$ROOT][$ZONE]; }

sub bundle { $_[0]->[$ROOT][$BUNDLE]; }

sub document { $_[0]->[$ROOT][$BUNDLE]->document; }

sub address { $_[0]->[$ROOT]->address . '#' . $_[0]->[$ORD]; }

sub is_root { return 0; }

sub is_leaf { return !$_[0]->[$FIRSTCHILD];}

sub prev_node {
    my ($self) = @_;
    my $ord = $self->[$ORD] - 1;
    return undef if $ord < 0;
    return $self->[$ROOT] if $ord == 0;
    return $self->[$ROOT][$DESCENDANTS][$ord-1];
}

sub next_node {
    my ($self) = @_;
    # Note that @all_nodes[$n]->ord == $n+1
    return $self->[$ROOT][$DESCENDANTS][$self->[$ORD]];
}

sub shift_before_node {
    my ( $self, $reference_node, $arg_ref ) = @_;
    return Udapi::Core::Node::_shift_to_node($self, $reference_node, 0, 0, $arg_ref);
}

sub shift_after_node {
    my ( $self, $reference_node, $arg_ref ) = @_;
    return Udapi::Core::Node::_shift_to_node($self, $reference_node, 1, 0, $arg_ref);
}

sub shift_before_subtree {
    my ( $self, $reference_node, $arg_ref ) = @_;
    return Udapi::Core::Node::_shift_to_node($self, $reference_node, 0, 1, $arg_ref);
}

sub shift_after_subtree {
    my ( $self, $reference_node, $arg_ref ) = @_;
    return Udapi::Core::Node::_shift_to_node($self, $reference_node, 1, 1, $arg_ref);
}

# This method does the real work for all shift_* methods.
# However, due to unfriendly name and arguments it's not public.
sub _shift_to_node {
    my ( $self, $reference_node, $after, $subtree, $args) = @_;

    # $node->shift_after_node($node) should result in no action.
    return if !$subtree && $self == $reference_node;

    # Extract the optional arguments from $args.
    my ($without_children, $skip_if_descendant);
    if ($args){
        $without_children = $args->{without_children};
        $skip_if_descendant = $args->{skip_if_descendant};
    }
    $without_children = 1 if !$self->[$FIRSTCHILD];

    # If $reference_node is a descendant of $self and without_children=>1 was not used
    # we should raise an exception (which could be ignored with skip_if_descendant=>1).
    if (!$without_children && Udapi::Core::Node::is_descendant_of($reference_node, $self)){
        return if $skip_if_descendant;
        confess '$reference_node is a descendant of $self.'
                . ' Maybe you have forgotten {without_children=>1}. ' . "\n";
    }

    # For shift_subtree_* methods, we need to find the real reference node first.
    if ($subtree) {
        if ($without_children) {
            my $new_ref;
            if ($after) {
                foreach my $node ($reference_node, Udapi::Core::Node::_descendantsF($reference_node)){
                    next if $node == $self;
                    $new_ref = $node if !$new_ref || ($node->[$ORD] > $new_ref->[$ORD]);
                }
            } else {
                foreach my $node ($reference_node, Udapi::Core::Node::_descendantsF($reference_node)){
                    next if $node == $self;
                    $new_ref = $node if !$new_ref || ($node->[$ORD] < $new_ref->[$ORD]);
                }
            }
            return if !$new_ref;
            $reference_node = $new_ref;
        } else {
            $reference_node = Udapi::Core::Node::_descendants($reference_node, 1, !$after, $after, $self);
        }
    }

    # Convert shift_after_* to shift_before_*.
    my $root = $self->[$ROOT];
    my $all_nodes = $root->[$DESCENDANTS];
    my $reference_ord = $reference_node->[$ORD];
    $reference_ord++ if $after;

    # without_children means moving just one node, which is easier
    if ($without_children) {
        my $my_ord = $self->[$ORD];
        if ($reference_ord > $my_ord+1){
             foreach my $ord ($my_ord..$reference_ord-2){
                 $all_nodes->[$ord-1] = $all_nodes->[$ord];
                 $all_nodes->[$ord-1][$ORD] = $ord;
             }
            $all_nodes->[$reference_ord-2] = $self;
            $self->[$ORD] = $reference_ord-1;
        } elsif ($reference_ord < $my_ord){
            foreach my $ord (reverse $reference_ord+1 .. $my_ord){
                $all_nodes->[$ord-1] = $all_nodes->[$ord-2];
                $all_nodes->[$ord-1][$ORD] = $ord;
            }
            $all_nodes->[$reference_ord-1] = $self;
            $self->[$ORD] = $reference_ord;
        }
        return;
    }

    # Which nodes are to be moved?
    # $self and all its descendants
    my @nodes_to_move = Udapi::Core::Node::_descendants($self, 1);
    my $first_ord = $nodes_to_move[0][$ORD];
    my $last_ord = $nodes_to_move[-1][$ORD];

    # If there are no "gaps" in @nodes_to_move (e.g. when it is projective)
    # we can make the shifting a bit faster and simpler.
    if ($last_ord - $first_ord == $#nodes_to_move){
        # First,...
        my $trg_ord = $last_ord;
        my $src_ord = $first_ord-1;
        while ($src_ord >= $reference_ord) {
            $all_nodes->[$trg_ord-1] = $all_nodes->[$src_ord-1];
            $all_nodes->[$trg_ord-1][$ORD] = $trg_ord;
            $trg_ord--;
            $src_ord--;
        }

        # Second,...
        $trg_ord = $first_ord;
        $src_ord = $last_ord+1;
        while ($src_ord < $reference_ord) {
            $all_nodes->[$trg_ord-1] = $all_nodes->[$src_ord-1];
            $all_nodes->[$trg_ord-1][$ORD] = $trg_ord;
            $trg_ord++;
            $src_ord++;
        }

        # Third, move @nodes_to_move to $trg_ord RIGHT-ward.
        $trg_ord = $reference_ord if $reference_ord < $first_ord;
        foreach my $node (@nodes_to_move){
            $all_nodes->[$trg_ord-1] = $node;
            $node->[$ORD] = $trg_ord++;
        }
        return;
    }

    # First, move a node from position $src_ord to position $trg_ord RIGHT-ward.
    # $src_ord iterates decreasingly over nodes which are not moving.
    my $trg_ord = $last_ord;
    my $src_ord = $last_ord-1;
    my $mov_ord = $#nodes_to_move-1;
    RIGHTSWIPE:
    while ($src_ord >= $reference_ord) {
        while ($all_nodes->[$src_ord-1] == $nodes_to_move[$mov_ord]){
            $src_ord--;
            $mov_ord--;
            last RIGHTSWIPE if $src_ord < $reference_ord;
        }
        $all_nodes->[$trg_ord-1] = $all_nodes->[$src_ord-1];
        $all_nodes->[$trg_ord-1][$ORD] = $trg_ord;
        $trg_ord--;
        $src_ord--;
    }

    # Second, move a node from position $src_ord to position $trg_ord LEFT-ward.
    # $src_ord iterates increasingly over nodes which are not moving.
    $trg_ord = $first_ord;
    $src_ord = $first_ord+1;
    $mov_ord = 1;
    LEFTSWIPE:
    while ($src_ord < $reference_ord) {
        while ($mov_ord < @nodes_to_move && $all_nodes->[$src_ord-1] == $nodes_to_move[$mov_ord]) {
            $src_ord++;
            $mov_ord++;
            last LEFTSWIPE if $src_ord >= $reference_ord;
        }
        $all_nodes->[$trg_ord-1] = $all_nodes->[$src_ord-1];
        $all_nodes->[$trg_ord-1][$ORD] = $trg_ord;
        $trg_ord++;
        $src_ord++;
    }

    # Third, move @nodes_to_move to $trg_ord RIGHT-ward.
    $trg_ord = $reference_ord if $reference_ord < $first_ord;
    foreach my $node (@nodes_to_move){
        $all_nodes->[$trg_ord-1] = $node;
        $node->[$ORD] = $trg_ord++;
    }
    return;
}

sub destroy {
    my ($self) = @_;
    undef @$self;
    return;
}

sub get_attrs {
    my $self = shift;
    my $change_undefs_to;
    if (ref $_[-1]) {
        my $arg_ref       = pop @_;
        $change_undefs_to = $arg_ref->{undefs};
    }

    my @values = map {$self->[$INDEX_OF_ATTR{$_} // confess "Unknown attribute '$_'"]} @_;

    return @values if !defined $change_undefs_to;
    return map {defined $_ ? $_ : $change_undefs_to} @values;
}

sub precedes {
    my ( $self, $another_node ) = @_;
    return $self->[$ORD] < $another_node->[$ORD];
}

use Udapi::Block::Write::TextModeTrees;

sub print_subtree {
    my $self = shift;
    Udapi::Block::Write::TextModeTrees->new(@_)->process_tree($self);
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Udapi::Core::Node - representation of a node in a dependency tree

=head1 SYNOPSIS

 # New nodes via constructor (used only in special cases)
 use Udapi::Core::Node;
 my $node = Udapi::Core::Node->new(
   form=>'dogs', lemma=>'dog', upos=>'NOUN', xpos=>'NNS',
   feats=>'Number=Plur', deprel='nubj', misc=>'SpaceAfter=No');

 # New nodes via create_child (the usual way)
 my $root = $bundle->create_tree($zone);
 my $node = $root->create_child(form=>'dogs', lemma=>'dog');
 my $child = $node->create_child(form=>'old', upos=>'ADJ');

 # Access to attributes
 my $lemma = $node->lemma;
 my ($deprel, $deps) = $node->get_attrs('deprel', 'deps', {undefs=>''});
 $child->set_lemma('old');

 # Access to containers and meta-info
 my $bundle   = $node->bundle;
 my $doc      = $node->document;
 my $zone     = $node->zone;    # e.g. en_gold
 my $address  = $node->address; # e.g. 123/en_gold#4

 # Access to topology
 my $root     = $node->root;
 my $boolean  = $node->is_root;
 my $parent   = $node->parent;
 my @children = $node->children;
 my @descs    = $node->descendants;
 my $first_ch = $node->children({first_only=>1});
 my $last_des = $node->descendants({last_only=>1});
 if (!$node->is_descendant_of($another_node)){
     $another_node->set_parent($node);
 }
 $child->remove(); # delete with all its descendants
 $child->remove({children=>'rehang_warn'});

 # Access to word order
 my $nth_token_in_tree = $node->ord;
 if ($node->precedes($another_node)){
     $node->shift_after_node($another_node);
 }
 $node->shift_before_subtree($another_node, {without_children=>1});
 $another_node = $node->next_node;
 $another_node = $node->prev_node;


=head1 DESCRIPTION

This class represents a Udapi node.
Udapi trees (contained in bundles) are formed by nodes and edges.
Attributes can be stored only in nodes.
The (technical) root of the tree is of type L<Udapi::Core::Node::Root>,
but all the node's methods can be called also on root.

=head2 Construction

=head3 new

C<my $node = Udapi::Core::Node-E<gt>new(%attributes);>

Nodes can be created with the constructor C<new>,
but such nodes do not have any parent and are not part of any tree,
so they should be first added to some tree using C<set_parent>,
otherwise some methods may not work as expected.
The C<%attributes> is a hash of attribute names and values.
Possible attribute names are:

=over

=item

regular L<CoNLL-U|http://universaldependencies.org/format.html> attributes:
B<form, lemma, upos, xpos, feats, deprel, deps, misc>
Currently, all are treated as strings.
(In future, B<feats>, B<deps> and B<misc> may become structured).

=item

B<ord> -- ordinal number of the node, corresponding to the first column (I<ID>)
in CoNLL-U files. That is 1-based index.
The technical root has ord=0.

=item

internal Udapi attributes: B<root, parent, firstchild, nextsibling>
These should not be accessed directly.

=back


=head1 AUTHOR

Martin Popel E<lt>popel@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
