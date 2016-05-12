package Udapi::Core::Run;
use strict;
use warnings;
use Carp;
use Moo;
use MooX::Options protect_argv => 0, usage_string => "usage: %c %o scenario [-- input_files]\nscenario is a sequence of blocks and scenarios (Scen::* modules or *.scen files)\noptions:";

use autodie;
use Exporter;
use base 'Exporter';
our @EXPORT_OK = q(udapi_runner);

use List::MoreUtils qw(first_index);
use Udapi::Core::Document;
use Udapi::Core::ScenarioParser;

option dump_scenario => (
    is    => 'ro',
    short => 'd',
    doc   => 'Just dump (print to STDOUT) the given scenario and exit.'
);

option quiet => (
    is      => 'ro',
    short   => 'q',
    default => 0,
    #trigger  => sub { Treex::Core::Log::log_set_error_level('FATAL'); },
    doc     => q{Warning, info and debug messages are suppressed. Only fatal errors are reported.},
);

has filenames => (
    is  => 'ro',
    doc => 'optional input file names, specified after "--" on the command line',
);

has global_params => (
    is=>'ro',
    default=> sub{ {} },
    doc => 'hashref with global parameters (shared by all blocks)',
);

# A factory subroutine, creating the right runner object
sub udapi_runner {
    # ref to array of arguments, or a string containing all arguments as on the command line
    my $arguments = shift;
    if ( ref($arguments) eq 'ARRAY' && scalar @$arguments > 0 ) {
        my @args = ( argv => $arguments );
        my $idx = first_index { $_ eq '--' } @$arguments;
        if ( $idx != -1 ) {
            push @args, filenames => [ splice @$arguments, $idx + 1 ];
            pop @$arguments;    # delete "--"
        }
        my $runner = Udapi::Core::Run->new_with_options( @args );
        $runner->execute();
    }
    elsif ( defined $arguments && ref($arguments) ne 'ARRAY' ) {
        udapi_runner( [ grep { defined $_ && $_ ne '' } split( /\s/, $arguments ) ] );
    }
    else {
        Udapi::Core::Run->new_with_options()->options_usage();
    }
    return;
}

sub execute {
    my ($self) = @_;

    # If someone wants to run treex -d My::Block my_scen.scen
    if ( $self->dump_scenario ) {
        print "not implemented yet\n"; # TODO: dump scenario
        exit;
    }

    my $scen_str = $self->_construct_scenario_string_with_quoted_whitespace();

    # TODO
    # some command line options are just shortcuts for blocks; the blocks are added to the scenario now
    #if ( $self->filenames ) {
    #    my $reader = $self->_get_reader_name_for( @{ $self->filenames } );
    #    log_info "Block $reader added to the beginning of the scenario.";
    #    $scen_str = "$reader from=" . join( ',', @{ $self->filenames } ) . " $scen_str";
    #}
    # $self->tokenize $self->lang $self->selector $self->save

    # parse the scenario specification stored in string, load subscenarios
    my @block_items = Udapi::Core::ScenarioParser::parse($scen_str);

    # We want to fail as soon as possible if there are any bugs in the blocks.
    # So we divide loading of blocks into 4 steps: use, new, process_start, process_document.
    # Step #1 should be the fastest one and catch all compile-time errors.
    # 1. use Block::A; use Block::B; ...
    foreach my $block_item (@block_items) {
        my $block_name = $block_item->{block_name};
        eval "use $block_name; 1;" or confess "Can't use block $block_name !\n$@\n";
    }

    # 2. Block::A->new(\%paramsA); ...
    # This step should be also fast and catch invalid/missing parameters and constructor problems
    my @blocks;
    foreach my $block_item (@block_items) {
        push @blocks, $self->_create_block($block_item);
    }

    # 3. load models etc. within process_start();
    foreach my $block (@blocks) {
        $block->process_start();
    }

    # 4. the main processing ($blockA->process_document($doc)...)
    my $number_of_blocks = @blocks;
    my $doc_number = 0;
    my $was_last_document = 0;

    DOC:
    while(!$was_last_document) {
        my $doc = Udapi::Core::Document->new();
        $doc_number++;
        my $block_number = 0;
        foreach my $block (@blocks) {
            $block_number++;
            my $block_name = ref($block);

            warn "Applying block $block_number/$number_of_blocks $block_name\n";
            $block->process_document($doc);
        }
        # TODO:
        $was_last_document = 1;
    }

    # 5. call process_end();
    foreach my $block (@blocks) {
        $block->process_end();
    }

    return;
}

# Parameters can contain whitespaces that should be preserved
sub _construct_scenario_string_with_quoted_whitespace {
    my ($self) = @_;
    my @arguments;
    foreach my $arg (@ARGV) {
        if ( $arg =~ /([^=\s]+)=(.*\s.*)$/ ) {
            my ( $name, $value ) = ( $1, $2 );
            $value =~ s/'/\\'/g;
            push @arguments, qq($name='$value');
        }
        else {
            push @arguments, $arg;
        }
    }
    return join ' ', @arguments;
}

sub _use_block {
    my ( $self, $block_item ) = @_;
    my $block_name = $block_item->{block_name};
    eval "use $block_name; 1;" or confess "Can't use block $block_name !\n$@\n";
    return;
}

sub _create_block {
    my ( $self, $block_item ) = @_;
    my $block_name = $block_item->{block_name};

    # Initialize with global (scenario) parameters
    my %params = ( %{ $self->global_params }, runner => $self );

    # which can be overriden by (local) block parameters.
    foreach my $param ( @{ $block_item->{block_parameters} } ) {
        my ( $name, $value ) = @$param;
        $params{$name} = $value;
    }

    my $new_block;
    eval {
        $new_block = $block_name->new( \%params );
        1;
    } or confess "Error when initializing block $block_name\n\nEVAL ERROR:\t$@";

    return $new_block;
}

1;
