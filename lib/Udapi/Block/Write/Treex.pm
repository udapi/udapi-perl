package Udapi::Block::Write::Treex;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';

#has_ro compress => ( isa => Bool, default => 1, doc => 'create *.conllu.gz files');

before process_document => sub {
    my ($self, $doc) = @_;
    print << 'END';
<?xml version="1.0" encoding="UTF-8"?>
<treex_document xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
  <head>
    <schema href="treex_schema.xml" />
  </head>
  <meta/>
  <bundles>
END
    return;
};

after process_document => sub {
    my ($self, $doc) = @_;
    say "  </bundles>\n</treex_document>\n";
    return;
};

before process_bundle => sub {
    my ( $self, $bundle ) = @_;
    say '<LM id="s' . $bundle->number . "\">\n      <zones>";
};

after process_bundle => sub {
    my ( $self, $bundle ) = @_;
    say "      </zones>\n    </LM>";
};

sub process_tree {
    my ($self, $tree) = @_;
    my $bundle_number = $tree->bundle->number;
    my $root_id = "a-$bundle_number";
    my $sentence = $tree->sentence;
    my ($language, $selector) = split /_/, $tree->zone;
    $language ||= 'und';
    $selector ||= '';
    my $tree_id = "s$bundle_number-$language";
    my $in = ' ' x 8;
    say "$in<zone language='$language' selector='$selector'>";
    say "$in  <sentence>$sentence</sentence>" if defined $sentence;
    say "$in  <trees>\n$in    <a_tree id='$tree_id'>";
    $self->print_subtree($tree, $tree_id, ' ' x 12);
    say "$in    </a_tree>\n$in  </trees>\n$in</zone>";
    return;
}

sub print_subtree {
    my ($self, $node, $tree_id, $indent, $print_LM) = @_;
    my ($ord, $form, $lemma, $upos, $xpos, $feats, $deprel, $deps, $misc) =
       $node->get_attrs(qw(ord form lemma upos xpos feats deprel deps misc));
    say "$indent<LM id='${tree_id}-n$ord'>" if !$node->is_root;
    my $in = $indent.'  ';
    say "$in<ord>$ord</ord>";
    if (!$node->is_root){
        say "$in<form>$form</form>" if defined $form;
        say "$in<lemma>$lemma</lemma>" if defined $lemma;
        say "$in<tag>$upos</tag>" if defined $upos;
        say "$in<deprel>$deprel</deprel>" if defined $deprel;
        $xpos ||= ''; $feats ||= '';
        say "$in<conll><pos>$xpos</pos><feat>$feats</feat></conll>";
    }
    # TODO misc and deps into wild, but probably need to encode ř as \x{159} etc using Dumper.
    my @children = $node->children;
    if (@children){
        say "$in<children>";
        foreach my $child (@children){
            $self->print_subtree($child, $tree_id, $in.'  ');
        }
        say "$in</children>";
    }
    say "$indent</LM>" if !$node->is_root;
    return;
}

1;
