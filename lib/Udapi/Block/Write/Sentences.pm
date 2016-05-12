package Udapi::Block::Write::Sentences;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

has_ro if_missing => ( default => 'detokenize',); #isa => enum([qw(detokenize empty warn fatal)]), );

sub process_tree {
    my ($self, $tree, $bundleNo) = @_;
    my $sentence = $tree->sentence;
    if (!defined $sentence){
        my $what = $self->if_missing;
        if ($what eq 'detokenize') {
            # TODO SpaceAfter=No
            $sentence = join ' ', map {$_->form} $tree->descendants();
        }
        elsif ($what eq 'empty') {
            $sentence = '';
        }
        else {
            my $msg = "Sentence $bundleNo is undefined";
            confess $msg if $what eq 'fatal';
            warn $msg;
        }
    }
    say $sentence;
    return;
}

1;
