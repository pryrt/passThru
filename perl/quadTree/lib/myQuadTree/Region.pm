package myQuadTree::Region;

use 5.014; # strict, //, s//r
use warnings;
use Carp;
use Exporter 5.57 qw/import/;  our @EXPORT = qw/Rectangle Circle/;

our $VERSION = 0.01;

sub Rectangle
{
    my ($cx,$cy, $rx, $ry) = @_;
    __PACKAGE__->new('rect', $cx,$cy, $rx,$ry);
}

sub Circle
{
    my ($cx,$cy, $r) = @_;
    __PACKAGE__->new('circ', $cx,$cy, $r,$r);
}

sub new
{
    my ($class, $type, $centerx, $centery, $halfwidth, $halfheight) = @_;
    my %types = ( rect => 1, circ => 1, point => 1 );
    defined $type and exists $types{$type} or croak("$class constructor: type must be supplied as one of @{[sort keys %types]}");
    my $self = bless {
        type => $type,
        cx => $centerx      // croak("$class($type) needs a center x specified"),
        cy => $centery      // croak("$class($type) needs a center y specified"),
        rx => $halfwidth    // croak("$class($type) needs a halfwidth specified"),
        ry => $halfheight   // croak("$class($type) needs a halfheight specified"),
    }, $class;
}

1;
