package Udapi::Block::Read::Sentences;
use Udapi::Core::Common;
use Udapi::Core::Node::Root;
extends 'Udapi::Core::Reader';

sub read_tree {
    my ($self, $doc) = @_;
    my $root = Udapi::Core::Node::Root->new();
    my $fh = $self->filehandle;
    my $line = <$fh>;
    return undef if !defined $line;
    chomp $line;
    $root->set_sentence($line);
    return $root;
}

1;