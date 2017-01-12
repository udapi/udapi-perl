package Udapi::Block::Write::Sentences;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';

has_ro if_missing => ( default => 'detokenize',); #isa => enum([qw(detokenize empty warn fatal)]), );

sub process_tree {
    my ($self, $tree) = @_;
    my $sentence_text = $tree->text;
    if (!defined $sentence_text){
        my $what = $self->if_missing;
        if ($what eq 'detokenize') {
            $sentence_text = $tree->compute_text();
        }
        elsif ($what eq 'empty') {
            $sentence_text = '';
        }
        else {
            my $msg = 'Sentence ' . $tree->bundle->number . ' is undefined';
            confess $msg if $what eq 'fatal';
            warn $msg;
        }
    }
    say $sentence_text;
    return;
}

1;
