package Udapi::Block::UDPipe::Tokenize;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';
use Udapi::Tool::UDPipe;

has_rw _tool => ();

#has_ro model_file => (default=>'data/models/udpipe/english-ud-1.2-160523.udpipe');
has_ro model_file => (required=>1);

sub BUILD {
    my ($self, $args) = @_;
    my $tool = Udapi::Tool::UDPipe->new(model_file=>$self->model_file);
    $self->set__tool($tool);
    return;
}

sub process_tree {
    my ($self, $root) = @_;
    my @tokens = $self->_tool->tokenize($root->sentence);
    foreach my $token (@tokens){
        $root->create_child(form=>$token);
    }
    return;
}

1;
