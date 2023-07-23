#!perl -l

# TODO: Add the Test::More stuff necessary to test that a single layer is working correctly,
# given the known starting point of weights/biases all set to 1, and 1 and 100 epochs
# FindBin should not be needed for the test version

use 5.014; # //, strict, say, s///r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";
use PDL;
use ToyNN::PerceptronNetwork;
$| = 1;


# standalone layer

# define the inputs
my $X = pdl [[ 0, 0, 1, 1],[ 0, 1, 0, 1]];

# define a target output for the trained version
my $TARGET = pdl
[
    [map {ToyNN::PerceptronLayer::sigmoid($_)} -15,-5,-5,5],
    [map {ToyNN::PerceptronLayer::sigmoid($_)} -5,5,5,15]
];

# create a standalone layer
my $layer = ToyNN::PerceptronLayer::->new(2, 2);
$layer->{W} .= 1;   # set all elements to 1
$layer->{B} .= 1;   # set all elements to 1
$layer->set_learning_rate(1);

for(1..100) {
    my $Q = $layer->feedforward($X);
    my $E = $TARGET - $Q;
    #printf "%-15.15s => %s\n", "SSE($_)", $layer->eSSE($E);
    $layer->backpropagate($X, $Q, $E);
}
print "final weights & biases => ", $layer->W, $layer->B;
printf "%-15.15s => %s\n", "SSE(END)", $layer->iSSE($X, $TARGET);
