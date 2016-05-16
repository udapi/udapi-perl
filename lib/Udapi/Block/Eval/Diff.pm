package Udapi::Block::Eval::Diff;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';
use Algorithm::Diff;

has_ro gold_zone => (required=>1);

has_ro attributes => (default=>'form');

has_ro focus => (default=>'.*');

has_ro _stats => (default=>sub{{zones=>{}}});

sub process_tree {
    my ($self, $pred_root) = @_;
    my $gold_root = $pred_root->bundle->get_tree($self->gold_zone);
    return if $gold_root==$pred_root;
    $self->_stats->{zones}{$pred_root->zone}++;

    my @attrs = split /,/, $self->attributes;
    my @pred_tokens = map {join '_', $_->get_attrs(@attrs)} $pred_root->descendants;
    my @gold_tokens = map {join '_', $_->get_attrs(@attrs)} $gold_root->descendants;
    my @common = Algorithm::Diff::LCS( \@pred_tokens, \@gold_tokens );

    my $focus = $self->focus;
    $self->_stats->{correct} += grep {/$focus/} @common;
    $self->_stats->{pred}    += grep {/$focus/} @pred_tokens;
    $self->_stats->{gold}    += grep {/$focus/} @gold_tokens;
    return;
}

sub process_end {
    my ($self) = @_;
    my %pred_zones = %{$self->_stats->{zones}};
    my @pz = keys %pred_zones;
    if (!@pz) {
        warn 'Block Eval::Diff was not applied to any zone. Check the parameter zones='.$self->zones;
    } elsif (@pz > 1){
        warn "Block Eval::Diff was applied to more than one zone (@pz). "
           . 'The results are mixed together. Check the parameter zones='.$self->zones;
    }
    say "Comparing predicted trees (zone=@pz) with gold trees (zone="
        . $self->gold_zone . "), sentences=$pred_zones{$pz[0]}";
    my ($pred, $gold, $correct) = @{$self->_stats}{qw(pred gold correct)};
    printf "%-9s = %7d\n"x3, predicted=>$pred, gold=>$gold, correct=>$correct;
    ($pred, $gold) = map {$_||1} ($pred, $gold); # prevent division by zero
    my $prec = $correct / $pred;
    my $rec  = $correct / $gold;
    my $f1   = 2 * $prec * $rec / (($prec + $rec)||1);
    printf "%-9s = %6.2f%%\n"x3, precision=>100*$prec, recall=>100*$rec, F1=>100*$f1;
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Udapi::Block::Eval::Diff - evaluate differences between sentences with P/R/F1

=head1 SYNOPSIS

 # in scenario
 Eval::Diff zones=en_pred gold_zone=en_gold to=results.txt

 Eval::Diff zones=x gold_zone=y attributes=form,upos focus='^(a|the)_DET$'

 # prints e.g.
 predicted =     210
 gold      =     213
 correct   =     210
 precision = 100.00%
 recall    =  98.59%
 F1        =  99.29%

=head1 DESCRIPTION

This block finds differences between nodes of trees in two zones
and reports the overall precision, recall and F1.
The two zones are "predicted" (on which this block is applied)
and "gold" (which needs to be specified with parameter C<gold>).

This block also reports the number of total nodes in the predicted zone
and in the gold zone and the number of "correct" nodes,
that is predicted nodes which are also in the gold zone.
By default two nodes are considered "the same" if they have the same C<form>,
but it is possible to check also for other nodes' attributes
(with parameter C<attributes>).

As usual:

 precision = correct / predicted
 recall = correct / gold
 F1 = 2 * precision * recall / (precision + recall)

The implementation is based on finding the longest common subsequence (LCS)
between the nodes in the two trees.
This means that the two zones do not need to be explicitly word-aligned.

=head1 PARAMETERS

=head2 zones

Which zone contains the "predicted" trees?
Make sure that you specify just one zone.
If you leave the default value "all" and the document contains more zones,
the results will be mixed, which is most likely not what you wanted.
Exception: If the document conaints just two zones (predicted and gold trees),
you can keep the default value "all" because this block
will skip comparison of the gold zone with itself.

=head2 gold_zone

Which zone contains the gold-standard trees?

=head2 attributes

comma separated list of attributes which should be checked
when deciding whether two nodes are equivalent in LCS

=head2 focus

Regular expresion constraining the tokens we are interested in.
If more attributes were specified in the C<attributes> parameter,
their values are concatenated with underscore, so C<focus> shoul reflect that
e.g. C<attributes=form,upos focus='^(a|the)_DET$'>.

For case-insensitive focus use e.g. C<focus='^(?i)the$'>
(which is equivalent to C<focus='^[Tt][Hh][Ee]$'>)

=head1 AUTHOR

Martin Popel E<lt>popel@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
