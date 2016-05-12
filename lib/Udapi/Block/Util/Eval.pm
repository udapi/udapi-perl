package Udapi::Block::Util::Eval;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

has_ro [qw(doc bundle tree node start end)];

has_ro expand_code => (
    default => 1,
    doc => 'Should "$." be expanded to "$this->" in all eval codes?'
);

# TODO expand all the codes just once in BUILD

sub expand_eval_code {
    my ($self, $to_eval) = @_;
    return "$to_eval;1;" if !$self->expand_code;
    $to_eval =~ s/\$\./\$this->/g;
    return "$to_eval;1;";
}

## no critic (ProhibitStringyEval) This block needs string evals
sub process_document {
    my ( $self, $doc ) = @_;
    my $document = $doc;
    my $this = $doc;
    if ( $self->doc ) {
        my $to_eval = $self->expand_eval_code($self->doc);
        eval($to_eval) or confess("While evaluating '$to_eval' got error: $@");
    }

    if ( $self->bundle || $self->tree || $self->node ) {
        my $bundleNo = 1;
        foreach my $bundle ( $doc->bundles() ) {
            if ($self->_should_process_bundle($bundle, $bundleNo)){
                $self->process_bundle($bundle, $bundleNo);
            }
            $bundleNo++;
        }
    }
    return;
}

sub process_bundle {
    my ( $self, $bundle, $bundleNo ) = @_;

    # Extract variables $document ($doc), so they can be used in eval code
    my $doc      = $bundle->document();
    my $document = $doc;
    my $this     = $bundle;
    if ( $self->bundle ) {
        my $to_eval = $self->expand_eval_code($self->bundle);
        eval($to_eval) or confess("While evaluating '$to_eval' got error: $@");
    }

    if ($self->tree || $self->node ) {
        my @trees = $bundle->trees();
        foreach my $tree (@trees) {
            next if !$self->_should_process_tree($tree);
            $self->process_tree( $tree, $bundleNo );
        }
    }
    return;
}

sub process_tree {
    my ( $self, $tree, $bundleNo ) = @_;

    # Extract variables $bundle, $document ($doc), so they can be used in eval code
    my $bundle   = $tree->bundle;
    my $document = $bundle->document;
    my $doc      = $document;
    my $this     = $tree;
    if ( $self->tree ) {
        if ( !eval $self->expand_eval_code($self->tree) ) {
            confess "Eval error: $@";
        }
    }

    if ($self->node){
        foreach my $node ( $tree->descendants() ) {
            $this = $node;
            if ( !eval $self->expand_eval_code($self->node) ) {
                confess "Eval error: $@";
            }
        }
    }
    return;
}

sub process_start {
    my ($self) = @_;
    if ( $self->start ) {
        my $to_eval = $self->expand_eval_code($self->start);
        eval($to_eval) or confess("While evaluating '$to_eval' got error: $@");
    }
    return;
}

sub process_end {
    my ($self) = @_;
    if ( $self->end ) {
        my $to_eval = $self->expand_eval_code($self->end);
        eval($to_eval) or confess("While evaluating '$to_eval' got error: $@");
    }
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Block::Util::Eval - Special block for evaluating code given by parameters.

=head1 SYNOPSIS

  # on the command line
  newtreex Read::CoNLLU from=a.txt Util::Eval node='say $.lemma'

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
