package Udapi::Core::Node::Removed;
use Carp;

sub AUTOLOAD {                         ## no critic (ProhibitAutoloading)
    our $AUTOLOAD;
    if ( $AUTOLOAD !~ /DESTROY$/ ) {
        confess "You cannot call any methods on removed nodes, but have called $AUTOLOAD";
    }
}

1;
