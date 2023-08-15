package myQuadTree::Region;

use 5.014; # strict, //, s//r
use warnings;
use Carp;
use Exporter 5.57 qw/import/;  our @EXPORT = qw/Rectangle Circle Point Item/;

our $VERSION = 0.01;

sub Rectangle
{
    my ($cx,$cy, $rx, $ry) = @_;
    __PACKAGE__->new('rectangle', $cx,$cy, $rx,$ry);
}

sub Circle
{
    my ($cx,$cy, $r) = @_;
    __PACKAGE__->new('circle', $cx,$cy, $r,$r);
}

sub Point
{
    my ($cx,$cy) = @_;
    __PACKAGE__->new('point', $cx,$cy, 0,0);
}

sub Item
{
    my($item, $cx, $cy) = @_;
    defined $item and ref $item or croak("Item() must be given an item");
    my $self = Point($cx, $cy);
    $self->myItem = $item;
    return $self;
}

sub new
{
    my ($class, $type, $centerx, $centery, $halfwidth, $halfheight) = @_;
    my %types = ( rectangle => 1, circle => 1, point => 1 );
    defined $type and exists $types{$type} or croak("$class constructor: type must be supplied as one of @{[sort keys %types]}");
    my $self = bless {
        type => $type,
        cx => $centerx      // croak("$class($type) needs a center x specified"),
        cy => $centery      // croak("$class($type) needs a center y specified"),
        rx => $halfwidth    // croak("$class($type) needs a halfwidth specified"),
        ry => $halfheight   // croak("$class($type) needs a halfheight specified"),
    }, $class;
}

sub myItem : lvalue { $_[0]->{myItem} }

1;
