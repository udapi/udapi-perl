package Udapi::Block::Write::TextModeTrees;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';

has_ro tree_ids => ( isa => Bool, default => 0 );
has_ro sents    => ( isa => Bool, default => 0 );
has_ro indent   => ( isa => Int,  default => 1, doc => 'number of columns for better readability');
has_ro minimize_cross => ( isa => Bool, default => 1, doc => 'minimize crossings of edges in non-projective trees');

# Symbols for drawing edges
my (@DRAW, @SPACE, $H, $V);

sub BUILD {
    my ($self) = @_;

    # $DRAW[bottom-most][top-most]
    my $line = '─' x $self->indent;
    $H          = $line . '─';
    $DRAW[1][1] = $H;
    $DRAW[1][0] = $line . '┘';
    $DRAW[0][1] = $line . '┐';
    $DRAW[0][0] = $line . '┤';

    # $SPACE[bottom-most][top-most]
    my $space = ' ' x $self->indent;
    $SPACE[1][0] = $space . '└';
    $SPACE[0][1] = $space . '┌';
    $SPACE[0][0] = $space . '├';
    $V           = $space . '│';
    return;
}

# We want to be able to call process_tree not only on root node,
# so this block can be called from $node->print_subtree($args)
# on any node and print its subtree. Thus, we cannot assume that
# $all[$idx]->ord == $idx. Instead of $node->ord, we'll use $index_of{$node},
# which is its index within the printed subtree.
# $gaps{$node} = number of nodes within $node's span, which are not its descendants.
my (%gaps, %index_of);

sub _compute_gaps {
    my ($node) = @_;
    my ($lmost, $rmost, $descs) = ($index_of{$node}, $index_of{$node}, 0);
    foreach my $child ($node->_childrenF){
        my ($lm, $rm, $de) =_compute_gaps($child);
        $lmost = min($lm, $lmost);
        $rmost = max($rm, $rmost);
        $descs += $de;
    }
    $gaps{$node} = $rmost - $lmost - $descs;
    return($lmost, $rmost, $descs + 1);
}

sub process_tree {
    my ($self, $root) = @_;
    my @all = $root->descendants({add_self=>1});
    %index_of = map {$all[$_] => $_} (0..$#all);
    my @lines = ('') x @all;

    # Precompute the number of non-projective gaps for each subtree
    _compute_gaps($root) if $self->minimize_cross;

    # Precompute lines for printing
    my @stack = ($root);
    while (my $node = pop @stack) {
        my @children = $node->children({add_self=>1});
        my ($min_idx, $max_idx) = @index_of{ @children[0, -1] };
        my $max_length = max( map{length $lines[$_]} ($min_idx..$max_idx) );
        for my $idx ($min_idx..$max_idx) {
            my $idx_node = $all[$idx];
            my $filler = $lines[$idx] =~ m/[─┌└├]$/ ? '─' : ' ';
            $lines[$idx] .= $filler x ($max_length - length $lines[$idx]);

            my $min = $idx == $min_idx;
            my $max = $idx == $max_idx;
            if ($idx_node == $node) {
                $lines[$idx] .= $DRAW[$max][$min] . $self->node_to_string($node);
            } else {
                if ($idx_node->parent != $node){
                    $lines[$idx] .= $V;
                } else {
                    $lines[$idx] .= $SPACE[$max][$min];
                    if ($idx_node->is_leaf){
                        $lines[$idx] .= $H . $self->node_to_string($idx_node);
                    } else {
                        push @stack, $idx_node;
                    }
                }
            }
        }

        # sorting the stack to minimize crossings of edges
        @stack = sort {$gaps{$b} <=> $gaps{$a}} @stack if $self->minimize_cross;
    }

    # TODO harmonize parameter names with with Write::CoNLLU
    # TODO $tree->id should contain $bundle_id" . ($zone ? "/$zone" : '')
    # TODO $tree->sentence vs. compute_sentence, but TextModeTrees should work on subtrees as well
    # Print the trees out
    if ( $self->tree_ids ){
        my $bundle_id = $root->bundle->id;
        my $zone = $root->zone;
        say "# sent_id $bundle_id" . ($zone ? "/$zone" : '');
    }
    if ( $self->sents ){
        my $sentence = $root->compute_sentence();
        say "# sentence $sentence";
    }
    say $_ for @lines;
    return;
}

# Render a node with its attributes
sub node_to_string {
    my ($self, $node) = @_;
    return '' if $node->is_root;

    my $str = $node->form // '';
    if ($node->upos || $node->deprel){
        $str .= '(';
        $str .= $node->upos if $node->upos;
        $str .= '/' . $node->deprel if $node->deprel;
        $str .= ')';
    }
    return $str;
}

1;

__END__

=encoding utf-8

=head1 NAME

Udapi::Block::Write::TextModeTrees - legible dependency trees

=head1 SYNOPSIS

 # is scenario
 Write::TextModeTrees indent=1 tree_ids=1

=head1 DESCRIPTION

Trees written in plain text format format.

For example the following conll file (with tabs instead of spaces)

 1  We         PRP  _ _ _ 2  SBJ
 2  gave       VBD  _ _ _ 0  ROOT
 3  Kennedy    NNP  _ _ _ 2  IOBJ
 4  no         DT   _ _ _ 7  NMOD
 5  very       RB   _ _ _ 6  AMOD
 6  positive   JJ   _ _ _ 7  NMOD
 7  approval   NN   _ _ _ 2  OBJ
 8  in         IN   _ _ _ 2  ADV
 9  the        DT   _ _ _ 10 NMOD
 10 margin     NN   _ _ _ 8  PMOD
 11 of         IN   _ _ _ 10 NMOD
 12 his        PRP$ _ _ _ 13 NMOD
 13 preferment NN   _ _ _ 11 PMOD

will be printed (with indent=1 afuns=1) as

 ─┐
  │ ┌──We(PRP/SBJ)
  └─┤gave(VBD/ROOT)
    ├──Kennedy(NNP/IOBJ)
    │ ┌──no(DT/NMOD)
    │ │ ┌──very(RB/AMOD)
    │ ├─┘positive(JJ/NMOD)
    ├─┘approval(NN/OBJ)
    └─┐in(IN/ADV)
      │ ┌──the(DT/NMOD)
      └─┤margin(NN/PMOD)
        └─┐of(IN/NMOD)
          │ ┌──his(PRP$/NMOD)
          └─┘preferment(NN/PMOD)

=head1 PARAMETERS

=head2 tree_ids

If set to 1, print tree (root) ID above each tree.

=head2 indent

number of characters to indent node depth in the tree for better readability

=head2 sents

If set to 1, print the corresponding sentence on one line above each tree.

=head1 AUTHORS

Martin Popel <popel@ufal.mff.cuni.cz>
based on Treex block Write::TreesTXT by Matyáš Kopp

=head1 COPYRIGHT AND LICENSE

Copyright © 2011-2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
