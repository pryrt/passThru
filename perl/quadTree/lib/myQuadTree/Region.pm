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

# getters
sub cx { $_[0]->{cx} }
sub cy { $_[0]->{cy} }
sub rx { $_[0]->{rx} }
sub ry { $_[0]->{ry} }
sub type { $_[0]->{type} }

# lvalue getter/setters
sub myItem : lvalue { $_[0]->{myItem} }

# steps 16 & 20: implement ->contains and make it be true for edges
#   if I ever implement the circular region checking from the CodingTrain repo,
#   I will need a flag of some sort to decide whether to check rectangle or circle
sub contains
{
    my ($self, $px, $py) = @_;
    return ($px >= $self->cx - $self->rx)
        && ($px <= $self->cx + $self->rx)
        && ($py >= $self->cy - $self->ry)
        && ($py <= $self->cy + $self->ry)
    ;
}

# step 202: implement ->intersects
#   if I ever implement circular region, I will need a flag to decide whether to check rectangle or circle
sub intersects
{
    my ($self, $range) = @_;
    return !(   ($range->cx - $range->rx) > ($self->cx + $self->rx)
            ||  ($range->cx + $range->rx) > ($self->cx - $self->rx)
            ||  ($range->cy - $range->ry) > ($self->cy + $self->ry)
            ||  ($range->cy + $range->ry) > ($self->cy - $self->ry)
    );
}


1;
