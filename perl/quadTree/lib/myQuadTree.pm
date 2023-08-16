package myQuadTree;

use 5.014; # strict, //, s//r
use warnings;
use Carp;
use Exporter 5.57 qw/import/;  our @EXPORT = qw/myQuadTree/;
use myQuadTree::Region;

our $VERSION = 0.01;

sub myQuadTree
{
    my ($boundary, $capacity) = @_;
    __PACKAGE__->new($boundary, $capacity);
}

sub new
{
    my ($class, $boundary, $capacity) = @_;
    my $self = bless {
        boundary => $boundary // croak("boundary region is required"),
        capacity => $capacity // croak("tree node's capacity is required"),
        items    => [],
        divided  => undef,
    }, $class;
}

# getters
sub boundary { return $_[0]->{boundary} }
sub capacity { return $_[0]->{capacity} }
sub items    { return $_[0]->{items} }

# lvalue: simple getter/setters
sub divided : lvalue  { $_[0]->{divided} }
sub northwest : lvalue { $_[0]->{northwest} }
sub northeast : lvalue { $_[0]->{northeast} }
sub southwest : lvalue { $_[0]->{southwest} }
sub southeast : lvalue { $_[0]->{southeast} }

# step 9 required a count of the points/items in the current tree node; I want to abstract that
sub countItems
{
    my ($self) = @_;
    scalar @{ $self->{items} };
}

sub addItemAtPoint
{
    my ($self, $item, $ptx, $pty) = @_; # step 7
    if(!$self->boundary->contains($ptx,$pty))
    {
        return undef;
    }
    if($self->countItems < $self->capacity) {
        my $pointItem = Item($item, $ptx, $pty);
        push @{$self->items}, $pointItem;
        return 1;
    } else {
        $self->divided or $self->subdivide();
        # now that it's subdivided, let each of the four quadrants decide whether to accept
        $self->northwest->addItemAtPoint($item, $ptx, $pty);   # at step 14, the point will incorrectly go in all four quadrants
        $self->northeast->addItemAtPoint($item, $ptx, $pty);   # at step 14, the point will incorrectly go in all four quadrants
        $self->southwest->addItemAtPoint($item, $ptx, $pty);   # at step 14, the point will incorrectly go in all four quadrants
        $self->southeast->addItemAtPoint($item, $ptx, $pty);   # at step 14, the point will incorrectly go in all four quadrants
    }
}

sub subdivide
{
    my ($self) = @_;
    my ($cx,$cy,$rx,$ry) = map { $self->boundary()->{$_} } qw/cx cy rx ry/;
    my $cap = $self->capacity;
    my $nw = Rectangle($cx-$rx/2, $cy+$ry/2, $rx/2, $ry/2); $self->northwest = myQuadTree($nw, $cap);
    my $ne = Rectangle($cx+$rx/2, $cy+$ry/2, $rx/2, $ry/2); $self->northeast = myQuadTree($ne, $cap);
    my $sw = Rectangle($cx-$rx/2, $cy-$ry/2, $rx/2, $ry/2); $self->southwest = myQuadTree($sw, $cap);
    my $se = Rectangle($cx+$rx/2, $cy-$ry/2, $rx/2, $ry/2); $self->southeast = myQuadTree($se, $cap);
    $self->divided = 1;
}

1;
