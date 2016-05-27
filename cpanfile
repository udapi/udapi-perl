requires 'Algorithm::Diff';
requires 'Class::XSAccessor::Array';
requires 'Data::Printer';
requires 'Import::Into';
requires 'List::MoreUtils';
requires 'List::Util', '1.33';
requires 'Moo';
requires 'Moo::Role';
requires 'MooX::Options';
requires 'MooX::TypeTiny';
requires 'PerlIO::gzip';
requires 'Scalar::Util';
requires 'Term::ANSIColor';
requires 'Types::Standard';
requires 'autodie';
requires 'feature';
requires 'parent';
requires 'perl', '5.010';
requires 'version';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};
