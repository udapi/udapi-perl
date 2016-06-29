package Udapi::Block::Tutorial::AddCommas;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

sub process_node {
    my ($self, $node) = @_;

    if ($self->should_add_comma_before($node)){
        $node->create_child(form=>',', deprel=>'punct')->shift_before_node($node);
    }
    return;
}

sub should_add_comma_before{
    my ($self, $node) = @_;
    my $prev_node = $node->prev_node || return 0;
    return 1 if $prev_node->lemma eq 'however';
    return 1 if any {$_->deprel eq 'appos'} $prev_node->children;
    return 0;
}

1;
