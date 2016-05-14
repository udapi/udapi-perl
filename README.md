# NAME

Udapi - a framework for processing Universal Dependencies

# SYNOPSIS

    # from command line
    cat in.conllu | udapi.pl Read::CoNLLU My::NLP::Block Another::Block \
                             Write::CoNLLU > out.conllu

# DESCRIPTION

Udapi is API and multi-language framework for processing UD (Universal Dependencies) data.
See [http://udapi.github.io](http://udapi.github.io) and [http://universaldependencies.org](http://universaldependencies.org).
This distribution is a Perl implementation of the Udapi framework.

# AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

# COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
