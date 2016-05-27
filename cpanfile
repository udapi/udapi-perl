requires 'Algorithm::Diff';
requires 'Class::XSAccessor::Array';
requires 'Data::Printer';
requires 'File::Slurp', '9999.19';
requires 'Import::Into';
requires 'List::MoreUtils';
requires 'List::Util', '1.33';
requires 'Moo';
requires 'Moo::Role';
requires 'MooX::Options';
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
