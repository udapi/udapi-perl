package Udapi::Core::Writer;
use Udapi::Core::Common;
use Udapi::Core::Files;
extends 'Udapi::Core::Block';
use autodie;

has_rw to => (
    #coerce        => \&Udapi::Core::Files::coerce,
    #isa           => 'Udapi::Core::Files', # Udapi::Core::Files->new(),
    doc => 'destination filename(s) (default is "-" meaning standard output',
    default => '-',
);

has_ro _files => (
    writer => '_set_files',
    handles => [qw(filename file_number next_filename)],
);

has_ro encoding => ( default  => 'utf8' );

sub BUILD {
    my ($self) = @_;
    $self->_set_files(Udapi::Core::Files->new(string=>$self->to));
    return;
}

sub before_process_document {
    my ($self, $doc) = @_;
    if ($self->to eq '-'){
        select STDOUT;
        return;
    }

    my $old_filehandle = select;
    if (fileno($old_filehandle) != fileno(STDOUT)) {
        close $old_filehandle;
    }

    my $filename = $self->next_filename;
    if (!defined $filename){
        cluck 'There are more documents to save than filenames given ('. $self->to . ').';
    } elsif ($filename eq '-') {
        select STDOUT;
    } else {
        my $mode = '>:'.$self->encoding;
        open(my $FH, $mode, $filename);
        select $FH;
    }
    return;
};

1;

__END__

=encoding utf-8

=head1 NAME

Udapi::Core::Writer - base class of all writer blocks

=head1 SYNOPSIS

 # in scenario
 Write::XY to='a.txt,b.txt' encoding=utf8

=head1 DESCRIPTION

All writer blocks should be derived from this class,
which provides the parameters C<to> and C<encoding>.

When writing the derived class you can just use C<print>, C<say> or C<printf>
from the C<process_*> methods without specifying any filehandle
and the output will be redirected to the correct file as specified
by the parameter C<to>.

Only in C<process_start> and C<process_end> you need to explicitly
select the correct filehandle, e.g.  by calling

 $self->before_process_document();

=head1 PARAMETERS

=head2 to

See L<Udapi::Core::Files>

=head2 encoding

I<utf8> by default

=head1 AUTHOR

Martin Popel E<lt>popel@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
