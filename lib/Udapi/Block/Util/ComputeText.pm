package Udapi::Block::Util::ComputeText;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

sub process_tree {
    my ( $self, $root ) = @_;
    $root->set_text($root->compute_text());
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Block::Util::ComputeText - fill $root->text attribute

=head1 SYNOPSIS

  # on the command line
  Util::ComputeText

=head1 DESCRIPTION

Currently, this block fills the C<$root-E<gt>text> attribute
just by concatenating all word forms separated by spaces
and considering the SpaceAfter=No attribute.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
