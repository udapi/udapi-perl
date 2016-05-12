package Udapi::Block::Tutorial::Adpositions;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

my ($prepositions, $postpositions) = (0, 0);

sub process_node {
    my ($self, $node) = @_;
    # TODO: Your task: distinguish prepositions and postpositions
    if ($node->upos eq 'ADP'){
        $prepositions++;
    }
    return;
}

sub process_end {
    my ($self) = @_;
    my $all = $prepositions + $postpositions;
    $prepositions = $prepositions*100 / $all;
    $postpositions = $postpositions*100/ $all;
    printf "prepositions %5.1f%%, postpositions %5.1f%%\n", $prepositions, $postpositions;
    return;
}

1;

__END__

Example usage:
for a in */*dev*.conllu; do
    printf '%50s ' $a;
    cat $a | udapi.pl Read::CoNLLU Tutorial::Adpositions;
done | tee ~/results.txt

cat UD_Czech/cs-ud-dev.conllu | udapi.pl Read::CoNLLU Util::Eval \
node='say join " ", map{($_==$node ? "***" : $_==$.parent ? "+++" : "").$_->form} $.root->descendants
      if $.upos eq "ADP" && !$.precedes($.parent)' | head

# https://lindat.mff.cuni.cz/services/pmltq/#!/treebank/ud_cs/help
a-node $A:= [
  child a-node [
    conll/cpos = 'ADP',
    ord > $A.ord,
  ]
]