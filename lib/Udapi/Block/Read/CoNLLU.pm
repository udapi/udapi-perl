package Udapi::Block::Read::CoNLLU;
use Udapi::Core::Common;
extends 'Udapi::Core::Reader';

has_rw file_handle => ();

sub process_start {
    my ($self) = @_;
    $self->set_file_handle(\*STDIN);
    return;
}

sub read_tree {
    my ($self, $doc) = @_;
    return $doc->_read_conllu_tree_from_fh($self->file_handle, '/dev/stdin');
}

1;