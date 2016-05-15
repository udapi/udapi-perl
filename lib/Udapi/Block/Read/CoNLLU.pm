package Udapi::Block::Read::CoNLLU;
use Udapi::Core::Common;
extends 'Udapi::Core::Reader';

sub read_tree {
    my ($self, $doc) = @_;
    return $doc->_read_conllu_tree_from_fh($self->filehandle, $self->filename);
}

1;