package Udapi::Core::Node::Root;
use strict;
use warnings;
use Carp qw(confess cluck);
use List::Util qw(any);

my @ATTRS;
my (
    $ORD, $ROOT, $PARENT, $FIRSTCHILD, $NEXTSIBLING, $MISC, # both root and node
    $DESCENDANTS, $BUNDLE, $ZONE, $SENTENCE, $ID            # root only
);

BEGIN {
    @ATTRS = qw(ord root parent firstchild nextsibling misc
                descendants bundle zone sentence id);
    ($ORD, $ROOT, $PARENT, $FIRSTCHILD, $NEXTSIBLING, $MISC) = (0..5);
    ($DESCENDANTS, $BUNDLE, $ZONE, $SENTENCE, $ID)           = (6..10);
}

use Class::XSAccessor::Array {
    setters => { _set_zone=>$ZONE, _set_bundle=>$BUNDLE, set_misc=>$MISC, set_sentence=>$SENTENCE, set_id=>$ID },
    getters => { zone=>$ZONE, bundle=>$BUNDLE, misc=>$MISC, sentence=>$SENTENCE, id=>$ID },
};

sub new {
    my ($class, $bundle) = @_;
    my $root = bless [], $class;
    $root->[$DESCENDANTS] = [];
    $root->[$ORD] = 0;
    $root->[$BUNDLE] = $bundle;
    $root->[$ROOT] = $root;
    return $root;
}

sub set_zone {
    my ($self, $zone) = @_;
    confess "'$zone' is not a valid zone name" if $zone !~ /^[a-z-]+(_[A-Za-z0-9-])?$/;
    confess "'all' cannot be used as a zone name" if $zone eq 'all';
    my $bundle = $self->[$BUNDLE];
    confess "Tree with zone '$zone' already exists in bundle " . $bundle->id
        if $bundle && any {$zone eq $_->zone} $bundle->trees;
    $self->[$ZONE] = $zone;
    return;
}

# The following methods are well defined for root
# (eventhough the well-defined value for parent() is 'undef').
sub parent {return undef;}
sub root {return $_[0];}
sub is_root {return 1;}
sub ord {return 0;}
sub document {return $_[0][$BUNDLE]->document;}

sub descendants {
    #my ($self, $args) = @_;
    return @{$_[0][$DESCENDANTS]} if !$_[1]; # !$args (most common case)
    if ($_[1]{except}){
        @_ = ($_[0], $_[1]{add_self}, $_[1]{first_only}, $_[1]{last_only}, $_[1]{except});
        goto &Udapi::Core::Node::_descendants;
    }
    if ($_[1]{first_only}){
        return $_[0] if $_[1]{add_self};
        return $_[0]->[$DESCENDANTS][0];
    }
    return $_[0]->[$DESCENDANTS][-1] if $_[1]{last_only};
    return ($_[0], @{$_[0]->[$DESCENDANTS]}) if $_[1]{add_self};
    confess 'unknown option for descendants(): '. %{$_[1]};
}

*_descendantsF = \&descendants;
*children = \&Udapi::Core::Node::children;

sub next_node { return $_[0]->[$DESCENDANTS][1]; }
sub prev_node { return undef; }
sub precedes { return 1;}
sub is_descendant_of { return 0; }

# The root is a technical node which has no CoNLL-U attributes.
# However, imagine a feature extraction code:
# foreach $node ($root->descendants) {
#    say $node->form . "-" . $node->parent->form;
# }
# It is useful if even the root returns some special value.
# Otherwise, we would have to write:
#   say $node->form . "-" . ($node->parent->is_root ? '<ROOT>' : $node->parent->form);
#

sub form {return '<ROOT>';}
sub lemma {return '<ROOT>';}
sub upos {return '<ROOT>';}
sub xpos {return '<ROOT>';}
sub feats {return '<ROOT>';} # TODO: empty feats object
sub deprel {return '<ROOT>';}
sub deps {return '<ROOT>';}

sub get_attrs {
    my $self = shift;
    return map {
          $_ eq 'ord'    ? 0
        : $_ eq 'misc'   ? $self->[$MISC]
        : /^(form|lemma|[ux]pos|feats|deprel|deps)$/ ? '<ROOT>'
        : confess "Unknown attribute '$_'";
    } @_;
}

sub create_child {
    my $self = shift;
    my $child = Udapi::Core::Node->new(@_);
    Udapi::Core::Node::set_parent($child, $self);
    return $child;
}

sub destroy {
    my ($self) = @_;
    foreach my $node (@{$self->[$DESCENDANTS]}){
        undef @$node;
    }
    undef @{$self->[$DESCENDANTS]};
    undef @$self;
    return;
}

sub remove {
    my ($self) = @_;
    $self->bundle->_remove_tree($self);
    $self->destroy();
    return;
}

sub copy_tree {
    my ($self) = @_;
    my $new_root = _copy_subtree($self);
    my @new_nodes = Udapi::Core::Node::_descendants($new_root);
    foreach my $new_node ($new_root, @new_nodes){
        $new_node->[$ROOT] = $new_root;
    }
    $new_root->[$DESCENDANTS] = \@new_nodes;
    return $new_root;
}

# This subroutine is not public because:
# - It is meant to be called only from Udapi::Core::Node::Root::copy_tree (and recursively from itself).
# - It keeps $new_node[$NEXTSIBLING] and $new_node[$PARENT] pointing to the original nodes.
#   Of course, $new_node's descendants have $NEXTSIBLING and $PARENT set up correctly.
#   So _copy_subtree should be called only on the root.
# - It is not a method because it is defined only here in Udapi::Core::Node::Root,
#   but in the recursive calls it is called also with ref $node eq Udapi::Core::Node.
sub _copy_subtree {
    my ($node) = @_;
    my $new_node = bless [@$node], ref $node;
    my $prev_child = undef;
    foreach my $child ($node->children){
        my $new_child = _copy_subtree($child);
        $new_child->[$PARENT] = $new_node;
        $new_child->[$NEXTSIBLING] = $prev_child;
        $prev_child = $new_child;
    }
    $new_node->[$FIRSTCHILD] = $prev_child;
    return $new_node;
}

sub address {
    return $_[0][$BUNDLE]->id . ($_[0][$ZONE] eq '' ? '' : '/' . $_[0][$ZONE]);
}

sub shift_before_node    { confess 'Cannot call shift_* methods on root';}
sub shift_after_node     { confess 'Cannot call shift_* methods on root';}
sub shift_before_subtree { confess 'Cannot call shift_* methods on root';}
sub shift_after_subtree  { confess 'Cannot call shift_* methods on root';}

1;
