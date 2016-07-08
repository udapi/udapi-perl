package Udapi::Block::UDPipe::EN;
use Udapi::Core::Common;
extends 'Udapi::Block::UDPipe::Base';

has_ro '+model_alias' => (default=>'en');

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Block::UDPipe::EN - tokenize, tag and parse into English UD

=head1 SYNOPSIS

 # from the command line
 echo John loves Mary | udapi.pl Read::Sentences UDPipe::EN Write::TextModeTrees

 # in scenario
 UDPipe::EN tokenize=1 tag=1 parse=0

=head1 DESCRIPTION

This is a simple subclass of L<Udapi::Block::UDPipe::Base>
with C<model_alias> parameter preset to C<en>, i.e. the English model.

=head1 PARAMETERS

=head1 tokenize

=head1 tag

=head1 parse

=head1 SEE ALSO

L<Udapi::Block::UDPipe::Base>

=head1 AUTHORS

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
