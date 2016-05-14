package Udapi::Block::Util::SetSentence;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

sub process_tree {
    my ( $self, $root ) = @_;
    # TODO SpaceAfter=No
    # TODO see Write::Sentences
    $root->set_sentence(join ' ', map {$_->form} $root->descendants);
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Block::Util::SetSentence - fill $root->sentence attribute

=head1 SYNOPSIS

  # on the command line
  Util::SetSentence

=head1 DESCRIPTION

Currently, this block fills the C<$root-E<gt>sentence> attribute
just by concatenating all word forms separated by spaces.
In future, it should consider the SpaceAfter=No attribute.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
