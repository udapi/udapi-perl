package Udapi::Core::Files;
use Udapi::Core::Common;
#use PerlIO::gzip;
use File::Basename;
use File::Slurp 9999.19;
use Types::Standard qw(ArrayRef);

has_ro filenames => ( writer => '_set_filenames', isa=>ArrayRef);
has_ro filehandle => ( writer => '_set_filehandle',);
has_rw encoding => ( default  => 'utf8');

has_ro file_number => (
    isa => Int,
    writer        => '_set_file_number',
    default       => 0,
    init_arg      => undef,
    doc => 'Number of the current file',
);

sub BUILD {
    my ( $self, $args ) = @_;
    if ($args->{filenames}){
        ## Nothing to do, $args->{filenames} are ArrayRef checked by Moo
    } elsif(defined $args->{string}){
        $self->_set_filenames( $self->string_to_filenames( $args->{string} ) );
    } else {
        confess 'One of the parameters (filenames, string)  is required';
    }
    return;
}

sub string_to_filenames {
    my ( $self, $string ) = @_;

    # "!" means glob pattern which can contain {dir1,dir2}
    # so it cannot be combined with separating tokens with comma.
    if ($string =~ /^!(.+)/) {
        my @filenames = glob $1;
        cluck "No filenames matched '$1' pattern" if !@filenames;
        return \@filenames;
    }

    return [ map { $self->_token_to_filenames($_) } grep {/./} split /[ ,]+/, $string ];
}

sub _token_to_filenames {
    my ( $self, $token ) = @_;
    if ($token =~ /^!(.+)/) {
        my @filenames = glob $1;
        cluck "No filenames matched '$1' pattern" if !@filenames;
        return @filenames;
    }
    return $token if $token !~ s/^@(.*)/$1/;
    my $filelist = $token eq '-' ? \*STDIN : $token;
    my @filenames = grep { $_ ne '' } read_file( $filelist, chomp => 1 );

    # Filname in a filelist can be relative to the filelist directory.
    my $dir = dirname($token);
    return @filenames if $dir eq '.';
    return map {!m{^/} ? "$dir/$_" : $_} @filenames;
}

sub number_of_files {
    my ($self) = @_;
    return scalar @{ $self->filenames };
}

sub filename {
    my ($self) = @_;
    return if $self->file_number == 0 || $self->file_number > @{ $self->filenames };
    return $self->filenames->[ $self->file_number - 1 ];
}

sub next_filename {
    my ($self) = @_;
    $self->_set_file_number( $self->file_number + 1 );
    return $self->filename;
}

sub has_next_file {
    my ($self) = @_;
    return $self->file_number < $self->number_of_files;
}

sub next_filehandle {
    my ($self) = @_;
    my $filename = $self->next_filename();
    my $FH = $self->filehandle;

    if (!defined $filename){
        $FH = undef;
    }
    elsif ( $filename eq '-' ) {
        binmode STDIN, $self->encoding;
        $FH = \*STDIN;
    }
    else {
        my $mode = $filename =~ /[.]gz$/ ? '<:gzip:' : '<:';
        $mode .= $self->encoding;
        open $FH, $mode, $filename or confess "Can't open $filename: $!";
    }
    $self->_set_filehandle($FH);
    return $FH;
}

# TODO: POD, next_filehandle, gz support

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Core::Files - helper class for iterating over filenames

=head1 SYNOPSIS

  use Udapi::Core::Files;

  my $f = Udapi::Core::Files->new(string=>'f1.txt f2.txt.gz @my.filelist');

  while (defined (my $filename = $f->next_filename)){ ... }
  #or
  while (my $filehandle = $f->next_filehandle){ ... }

  # You can use also wildcard expansion
  my $f = Udapi::Core::Files->new(string=>'!dir??/file*.txt');

  $f->filehandle;
  $f->filename;
  $f->number_of_files;


=head1 DESCRIPTION

The I<@filelist> and I<!wildcard> conventions are used in several tools, e.g. 7z or javac.
For a large number of files, list the file names in a file - one per line.
Then use the list file name preceded by an @ character.

Methods <next_*> serve as iterators and return undef if the called after the last file is reached.

=head1 METHODS

=head2 number_of_files

Returns the total number of files contained by this instance.

=head2 file_number

Returns ordinal number (1..number_of_files) of the current file.

=head2 filename

Returns the current filename or undef if the iterator is before the first file
(i.e. C<next_filename> has not been called so far) or after the last file.

=head2 next_filename

Returns the next filename (and increments the file_number).

=head2 filehandle

Opens the current file for reading and returns the filehandle.
Filename "-" is interpreted as STDIN.
Filenames with extension ".gz" are opened via L<PerlIO::via::gzip> (ie. unzipped on the fly).

=head2 next_filehandle

Returns the next filehandle (and increments the file_number).

=head2 next_file_text

Returns the content of the next file (slurp) and increments the file_number.

=head2 next_line

Returns the next line of the current file.
If the end of file is reached and attribute C<join_files_for_next_line> is set to true (which is by default),
the first line of next file is returned (and file_number incremented).


=head2 $filenames_ref = string_to_filenames($string)

Helper method that expands comma-or-space-separated list of filenames
and returns an array reference containing the filenames.
If the string starts with "!", it is interpreted as wildcards (see Perl L<glob>).
If a filename starts with "@" it is interpreted as a file list with one filename per line.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
