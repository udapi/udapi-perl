package Udapi::Block::Write::TextModeTrees;
use Udapi::Core::Common;
use Term::ANSIColor qw(colored colorstrip);
extends 'Udapi::Core::Writer';

has_ro print_sent_id  => ( isa=>Bool, default=>0 );
has_ro print_text     => ( isa=>Bool, default=>0 );
has_rw add_empty_line => ( isa=>Bool, default=>1 );
has_ro indent         => ( isa => Int,  default => 1, doc => 'number of columns for better readability');
has_ro minimize_cross => ( isa => Bool, default => 1, doc => 'minimize crossings of edges in non-projective trees');
has_rw color          => ( default=> 'auto' );
has_ro attributes     => ( default=>'form,upos,deprel' );
has_ro print_undef_as => (default=>'');

my %COLOR_OF = (
    form => 'yellow',
    lemma => 'cyan',
    upos => 'bright_red',
    deprel => 'bright_blue',
    ord => 'bright_yellow',
);

# Symbols for drawing edges
my (@DRAW, @SPACE, $HORIZ, @VERT);
my @ATTRS;

sub BUILD {
    my ($self) = @_;

    # $DRAW[bottom-most][top-most]
    my $line = '─' x $self->indent;
    $HORIZ      = $line . '╼';
    $DRAW[1][1] = $HORIZ;
    $DRAW[1][0] = $line . '┶';
    $DRAW[0][1] = $line . '┮';
    $DRAW[0][0] = $line . '┾';

    # $SPACE[bottom-most][top-most]
    my $space = ' ' x $self->indent;
    $SPACE[1][0] = $space . '╰';
    $SPACE[0][1] = $space . '╭';
    $SPACE[0][0] = $space . '├';

    # $VERT[is_crossing]
    $VERT[0] = $space . '│';
    $VERT[1] = $line  . '╪';

    @ATTRS = split /,/, $self->attributes;
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

sub _length {
    my ($self, $str) = @_;
    return length colorstrip($str);
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
        my $max_length = max( map{$self->_length($lines[$_])} ($min_idx..$max_idx) );
        for my $idx ($min_idx..$max_idx) {
            my $idx_node = $all[$idx];
            my $filler = $lines[$idx] =~ m/[─╭╰├╪]$/ ? '─' : ' ';
            $lines[$idx] .= $filler x ($max_length - $self->_length($lines[$idx]));

            my $min = ($idx == $min_idx);
            my $max = ($idx == $max_idx);
            if ($idx_node == $node) {
                $lines[$idx] .= $DRAW[$max][$min] . $self->node_to_string($node);
            } else {
                if ($idx_node->parent != $node){
                    $lines[$idx] .= $VERT[$lines[$idx] =~ m/[─├]$/ ? 1 : 0];
                } else {
                    $lines[$idx] .= $SPACE[$max][$min];
                    if ($idx_node->is_leaf){
                        $lines[$idx] .= $HORIZ . $self->node_to_string($idx_node);
                    } else {
                        push @stack, $idx_node;
                    }
                }
            }
        }

        # sorting the stack to minimize crossings of edges
        @stack = sort {$gaps{$b} <=> $gaps{$a}} @stack if $self->minimize_cross;
    }

    # Print headers (if required) and the tree itself
    say '# sent_id = ' . $root->address()   if $self->print_sent_id;
    say '# text = ' . $root->compute_text() if $self->print_text;
    say $_ for @lines;
    print "\n" if $self->add_empty_line;
    return;
}

sub before_process_document {
    my ($self, $doc) = @_;
    $self->SUPER::before_process_document($doc);
    if ($self->color eq 'auto'){
        my $filehandle = select;
        $self->set_color(-t $filehandle ? 1 : 0);
    }
    return;
}

# Render a node with its attributes
sub node_to_string {
    my ($self, $node) = @_;
    return '' if $node->is_root;
    my @values = $node->get_attrs(@ATTRS, {undefs => $self->print_undef_as});
    if ($self->color){
        for my $i (0..$#ATTRS){
            my $attr = $ATTRS[$i];
            if (my $color = $COLOR_OF{$attr}){
                $values[$i] = colored($values[$i], $color);
            }
        }
    }
    return ' ' . join ' ', @values;
}

