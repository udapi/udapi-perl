package Udapi::Block::My::AddArticles;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

sub process_node {
    my ($self, $node) = @_;

    return if $node->upos ne 'NOUN';
    my $the = $node->create_child(form=>'the', lemma=>'the', upos=>'DET', deprel=>'det');
    $the->shift_before_subtree($node);
    return;
}

1;

__END__

Example usage:

udapi.pl
 Read::CoNLLU zone=en_gold from=gold.conllu
 Util::CopyTree to_zone=en_pred
 Util::Eval zones=en_pred
  node='$.remove({children=>"rehang"}) if $.upos eq "DET" && $.lemma =~ /^(a|the)$/'
 Tutorial::AddArticles zones=en_pred
 Eval::Diff gold_zone=en_gold focus='^(?i:an?|the)$'
 Write::TextModeTrees zones=en_pred to=pred.txt
 Write::TextModeTrees zones=en_gold to=gold.txt

vimdiff pred.txt gold.txt
