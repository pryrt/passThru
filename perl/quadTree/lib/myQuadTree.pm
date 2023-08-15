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
        points   => [(undef) x $capacity],
        divided  => undef,
    }, $class;
}

1;
