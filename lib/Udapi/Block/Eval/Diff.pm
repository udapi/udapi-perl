package Udapi::Block::Eval::Diff;
use Udapi::Core::Common;
extends 'Udapi::Core::Writer';
use Algorithm::Diff;

has_ro gold_zone => (required=>1);

has_ro attributes => (default=>'form');

has_ro focus => (default=>'.*');

has_ro _stats => (default=>sub{{zones=>{}}});

has_ro details => (default=>4);

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
    if ($focus ne '.*') {
        @common      = grep {/$focus/} @common;
        @pred_tokens = grep {/$focus/} @pred_tokens;
        @gold_tokens = grep {/$focus/} @gold_tokens;
    }

    $self->_stats->{correct} += @common;
    $self->_stats->{pred}    += @pred_tokens;
    $self->_stats->{gold}    += @gold_tokens;

    if ($self->details){
        $self->_stats->{C}{$_}++ for (@common);
        $self->_stats->{P}{$_}++ for (@pred_tokens);
        $self->_stats->{G}{$_}++ for (@gold_tokens);
        $self->_stats->{T}{$_}++ for (@gold_tokens, @pred_tokens);
    }
    return;
}

sub process_end {
    my ($self) = @_;

    # Redirect the default filehandle to the file specified by $self->to
    $self->before_process_document();

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

    if ($self->details){
        say '=== Details ===';
        my $total_count = $self->_stats->{T};
        my @tokens = sort {$total_count->{$b} <=> $total_count->{$a}} keys %{$total_count};
        splice @tokens, $self->details;
        printf "%-10s %5s %5s %5s %6s  %6s  %6s\n", qw(token pred gold corr prec rec F1);
        foreach my $token (@tokens){
            my ($p, $g, $c) = map {$self->_stats->{$_}{$token}||0} (qw(P G C));
            my $pr = $c / ($p || 1);
            my $re = $c / ($g || 1);
            my $f  = 2 * $pr * $re / (($pr + $re)||1);
            printf "%-10s %5d %5d %5d %6.2f%% %6.2f%% %6.2f%%\n",
                $token, $p, $g, $c, 100*$pr, 100*$re, 100*$f
        }
        say '=== Totals ==='
    }

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

 Eval::Diff zones=en_pred gold_zone=en_gold to=results.txt

 # prints something like
 predicted =     210
 gold      =     213
 correct   =     210
 precision = 100.00%
 recall    =  98.59%
 F1        =  99.29%

 Eval::Diff gold_zone=y attributes=form,upos focus='^(?i:an?|the)_DET$' details=4

 # prints something like
 === Details ===
 token       pred  gold  corr   prec     rec      F1
 the_DET      711   213   188  26.44%  88.26%  40.69%
 The_DET       82    25    19  23.17%  76.00%  35.51%
 a_DET          0    62     0   0.00%   0.00%   0.00%
 an_DET         0    16     0   0.00%   0.00%   0.00%
 === Totals ===
 predicted =     793
 gold      =     319
 correct   =     207
 precision =  26.10%
 recall    =  64.89%
 F1        =  37.23%

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

=head2 details

Print also detailed statistics for each token (matching the C<focus>).
The value of this parameter C<details> specifies the number of tokens to include.
The tokens are sorted according to the sum of their I<predicted> and I<gold> counts.

=head1 AUTHOR

Martin Popel E<lt>popel@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
