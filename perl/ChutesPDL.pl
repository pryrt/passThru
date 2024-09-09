#!perl -l
# Chutes And Ladders Markov Chain with PDL
#   (actually, something more similar to Nonograms's "Dice" mini-game, which is essentially a 200-square Chutes/Snakes+Ladders)
use 5.014; # strict, //, s//r
use warnings;
use PDL;
$|=1; # autoflush

# The current state should be a vertical vector, with a count of the number of ways to have reached that state
#   ndarrays are 0-based, just like perl, but the Dice mini-game starts the player at "1"
#   but I'm going to design this interface as 0-based, so "0" means start and "199" means end.
#print "state => ",
my $S = zeros(1,200);

# https://metacpan.org/pod/PDL::Slices#range for simple ranges; if I want fancier, might go to NiceSlice
$S->range([0,0]) .= 1;  # set the first element to 1    # cannot use $S->at(...) as lvalue, but can use ->range() as lvalue with .=
print "state => ", $S->transpose();

# the state transition matrix M will be a map from row=starting position to col=ending position
#   the values will be the number of paths to lead from row to col
#   so, for example, from state0, you can make it with equal probability to 1-6, so those will all be ones
my $M = zeros(200,200);
$M->range([1,0], [6,1]) .= ones(6,1);   # assigns the 1/6 probability to each of the 6 possible destinations
# assuming no chutes or ladders, I can just fill the offsets
for my $i ( 0 .. 193 ) {
    my $j = $i + 1;
    $M->range([$j,$i], [6,1]) .= ones(6,1);
}
for my $i ( 194 .. 198 ) {
    my $j = $i + 1;
    my $w = 199 - $i;
    $M->range([$j,$i], [$w,1]) .= ones($w,1); $M->range([199,$i]) += ($i-193);
}
#$M->range([196,195], [4,1]) .= ones(4,1); $M->range([199,195]) += 2;
#$M->range([197,196], [3,1]) .= ones(3,1); $M->range([199,196]) += 3;
#$M->range([198,197], [2,1]) .= ones(2,1); $M->range([199,197]) += 4;
#$M->range([199,198], [1,1]) .= ones(1,1); $M->range([199,198]) += 5;
#print "M => ", $M;

# example using NiceSlice:
use PDL::NiceSlice;
print "M[c:0:9,r:0:9] => ", $M->(0:9,0:9);
print "M[c:190:199,r:190:199] => ", $M->(190:199,190:199);
