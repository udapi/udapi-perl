package Udapi::Core::Role::Reader;
use Moo::Role;

requires 'is_multizone_reader';
requires 'process_document';

1;
