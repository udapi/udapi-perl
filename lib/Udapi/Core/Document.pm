package Udapi::Core::Document;
use strict;
use warnings;
use autodie;
use Udapi::Core::Bundle;
use Udapi::Core::Node::Root;
use Carp;

sub new {
    my ($class) = @_;
    my $self = {_bundles=>[], _highest_bundle_id=>0};
    return bless $self, $class;
}

sub bundles {@{$_[0]->{_bundles}};}

sub create_bundle {
    my ($self, $args) = @_;
    # TODO args->{before} args->{after}
    my $bundle = Udapi::Core::Bundle->new();
    my $id = ++$self->{_highest_bundle_id};
    $bundle->set_id($id);
    $bundle->_set_number(1 + @{$self->{_bundles}});
    $bundle->_set_document($self);
    push @{$self->{_bundles}}, $bundle;
    return $bundle;
}

# Based on $root->id the tree is added either to the last existing bundle or to a new bundle.
# $root->id should contain "$bundle_id/$zone".
# The "/$zone" part is optional. If missing, an empty-string zone is used for the new tree.
sub add_tree {
    my ($self, $root) = @_;
    my $add_to_the_last_bundle = 1;
    my $tree_id = $root->id;
    if (!defined $tree_id) {
        $self->create_bundle()->add_tree($root);
    }
    else {
        my ($bundle_id, $zone) = split /\//, $tree_id;
        if (defined $zone){
            confess "'$zone' is not a valid zone name (from tree_id='$tree_id')"
                if $zone !~ /^[a-z-]*(_[A-Za-z0-9-])?$/;
            $root->_set_zone($zone);
        }
        my $last_bundle = $self->{_bundles}[-1];
        if (!$last_bundle || $last_bundle->id ne $bundle_id){
            $last_bundle = $self->create_bundle();
            $last_bundle->set_id($bundle_id);
        }
        $root->set_id(undef);
        $last_bundle->add_tree($root);
    }
    return;
}

sub _remove_bundle {
    my ($self, $number) = @_;
    $number--; # the number is 1-based
    splice @{$self->{_bundles}}, $number, 1;
    foreach my $index ($number .. -1+@{$self->{_bundles}}){
        $self->{_bundles}[$index]->_set_number($index+1);
    }
    return;
}

my ($ORD, $ROOT, $PARENT, $FIRSTCHILD, $NEXTSIBLING, $MISC) = (0..5);
my $DESCENDANTS = 6;

sub _read_conllu_tree_from_fh {
    my ($self, $fh, $error_context) = @_;

    # We could use _create_root($bundle),
    # but the $bundle is not known yet, it will be specified later.
    my $root = Udapi::Core::Node::Root->new();
    my @nodes = ($root);
    my @parents = (0);
    my ( $id, $form, $lemma, $upos, $xpos, $feats, $head, $deprel, $deps, $misc);
    my $comment = '';

    LINE:
    while (my $line = <$fh>) {
        chomp $line;
        last LINE if $line eq '';
        if ($line =~ s/^#// ){
            if ($line =~ /^\s*sent_id\s+(\S+)/) {
                $root->set_id($1);
            # TODO: see https://github.com/UniversalDependencies/docs/issues/273
            # and decide whether it should be "sentence-text:", "text" or what.
            } elsif ($line =~ /^\s*sentence\s+(.*)$/) {
                $root->set_sentence($1);
            } else {
                $comment = $comment . $line . "\n";
            }
        } else {
            ( $id, $form, $lemma, $upos, $xpos, $feats, $head, $deprel, $deps, $misc ) = split /\t/, $line;
            if (index($id, '-', 1) >=0){
                # TODO multiword tokens
                next LINE;
            }
            my $new_node = bless [scalar(@nodes), $root, undef, undef, undef, $misc,
                                  $form, $lemma, $upos, $xpos, $feats, $deprel, $deps], 'Udapi::Core::Node';

            push @nodes, $new_node;
            push @parents, $head;
            # TODO deps
            # TODO convert feats into iset
        }
    }

    # If no nodes were read from $fh (so only $root remained in @nodes),
    # we return undef as a sign of failure (end of file or more than one empty line).
    return undef if @nodes==1;

    # Empty sentences are not allowed in CoNLL-U,
    # but if the users want to save just the sentence string and/or sent_id
    # they need to create one artificial node and mark it with Empty=Yes.
    # In that case, we will delete this node, so the tree will have just the (technical) root.
    # See also Udapi::Block::Write::CoNLLU, which is compatible with this trick.
    if (@nodes == 2 && $nodes[1][$MISC] eq 'Empty=Yes'){
        pop @nodes;
    }

    # Set dependency parents (now, all nodes of the tree are created).
    # The following code does the same as
    # $nodes[$i]->set_parent($nodes[$parents[$i]]) for my $i (1..$#nodes);
    # but slightly faster (set_parent has some checks we can skip here).
    foreach my $i (1..$#nodes){
        my $parent = $nodes[ $parents[$i] ];
        my $node = $nodes[$i];
        if ($node == $parent){
            confess "Conllu file $error_context (before line $.) contains a cycle: node $id is attached to itself";
        }
        if ($node->[$FIRSTCHILD]) {
            my $grandpa = $parent->[$PARENT];
            while ($grandpa) {
                if ($grandpa == $node){
                    my $b_id = $node->bundle->id;
                    my $p_id = $parent->ord;
                    confess "Conllu file $error_context (before line $.) contains a cycle: nodes $id and $p_id.";
                }
                $grandpa = $grandpa->[$PARENT];
            }
        }
        $node->[$PARENT] = $parent;
        $node->[$NEXTSIBLING] = $parent->[$FIRSTCHILD];
        $parent->[$FIRSTCHILD] = $node;
    }

    # Set root attributes (descendants for faster iteration of all nodes in a tree).
    $root->[$DESCENDANTS] = [@nodes[1..$#nodes]];
    if (length $comment){
        $root->set_misc($comment);
        $comment = '';
    }

    return $root;
}

sub load_conllu {
    my ($self, $conllu_file) = @_;
    open my $fh, '<:utf8', $conllu_file;

    while (my $root = $self->_read_conllu_tree_from_fh($fh, $conllu_file)){
        my $bundle = $self->create_bundle();
        $bundle->add_tree($root);
    }

    close $fh;
    return;
}

sub save_conllu {
    my ($self, $conllu_file) = @_;
    open my $fh, '>:utf8', $conllu_file;
    my @nodes;
    foreach my $bundle ($self->bundles){
        foreach my $tree ($bundle->trees){
            @nodes = $tree->descendants;
            # Empty sentences are not allowed in CoNLL-U.
            next if !@nodes;
            my $comment = $tree->misc;
            if (length $comment){
                chomp $comment;
                $comment =~ s/\n/\n#/g;
                print {$fh} "#", $comment, "\n";
            }
            foreach my $node (@nodes){
                print {$fh} join("\t", map {(defined $_ and $_ ne '') ? $_ : '_'}
                    $node->ord, $node->form, $node->lemma, $node->upos, $node->xpos,
                    $node->feats, $node->parent->ord, $node->deprel, $node->deps, $node->misc,
                ), "\n";
            }
            print {$fh} "\n";
        }
    }
    close $fh;
    return;
}

sub destroy {
    my ($self) = @_;
    my $bundles_ref = $self->{_bundles};
    foreach my $bundle (@$bundles_ref){
        $bundle->destroy();
    }
    undef @$bundles_ref;
    undef %$self;
    return;
}

1;
