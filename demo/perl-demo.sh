#!/bin/bash

export PATH=../script:$PATH

udapi.pl Read::CoNLLU from=en-sample.conllu \
         Write::TextModeTrees to=en-sample.txt \
         Util::Eval node='if ($.upos eq "ADP") {my $noun = $node->parent; $node->set_parent($noun->parent); $noun->set_parent($node)}' \
         Write::TextModeTrees to=prepositions-up.txt \
         Write::CoNLLU to=prepositions-up.conllu

echo -e "To see the differences run:\n  vimdiff en-sample.txt prepositions-up.txt"