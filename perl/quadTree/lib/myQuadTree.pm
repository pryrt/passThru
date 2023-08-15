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

# lvalue: simple getter/setter
sub divided : lvalue  { $_[0]->{divided} }

# step 9 required a count of the points/items in the current tree node; I want to abstract that
sub countItems
{
    my ($self) = @_;
    scalar @{ $self->{items} };
}

sub addItemAtPoint
{
    my ($self, $item, $ptx, $pty) = @_; # step 7
    if($self->countItems < $self->capacity) {
        my $pointItem = Item($item, $ptx, $pty);
        push @{$self->items}, $pointItem;
    }
}

1;
