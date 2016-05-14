package Udapi::Block::Util::RenameTree;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

has_ro to_zone => (required=>1);

sub process_tree {
    my ( $self, $root ) = @_;
    my $to_zone = $self->to_zone;
    confess "Tree with zone '$to_zone' already exists in bundle " . $root->bundle->id
        if any {$to_zone eq $_->zone} $root->bundle->trees;
    $root->_set_zone($to_zone);
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Block::Util::RenameTree - rename tree to another zone

=head1 SYNOPSIS

  # on the command line
  Util::RenameTree zones=en to_zone=en_backup

=head1 DESCRIPTION

Note that the parameter C<to_zone> specifies just one target zone.
So if you use C<Util::RenameTree zones=all to_zone=en_backup>
and you have more than one zone in some bundle,
you will get an error I<Tree with zone 'en_backup' already exists in bundle...>.
In future, a parameter C<to_zone_regex> may be added,
which would allow to specify a pattern for renaming more zones at once.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
