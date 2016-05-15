package Udapi::Block::Write::CoNLLU;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';

has_rw print_sent_id => (isa=>Bool, default=>1);
has_rw print_sentence => (isa=>Bool, default=>1);
has_rw print_empty_trees => (isa=>Bool, default=>1);

sub process_tree {
    my ($self, $tree) = @_;
    my @nodes = $tree->descendants;

    # Empty sentences are not allowed in CoNLL-U, so with print_empty_trees==0
    # we need to skip the whole tree (including possible comments).
    return if !@nodes && !$self->print_empty_trees;

    if ($self->print_sent_id) {
        my $bundle_id = $tree->bundle->id;
        my $zone = $tree->zone;
        say "# sent_id $bundle_id" . ($zone ? "/$zone" : '');
    }
    if ($self->print_sentence) {
        my $sentence = $tree->sentence;
        say "# sentence $sentence" if length $sentence;
    }

    my $comment = $tree->misc;
    if (length $comment){
        chomp $comment;
        $comment =~ s/\n/\n#/g;
        say "#", $comment;
    }

    foreach my $node (@nodes){
        say join("\t", map {(defined $_ and $_ ne '') ? $_ : '_'}
            $node->ord, $node->form, $node->lemma, $node->upos, $node->xpos,
            $node->feats, $node->parent->ord, $node->deprel, $node->deps, $node->misc);
    }

    # Empty sentences are not allowed in CoNLL-U,
    # but with print_empty_trees==1 (which is the default),
    # we will print an artificial node, so we can print the comments.
    say "1\t_\t_\t_\t_\t_\t0\t_\t_\tEmpty=Yes" if !@nodes;

    print "\n";
    return;
}

1;
