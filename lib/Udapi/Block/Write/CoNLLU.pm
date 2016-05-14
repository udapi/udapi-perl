package Udapi::Block::Write::CoNLLU;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

has_rw print_sent_id => (isa=>Bool, default=>1);
has_rw print_sentence => (isa=>Bool, default=>1);

sub process_tree {
    my ($self, $tree) = @_;
    my @nodes = $tree->descendants;

    # Empty sentences are not allowed in CoNLL-U.
    return if !@nodes;

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
    print "\n";
    return;
}

1;
