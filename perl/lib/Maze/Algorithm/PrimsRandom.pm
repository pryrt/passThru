package Maze::Algorithm::PrimsRandom 1.000000;
# https://github.com/emadehsan/maze/blob/main/src/algorithms/prims_randomized.py
use 5.012; # //, strict, say
use warnings;
use autodie;
use Maze::Algorithm::PrimsRandom;

use Data::Dump qw/dd/;

sub total_nodes { $_[0]->{total_nodes} }
sub row_len { $_[0]->{row_len} }

sub new
{
    my ($class, $row_len) = @_;
    my $self = bless { row_len => $row_len }, $class;
    $self->{total_nodes} = $row_len**2;
    return $self;
}

sub prims_mst
{
    my ($self) = @_;
    my $n1 = $self->total_nodes - 1;

    # nodes to visit
    my @to_visit = ( 0 .. $n1 );

    # initialize the minimum spanning tree with no neighbors for each node to visit
    my $mst = [];
    push @$mst, {TOP=>0,LEFT=>0,BOTTOM=>0,RIGHT=>0} for @to_visit;

    # start Prim's algorithm by visiting the first node
    my $node = splice @to_visit, 0, 1;  # take the first node out of @to_visit and put it in $node instead
    my $visited = [$node];              # this is the only node visited so far

    # for all the nodes in visited, pick an outgoing edge
    # at random, connecting to a new node that isn't already visited
    while(@to_visit) {
        my @edges_pool = $self->edges_to_unvisited_nodes($visited);

        # pick a random edge
        my $edge = $edges_pool[rand @edges_pool];
        ($node, my $next_node) = @$edge;

        # connect these two nodes in the minimum spanning tree
        my $direction = $self->get_neighbor_dir($node, $next_node);
        $mst->[$node]{$direction} = 1;

        # also set it for the neighbor
        my $neighbor_dir = $self->get_neighbor_dir($next_node, $node);
        $mst->[$node]{$neighbor_dir} = 1;

        # now remove this next_node from unvisited and add it to visited
        push @$visited, $next_node;
        splice @to_visit, $next_node; # this isn't right... it is deleting the nth element, not the element with value n. :-(
            # TODO = revisit data structures
            last;# temporarily stop after first
    }

    # return the minimum spanning tree
    return $mst;
}

# returns all the edges originating from already visited nodes and going
# towards unvisited nodes
sub edges_to_unvisited_nodes
{
    return [1,2];
}

# returns the direction in which next_node
sub get_neighbor_dir
{
    my ($self, $node, $next_node) = @_;
    if($node - $self->row_len == $next_node) { return 'TOP' }       # one row above is whole row before
    if($node + $self->row_len == $next_node) { return 'BOTTOM' }    # one row below is whole row after
    if($node - 1 == $next_node) { return 'LEFT' }
    if($node + 1 == $next_node) { return 'RIGHT' }
    die "shouldn't get here, I think";
}

1;
