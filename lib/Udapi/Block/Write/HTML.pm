package Udapi::Block::Write::HTML;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';

has_ro path_to_js => (default=>'web');

sub process_document {
    my ($self, $doc) = @_;
    my ($jquery, $js_t_v);
    if ($self->path_to_js eq 'web'){
        $jquery = 'https://code.jquery.com/jquery-2.1.4.min.js';
        $js_t_v = 'http://ufal.github.io/js-treex-view/js-treex-view.js';
    } else {
        $jquery = $self->path_to_js . '/jquery-2.1.4.min.js';
        $js_t_v = $self->path_to_js . '/js-treex-view.js';
    }
    say '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">';
    say '<title>Udapi viewer</title>'; # TODO $doc->loaded_from
    say qq'<script src="$jquery"></script>';
    say qq'<script src="$js_t_v"></script>';
    say "</head>\n<body>\n<div id='treex-view'></div><script>";
    print "data=[\n";
    foreach my $bundle ( $doc->bundles() ) {
        next if !$self->_should_process_bundle($bundle);
        print ',' if $bundle->number != 1;
        print '{"zones":{';
        my $desc;
        my $first_zone = 1;
        foreach my $tree ($bundle->trees) {
            next if !$self->_should_process_tree($tree);
            my $zone = $tree->zone;
            if ($first_zone){
                $first_zone = 0;
            } else {
                print ',';
            }
            print qq("$zone":{"sentence":");
            print _esc($tree->sentence);
            say qq'","trees":{"a":{"language":"$zone","nodes":[';
            say ' {"id":' . _id($tree) . ',"parent":null,"firstson":'
                . _id($tree->firstchild)
                . qq',"labels":["zone=$zone","id=' . $tree->address . '"]}';
            $desc .= qq',["[$zone]","label"],[" ","space"]';
            foreach my $node ($tree->descendants) {
                $desc .= $self->print_node($node);
            }
            $desc .= ',["\n","newline"]';
            say ']}}}';
        }
        $desc =~ s/^.//; # delete extra starting comma
        say qq'},"desc":[$desc]}';
    }
    say '];';
    say "\$('#treex-view').treexView(data);\n</script></body></html>";
    return;
}

sub print_node {
    my ($self, $node) = @_;
    my ($ord, $misc, $form, $lemma, $upos, $xpos, $feats, $deprel, $deps)
        = map {_esc($_)} $node->get_attrs(
            qw(ord misc form lemma upos xpos feats deprel deps),
            {undefs=>''}
        );
    my ($id, $parent) = map {_id($_)} ($node, $node->parent);
    my ($rbrother, $firstson) = ($node->nextsibling, $node->firstchild);
    my $multiline_feats = $feats;
    $multiline_feats =~ s/\|/\\n/g;
    say qq',{"id":$id,"parent":$parent,"order":$ord,'
        . ($firstson ? '"firstson":' . _id($firstson) . ',' : '')
        . ($rbrother ? '"rbrother":' . _id($rbrother) . ',' : '')
        . qq'"data":{"ord":$ord,"form":"$form","lemma":"$lemma","upos":"$upos",'
        . qq'"xpos":"$xpos","feats":"$feats","deprel":"$deprel","deps":"$deps",'
        . qq'"misc":"$misc","id":"'.$node->address.'"},'
        . qq'"labels":["$form","#{#bb0000}$upos","#{#0000bb}$deprel"],'
        . qq'"hint":"lemma=$lemma\\n$multiline_feats"}';
    my $desc = qq',["$form",$id]';
    $desc .= ',[" ","space"]' if $misc !~ /SpaceAfter=No/;
    return $desc;
}

# id needs to be a valid DOM querySelector
# so it cannot contain # nor / and it cannot start with a digit
sub _id {
    my ($node) = @_;
    return 'null' if !defined $node;
    my $id = $node->address;
    $id =~ s{[#/]}{-}g;
    return qq("n$id");
}

sub _esc {
    my ($string) = @_;
    $string //= '';
    $string =~ s/\\/\\\\/g;
    $string =~ s/"/\\"/g;
    return $string;
}

1;

__END__

=encoding utf-8

=head1 NAME

Udapi::Block::Write::HTML - HTML+JavaScript+SVG visualization of dependency trees

=head1 SYNOPSIS

 # from the command line
 udapi.pl Write::HTML < file.conllu > file.html
 firefox file.html

 # for offline use, we need to download first two JavaScript libraries
 wget http://ufal.github.io/js-treex-view/js-treex-view.js
 wget https://code.jquery.com/jquery-2.1.4.min.js
 udapi.pl Write::HTML path_to_js=. < file.conllu > file.html
 firefox file.html

=head1 DESCRIPTION

This writer produces an html file with drawings of the dependency trees
in the document (there are buttons for selecting which bundle will be shown).
Under each node its form, upos and deprel are shown.
In the tooltip its lemma and (morphological) features are shown.
After clicking the node, all other attributes are shown.
When hovering over a node, the respective word in the (plain text) sentence
is highlighted.

Two JavaScript libraries are required (jquery and js-treex-view).
By default they are linked online (so Internet access is needed when viewing),
but they can be also downloaded locally (so offline browsing is possible and
the loading is faster): see the Synopsis above.

This block is based on L<Treex::View|https://metacpan.org/release/Treex-View>
but takes a different approach. Treex::View depends on (older version of)
L<Valence> (Perl interface to L<Electron|http://electron.atom.io/>)
and comes with a script C<view-treex>, which takes a treex file,
converts it to json behind the scenes (which is quite slow)
and displays the json in a Valence window.

This block generates the json code directly to the html file,
so it can be viewed with any browser or even published online.
(Most of the html file is actually the json.)

When viewing the html file, the JavaScript library C<js-treex-view>
generates an svg on the fly from the json.
You can save the svg to file, e.g. using Chrome's Inspect (Ctrl+Shift+I).

=head1 PARAMETERS

=head2 path_to_js

Path to jquery and js-treex-view.
C<web> means http://ufal.github.io/js-treex-view/js-treex-view.js
and https://code.jquery.com/jquery-2.1.4.min.js will be linked.
When you use C<path_to_js=.> the libraries will be searched in the current directory.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
