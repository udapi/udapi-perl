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

# TODO: if a derived class uses before process_document => sub{},
# e.g. for printing a header (as is the case with Write::Treex),
# this before code will be called befor this process_document
# and the header will be printed to a wrong filename.

sub process_document {
    my ($self, $doc) = @_;
    if ($self->to ne '-'){
        close STDOUT;
        my $filename = $self->next_filename;
        if (!defined $filename){
            cluck 'There are more documents to save than filenames given ('. $self->to . ').';
        } elsif ($filename eq '-') {
            select STDOUT;
        } else {
            my $mode = '>:'.$self->encoding;
            open STDOUT, $mode, $filename;
        }
    }
    return $self->SUPER::process_document($doc);
}

1;

__END__

before process_document => sub {
    my ($self, $doc) = @_;
    return if $self->to eq '-';

    close STDOUT;
    my $filename = $self->next_filename;
    if (!defined $filename){
        cluck 'There are more documents to save than filenames given ('. $self->to . ').';
    } elsif ($filename eq '-') {
        select STDOUT;
    } else {
        my $mode = '>:'.$self->encoding;
        open STDOUT, $mode, $filename;
    }
    return;
};

1;