1;

__END__

=encoding utf-8

=head1 NAME

Udapi::Block::Write::TextModeTrees - print legible dependency trees

=head1 SYNOPSIS

 # from command line (visualize CoNLL-U files)
 udapi.pl Write::TextModeTrees color=1 < file.conllu | less -R

 # is scenario (examples of other parameters)
 Write::TextModeTrees indent=1 print_sent_id=1 print_text=1
 Write::TextModeTrees zones=en,cs attributes=form,lemma,upos minimize_cross=0

=head1 DESCRIPTION

This block prints dependency trees in plain-text format.
For example the following CoNLL-U file (with tabs instead of spaces)

  1  I     I     PRON  PRP Number=Sing|Person=1 2  nsubj     _ _
  2  saw   see   VERB  VBD Tense=Past           0  root      _ _
  3  a     a     DET   DT  Definite=Ind         4  det       _ _
  4  dog   dog   NOUN  NN  Number=Sing          2  dobj      _ _
  5  today today NOUN  NN  Number=Sing          2  nmod:tmod _ SpaceAfter=No
  6  ,     ,     PUNCT ,   _                    2  punct     _ _
  7  which which DET   WDT PronType=Rel         10 nsubj     _ _
  8  was   be    VERB  VBD Person=3|Tense=Past  10 cop       _ _
  9  a     a     DET   DT  Definite=Ind         10 det       _ _
  10 boxer boxer NOUN  NN  Number=Sing          4  acl:relcl _ SpaceAfter=No
  11 .     .     PUNCT .   _                    2  punct     _ _

will be printed (with the default parameters) as

  ─┮
   │ ╭─╼ I PRON nsubj
   ╰─┾ saw VERB root
     │                        ╭─╼ a DET det
     ├────────────────────────┾ dog NOUN dobj
     ├─╼ today NOUN nmod:tmod │
     ├─╼ , PUNCT punct        │
     │                        │ ╭─╼ which DET nsubj
     │                        │ ├─╼ was VERB cop
     │                        │ ├─╼ a DET det
     │                        ╰─┶ boxer NOUN acl:relcl
     ╰─╼ . PUNCT punct

Some non-projective trees cannot be printed witout crossing edges.
TextModeTrees uses a special "bridge" symbol ─╪─ to mark this:

  ─┮
   │ ╭─╼ 1
   ├─╪───┮ 2
   ╰─┶ 3 │
         ╰─╼ 4

This block's method C<process_tree> can be called on any node (not only root),
which is useful for printing subtrees using C<$node-E<gt>print_subtree()>,
which is internally implemented using this block.

=head1 PARAMETERS

=head2 print_sent_id

Print ID of the tree (its root, aka "sent_id") above each tree? Default = 0.

=head2 print_text

Print plain-text detokenized sentence text on one line above each tree? Default = 0.

=head2 add_empty_line

Print an empty line after each tree? Default = 1.

=head2 indent

Number of characters to indent node depth in the tree for better readability.
Default = 1.

=head2 minimize_cross

Minimize crossings of edges in non-projective trees? Default = 1.
Trees without crossings are subjectively more readable,
but usually in practice also "deeper", that is with higher maximal line length.

=head2 color

Print the node attribute with ANSI terminal colors?
Default = 'auto' which means that color output only if the output filehandle
is interactive (console). Each attribute is assigned a color (the mapping is
tested on black background terminals and can be changed only in source code).

If you plan to pipe the output (e.g. to "less -R") and you want the colors,
you need to set explicitly C<color=1>, see the example in Synopsis.

=head2 attributes

A comma-separated list of node attributes which should be printed.
Default = 'form,upos,deprel'.
Possible values are I<ord, form, lemma, upos, xpos, feats, deprel, deps, misc>.

=head2 print_undef_as

What should be printed instead of undefined attribute values (if any)?
Default = empty string.

=head1 AUTHORS

Martin Popel <popel@ufal.mff.cuni.cz>
based on Treex block Write::TreesTXT by Matyáš Kopp

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2017 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
