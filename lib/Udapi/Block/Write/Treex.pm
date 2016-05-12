package Udapi::Block::Write::Treex;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

#has_ro compress => ( isa => Bool, default => 1, doc => 'create *.treex.gz files');

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
    print << 'END';
  </bundles>
</treex_document>
END
    return;
};

before process_bundle => sub {
    my ( $self, $bundle, $bundleNo ) = @_;
    print << "END";
    <LM id="s$bundleNo">
      <zones>
END
};

after process_bundle => sub {
    my ( $self, $bundle, $bundleNo ) = @_;
    print << 'END';
      </zones>
    </LM>
END
};

sub process_tree {
    my ($self, $tree, $bundleNo) = @_;
    my $root_id = "a-$bundleNo";
    my $sentence = $tree->sentence;
    my $language = 'und'; # TODO + selector
    my $tree_id = "s$bundleNo-$language";
    my $in = ' ' x 8;
    say "$in<zone language='$language'>";
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
    say "$in<form>$form</form>" if defined $form;
    say "$in<lemma>$lemma</lemma>" if defined $lemma;
    say "$in<tag>$upos</tag>" if defined $upos;
    say "$in<deprel>$deprel</deprel>" if defined $deprel;
    $xpos ||= ''; $feats ||= '';
    say "$in<conll><pos>$xpos</pos><feat>$feats</feat></conll>" if !$node->is_root;
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

__END__

sub process_document {
    my ($self, $doc) = @_;
    print << "END";
<?xml version="1.0" encoding="UTF-8"?>
<treex_document xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
  <head>
    <schema href="treex_schema.xml" />
  </head>
  <meta/>
  <bundles>
END
    foreach my $bundle ( $doc->bundles() ) {
        if ($self->_should_process_bundle($bundle, $bundleNo)){
            $self->process_bundle($bundle, $bundleNo);
        }
        $bundleNo++;
    }
    return;
}
