package Bash::Completion::Plugins::Udapi;
use strict;
use warnings;
use parent 'Bash::Completion::Plugin';
use Bash::Completion::Utils qw( command_in_path match_perl_modules prefix_match );
use List::MoreUtils qw( any );
use Moose (); # Udapi classes are Moo-based, but we need to load Moose first, so we can use meta-object-protocol (aka introspection)

my @general_options = qw(
 -d --dump_scenario
 -h --help
 -q --quiet
 -s --save
);

sub generate_bash_setup { return [qw( nospace default )]; }

sub should_activate { return [grep { command_in_path($_) } ('udapi.pl')]; }

# Block attributes which are not supposed to be used as parameters
#my %nonparams = map {("$_=" => 1)} (qw(consumer doc_number jobindex jobs outdir));

sub get_block_parameters{
    my ($block_name) = @_;
    return if !$block_name || !eval "require $block_name";
    my $meta = Class::MOP::class_of($block_name);
    return grep {!/^_/} # && !$nonparams{$_}}
        map {$_->name."="} $meta->get_all_attributes;
}

sub complete {
    my ($self, $req) = @_;
    my @c;
    my $word = $req->word;
    my @args = $req->args;
    my $last = $args[$word ? -2 : -1] || 0;
    $last = ($last =~ /::/) ? "Udapi::Block::$last" : 0;

    if ($word eq '') {
        @c = get_block_parameters($last);
        my @blocks = match_perl_modules('Udapi::Block::');
        if (@c){
            print STDERR "\nBlocks:\n" . join("\t", @blocks) . "\n\nParameters of $last:";
        } else {
            @c = @blocks;
        }
    }
    elsif ($word =~ /^-/) {
        @c = prefix_match($word, @general_options);
    }
    elsif ($word =~ /=/) {
        # When no suggestions are given for parameter values,
        # default Bash (filename) completion is used.
    }
    else {
        @c = prefix_match($word, get_block_parameters($last));
        push @c, match_perl_modules("Udapi::Block::$word");
    }

    return $req->candidates(map {/[:=]$/ ? $_ : "$_ "} @c);
}

1;

__END__


=encoding utf-8

=head1 NAME

Bash::Completion::Plugins::Udapi - Bash completion for udapi.pl

=head1 SYNOPSIS
 
 # In Bash, press TAB to auto-complete udapi.pl commands
 $ udapi.pl Read::
 CoNLLU      Sentences
 
 $ udapi.pl Eval::Diff
 Blocks:
 Write:: Eval::  Read::  Tutorial::  Util::

 Parameters of Udapi::Block::Eval::Diff:
 attributes=  encoding=    focus=       gold_zone=   to=          zones= 
 
=head1 DESCRIPTION

L<Bash::Completion> profile for C<udapi.pl>.

Simply add these two lines to your C<.bashrc> file:

 eval "$(bash-complete setup)"
 bind 'set show-all-if-ambiguous on'

or run it manually in a bash session.

The second line is optional, but highly recommended
(unless you already have "set show-all-if-ambiguous on" in your C<~/.inputrc>).
It overrides the default Bash/Readline behavior,
so when more completions are possible
you don't need to press TAB second time to see all the suggestions.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
