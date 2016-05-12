package Udapi::Block::Read::Sentences;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';
#extends 'Udapi::Core::DocumentReader';

sub process_document {
    my ($self, $doc) = @_;

    # TODO $self->from
    #open my $fh, '<:utf8', $conllu_file;
    my $conllu_file = '/dev/stdin';
    my $fh = \*STDIN;

    while (my $line = <$fh>) {
        chomp $line;
        my $bundle = $doc->create_bundle();
        my $root = $bundle->create_tree(); # TODO {selector=>''}
        $root->set_sentence($line);
    }

    #close $fh;
    return;
}

1;