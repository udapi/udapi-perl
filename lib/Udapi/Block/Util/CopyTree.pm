package Udapi::Block::Util::CopyTree;
use Udapi::Core::Common;
extends 'Udapi::Core::Block';

has_ro to_zone => (required=>1);

sub process_tree {
    my ( $self, $root ) = @_;
    my $new_root = $root->copy_tree();
    $new_root->set_zone($self->to_zone);
    $root->bundle->add_tree($new_root);
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Udapi::Block::Util::CopyTree - copy tree to another zone

=head1 SYNOPSIS

  # on the command line
  Util::CopyTree zones=en to_zone=en_backup

=head1 DESCRIPTION

Note that the parameter C<to_zone> specifies just one target zone.
So if you use C<Util::CopyTree zones=all to_zone=en_backup>
and you have more than one zone in some bundle,
you will get an error I<Tree with zone 'en_backup' already exists in bundle...>.
In future, a parameter C<to_zone_regex> may be added,
which would allow to specify a renaming pattern for copying more zones at once.

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
