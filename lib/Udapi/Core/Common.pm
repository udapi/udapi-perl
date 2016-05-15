package Udapi::Core::Common;
use strict;
use warnings;
use 5.010;
use utf8;
use Moo;
use Carp;
use List::Util 1.33;
use Scalar::Util;
use Data::Printer;
use Import::Into;

sub import {
    my $caller = caller;
    my $result = eval "package $caller;" .
<<'END';
use Moo;
use Carp qw(cluck confess);
use List::Util qw(first min max all any none);
use Scalar::Util qw(weaken);
use Data::Printer;
use MooX::TypeTiny;
use Types::Standard qw(Int Bool);

sub has_ro {my $name = shift; has($name, is=>'ro', @_);};
sub has_rw {my $name = shift; has($name, is=>'ro', writer => "set_$name", @_);};
1;
END
    confess "Error in Udapi::Core::Common (probably a missing package):\n$@" if !$result;
    require feature;
    'feature'->import('say');
    'utf8'->import;
    'strict'->import;
    'warnings'->import;
    'open'->import::into($caller, qw{:encoding(UTF-8) :std});
    return;
}

1;

__END__

# TODO
use Carp qw(carp croak confess cluck);
# give a full stack dump on any untrapped exceptions
local $SIG{__DIE__} = sub {
    confess "Uncaught exception: @_" unless $^S;
};

# now promote run-time warnings into stackdumped exceptions
#   *unless* we're in an try block, in which
#   case just generate a clucking stackdump instead
local $SIG{__WARN__} = sub {
    if ($^S) { cluck   "Trapped warning: @_" }
    else     { confess "Deadly warning: @_"  }
};

=encoding utf-8

=head1 NAME

Udapi::Core::Common - shorten the "C<use>" part of your Perl codes

=head1 SYNOPSIS

Write just

 use Udapi::Core::Common;
 has_ro foo => (default=>42);
 has_rw bar => (default=>43, isa=>Int);
 # now you can use $self->set_bar(44);

Instead of

 use utf8;
 use strict;
 use warnings;
 use feature 'say';
 use open qw(:encoding(UTF-8) :std); # STD(IN|OUT|ERR) in utf8
 use Moo;
 use Carp qw(cluck confess);
 use List::Util qw(first min max all any none);
 use Scalar::Util qw(weaken);
 use Data::Printer;
 use MooX::TypeTiny;
 use Types::Standard qw(Int Bool);

 has foo => (is=>'ro', default=>42);
 has bar => (is=>'ro', default=>43, writer=>'set_bar', isa=>Int);

=head1 DESCRIPTION

This module saves boilerplate lines from Moo based classes.
Unlike Moose, Moo has no L<MooseX::SemiAffordanceAccessor>,
which would allow for having setters with "set_" prefix
(and getters without any prefix).
So we include pseudokeywords C<has_ro> and C<has_rw>,
which also automatically include the respective "is" type.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
