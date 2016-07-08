#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Udapi::Core::Node::Root;

eval {
    require Ufal::UDPipe;
    1;
} or plan skip_all => 'Cannot load Ufal::UDPipe';

plan tests => 24;

use_ok 'Udapi::Tool::UDPipe';

my $test_model = 'data/models/udpipe/english-ud-1.2-160523.udpipe';

SKIP:
{
    eval {
        require Treex::Core::Resource;
        Treex::Core::Resource::require_file_from_share($test_model);
        1;
    } or skip 'Cannot download model', 23;
    my $udpipe = Udapi::Tool::UDPipe->new( model => $test_model );
    isa_ok( $udpipe, 'Udapi::Tool::UDPipe' );

    my $sentence_string  = q(I don't  know.);
    my @expected_forms   = qw(I do n't know .);
    my @expected_nospace = ( 0, 1, 0, 1, 0 );
    my @expected_upos    = qw(PRON AUX PART VERB PUNCT);
    my @expected_xpos    = qw(PRP VBP RB VB .);
    my @expected_feats   = ( 'Case=Nom|Number=Sing|Person=1|PronType=Prs', 'Mood=Ind|Tense=Pres|VerbForm=Fin', '', 'VerbForm=Inf', '' );
    my @expected_heads   = qw(4 4 4 0 4);
    my @expected_deprels = qw(nsubj aux neg root punct);
    my ( @nodes, @forms, @nospace, @upos, @xpos, @feats, @heads, @deprels );

    @forms = $udpipe->tokenize_string($sentence_string);
    is_deeply( \@forms, \@expected_forms, 'tokenize_string - forms' );

    my $root = Udapi::Core::Node::Root->new();
    $root->set_sentence($sentence_string);
    $udpipe->tokenize_tree($root);
    @nodes = $root->descendants;
    @forms   = map { $_->form } @nodes;
    @nospace = map { $_->misc =~ /SpaceAfter=No/ ? 1 : 0} @nodes;
    is_deeply( \@forms,   \@expected_forms,   'tokenize_tree - forms' );
    is_deeply( \@nospace, \@expected_nospace, 'tokenize_tree - no_space_after' );

    $udpipe->tag_nodes(@nodes);
    @upos  = map { $_->upos } @nodes;
    @xpos  = map { $_->xpos } @nodes;
    @feats = map { $_->feats } @nodes;
    is_deeply( \@upos,  \@expected_upos,  'tag_nodes - upos' );
    is_deeply( \@xpos,  \@expected_xpos,  'tag_nodes - xpos' );
    is_deeply( \@feats, \@expected_feats, 'tag_nodes - feats' );

    foreach my $node (@nodes) { $node->set_upos(''); }
    $udpipe->tag_tree($root);
    @upos = map { $_->upos } @nodes;
    is_deeply( \@upos, \@expected_upos, 'tag_tree - upos' );

    foreach my $node (@nodes) { $node->remove(); }
    $udpipe->tokenize_tag_tree($root);
    @nodes = $root->descendants;
    @upos  = map { $_->upos } @nodes;
    @xpos  = map { $_->xpos } @nodes;
    @feats = map { $_->feats } @nodes;
    is_deeply( \@upos,  \@expected_upos,  'tokenize_tag_tree - upos' );
    is_deeply( \@xpos,  \@expected_xpos,  'tokenize_tag_tree - xpos' );
    is_deeply( \@feats, \@expected_feats, 'tokenize_tag_tree - feats' );

    $udpipe->parse_tree($root);
    @heads   = map { $_->parent->ord } @nodes;
    @deprels = map { $_->deprel } @nodes;
    is_deeply( \@heads,   \@expected_heads,   'parse_tree - heads' );
    is_deeply( \@deprels, \@expected_deprels, 'parse_tree - deprels' );

    foreach my $node (@nodes) { $node->set_deprel(undef); $node->set_upos(undef); }
    $udpipe->tag_parse_tree($root);
    @upos    = map { $_->upos } @nodes;
    @heads   = map { $_->parent->ord } @nodes;
    @deprels = map { $_->deprel } @nodes;
    is_deeply( \@upos,    \@expected_upos,    'tag_parse_tree - upos' );
    is_deeply( \@heads,   \@expected_heads,   'tag_parse_tree - heads' );
    is_deeply( \@deprels, \@expected_deprels, 'tag_parse_tree - deprels' );

    foreach my $node ( $root->children ) { $node->remove(); }
    $udpipe->tokenize_tag_parse_tree($root);
    @nodes   = $root->descendants;
    @forms   = $udpipe->tokenize_string($sentence_string);
    @nospace = map { $_->misc =~ /SpaceAfter=No/ ? 1 : 0} @nodes;
    @upos    = map { $_->upos } @nodes;
    @xpos    = map { $_->xpos } @nodes;
    @feats   = map { $_->feats } @nodes;
    @heads   = map { $_->parent->ord } @nodes;
    @deprels = map { $_->deprel } @nodes;
    is_deeply( \@forms,   \@expected_forms,   'tokenize_tag_parse_tree - forms' );
    is_deeply( \@nospace, \@expected_nospace, 'tokenize_tag_parse_tree - no_space_after' );
    is_deeply( \@upos,    \@expected_upos,    'tokenize_tag_parse_tree - upos' );
    is_deeply( \@xpos,    \@expected_xpos,    'tokenize_tag_parse_tree - xpos' );
    is_deeply( \@feats,   \@expected_feats,   'tokenize_tag_parse_tree - feats' );
    is_deeply( \@heads,   \@expected_heads,   'tokenize_tag_parse_tree - heads' );
    is_deeply( \@deprels, \@expected_deprels, 'tokenize_tag_parse_tree - deprels' );
}
