package Udapi::Block::UDPipe::Base;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';
with 'Udapi::Core::RememberArgs';
use Udapi::Tool::UDPipe;

has_ro tokenize => (isa => Bool, default => 1);
has_ro tag      => (isa => Bool, default => 1);
has_ro parse    => (isa => Bool, default => 1);

has_ro known_models => (
    default => sub {{
        grc_proiel => 'data/models/udpipe/ancient-greek-proiel-ud-1.2-160523.udpipe',
        grc => 'data/models/udpipe/ancient-greek-ud-1.2-160523.udpipe',
        ar => 'data/models/udpipe/arabic-ud-1.2-160523.udpipe',
        eu => 'data/models/udpipe/basque-ud-1.2-160523.udpipe',
        bg => 'data/models/udpipe/bulgarian-ud-1.2-160523.udpipe',
        hr => 'data/models/udpipe/croatian-ud-1.2-160523.udpipe',
        cs => 'data/models/udpipe/czech-ud-1.2-160523.udpipe',
        da => 'data/models/udpipe/danish-ud-1.2-160523.udpipe',
        nl => 'data/models/udpipe/dutch-ud-1.2-160523.udpipe',
        en => 'data/models/udpipe/english-ud-1.2-160523.udpipe',
        et => 'data/models/udpipe/estonian-ud-1.2-160523.udpipe',
        fi => 'data/models/udpipe/finnish-ftb-ud-1.2-160523.udpipe',
        fi_ftb => 'data/models/udpipe/finnish-ud-1.2-160523.udpipe',
        fr => 'data/models/udpipe/french-ud-1.2-160523.udpipe',
        got => 'data/models/udpipe/gothic-ud-1.2-160523.udpipe',
        de => 'data/models/udpipe/german-ud-1.2-160523.udpipe',
        el => 'data/models/udpipe/greek-ud-1.2-160523.udpipe',
        he => 'data/models/udpipe/hebrew-ud-1.2-160523.udpipe',
        hi => 'data/models/udpipe/hindi-ud-1.2-160523.udpipe',
        hu => 'data/models/udpipe/hungarian-ud-1.2-160523.udpipe',
        id => 'data/models/udpipe/indonesian-ud-1.2-160523.udpipe',
        ga => 'data/models/udpipe/irish-ud-1.2-160523.udpipe',
        it => 'data/models/udpipe/italian-ud-1.2-160523.udpipe',
        la_itt => 'data/models/udpipe/latin-itt-ud-1.2-160523.udpipe',
        la_proiel => 'data/models/udpipe/latin-proiel-ud-1.2-160523.udpipe',
        la => 'data/models/udpipe/latin-ud-1.2-160523.udpipe',
        no => 'data/models/udpipe/norwegian-ud-1.2-160523.udpipe',
        cu => 'data/models/udpipe/old-church-slavonic-ud-1.2-160523.udpipe',
        fa => 'data/models/udpipe/persian-ud-1.2-160523.udpipe',
        po => 'data/models/udpipe/polish-ud-1.2-160523.udpipe',
        ro => 'data/models/udpipe/romanian-ud-1.2-160523.udpipe',
        pt => 'data/models/udpipe/portuguese-ud-1.2-160523.udpipe',
        sl => 'data/models/udpipe/slovenian-ud-1.2-160523.udpipe',
        es => 'data/models/udpipe/spanish-ud-1.2-160523.udpipe',
        ta => 'data/models/udpipe/tamil-ud-1.2-160523.udpipe',
        sv => 'data/models/udpipe/swedish-ud-1.2-160523.udpipe',
    }},
);

has_ro model => (predicate=>1);

has_ro model_alias => (predicate => 1);

has_rw tool => (lazy=>1, builder=>1);

sub _build_tool {
    my ($self) = @_;
    if ($self->has_model) {
        $self->args->{model} = $self->model;
    }
    elsif ($self->has_model_alias) {
        $self->args->{model} = $self->known_models()->{$self->model_alias};
    }
    else {
        log_fatal('Model path (model=path/to/model) or alias (e.g. model_alias=en) must be set!');
    }
    return Udapi::Tool::UDPipe->new($self->args);
}

sub process_tree {
    my ($self, $root) = @_;

    my ($tok, $tag, $par) =  ($self->tokenize, $self->tag, $self->parse);
    return $self->tool->tokenize_tag_parse_tree($root) if  $tok &&  $tag &&  $par;
    return $self->tool->tokenize_tag_tree($root)       if  $tok &&  $tag && !$par;
    return $self->tool->tokenize_tree($root)           if  $tok && !$tag && !$par;
    return $self->tool->tag_parse_tree($root)          if !$tok &&  $tag &&  $par;
    return $self->tool->tag_tree($root)                if !$tok &&  $tag && !$par;
    return $self->tool->parse_tree($root)              if !$tok && !$tag &&  $par;
    confess "Combination 'tokenize=$tok tag=$tag parse=$par' is not allowed";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Block::UDPipe::Base - tokenize, tag and parse into UD

=head1 SYNOPSIS

 # from the command line
 echo John loves Mary | udapi.pl Read::Sentences UDPipe::Base model_alias=en Write::TextModeTrees

 # in scenario
 UDPipe::Base model=/home/me/english-ud-1.2-160523.udpipe
 UDPipe::Base model_alias=en
 UDPipe::EN # shortcut for the above
 UDPipe::EN tokenize=1 tag=1 parse=0

=head1 DESCRIPTION

This block loads L<Udapi::Tool::UDPipe> (a wrapper for the UDPipe C++ tool) with
the given C<model> for analysis into the Universal Dependencies (UD) style.
UDPipe can do tokenization, tagging (plus lemmatization and universal features)
and parsing (with deprel labels) and users of this block can select which of the
substasks should be done using parameters C<tokenize>, C<tag> and C<parse>.
The default is to do all three.

=head1 TODO

UDPipe can do also sentence segmentation, but L<Udapi::Tool::UDPipe> does not supported it yet.

Similarly with multi-word tokens.

=head1 PARAMETERS

=head2 C<model>

Path to the model file within Udapi share
(or relative path starting with "./" or absolute path starting with "/").
This parameter is required if C<model_alias> is not supplied.

=head2 C<model_alias>

The C<model> parameter can be omitted if this parameter is supplied.
Currently available model aliases are:

B<grc_proiel, grc, ar, eu, bg, hr, cs, da, nl, en, et, fi, fi_ftb, fr, got, de,
el, he, hi, hu, id, ga, it, la_itt, la_proiel, la, no, cu, fa, po, ro, pt, sl,
es, ta, sv>.

They correspond to paths where the language code in the alias is substituted
with the respective language name, e.g. B<grc_proiel> expands to
C<data/models/udpipe/ancient-greek-ud-1.2-160523.udpipe>.

=head1 tokenize

Do tokenization, i.e. create new nodes with attributes
C<form>, C<misc> (if SpaceAfter=No) and C<ord>.
The sentence string is taken from the root's attribute C<text>.

=head1 tag

Fill node attributes: C<lemma>, C<upos>, C<xpos> and C<feats>.
On the input, just the attribute C<form> is expected.

=head1 parse

Fill node attributes: C<deprel> and rehang the nodes to their parent.
On the input, attributes C<lemma>, C<upos>, C<xpos> and C<feats> are expected.

=head1 SEE ALSO

L<http://ufal.mff.cuni.cz/udpipe>

L<Udapi::Tool::UDPipe>

=head1 AUTHORS

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
