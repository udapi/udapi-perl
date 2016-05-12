package Udapi;
use 5.010;
use strict;
use warnings;
use version; our $VERSION = version->declare("v0.1.3");

1;
__END__

=encoding utf-8

=head1 NAME

Udapi - a framework for processing Universal Dependencies

=head1 SYNOPSIS

    # from command line
    cat in.conllu | udapi.pl Read::CoNLLU My::NLP::Block Another::Block \
                             Write::CoNLLU > out.conllu

=head1 DESCRIPTION

Udapi is API for processing UD (Universal Dependencies) data.
See L<http://udapi.github.io> and L<http://universaldependencies.org>.
This distribution is a Perl implementation of the Udapi framework.

=head1 AUTHOR

Martin Popel E<lt>popel@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
