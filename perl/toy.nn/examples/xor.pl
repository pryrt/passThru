#!perl -l
# now moving from a standalone layer to a PerceptronNetwork that has only a single layer

use 5.014; # //, strict, say, s///r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";
use PDL;
use ToyNN::PerceptronNetwork;
$| = 1;

# define the inputs
my $X = pdl [[ 0, 0, 1, 1],[ 0, 1, 0, 1]];

# define a target output for the trained version
my $TARGET = pdl
[
    [map {ToyNN::PerceptronLayer::sigmoid($_)} -5,5,5,-5],
];

# create a network with two layers
my $network = ToyNN::PerceptronNetwork::->new(2, 2, 1);
# for testing purposes (comparison against spreadsheet), guarantee that all weights and biases are 1 for first layer
my $layer = ${ $network->{layers} }[0];
$layer->{W} .= 1;   # set all elements to 1
$layer->{B} .= 1;   # set all elements to 1
$layer->set_learning_rate(1);
print $layer->W, $layer->B;
# for testing purposes (comparison against spreadsheet), set weights and biases to -2, +2, -1
$layer = ${ $network->{layers} }[1];
$layer->{W}->slice(0,0) .= -2;
$layer->{W}->slice(1,0) .= +2;
$layer->{B} .= -1;
$layer->set_learning_rate(1);
print $layer->W, $layer->B;


# initial feedforward
my $output = $network->feedforward($X);
print "Initial Output => ", $output;
my $ll = $network->lastLayerIndex;
my $sse = $network->L($ll)->oSSE($output, $TARGET);
print "Initial SSE => ", $sse;

# next, do a single training epoch -- start without any of the complications of multiple layers, but add that in later
$network->backpropagate($X, $output, $TARGET);

$output = $network->feedforward($X);
print "Updated Output => ", $output;
$ll = $network->lastLayerIndex;
$sse = $network->L($ll)->oSSE($output, $TARGET);
print "Updated SSE => ", $sse;

# another 99 epochs
$network->backpropagate($X, $output, $TARGET) for 1..99;

$output = $network->feedforward($X);
print "100th Output => ", $output;
$ll = $network->lastLayerIndex;
$sse = $network->L($ll)->oSSE($output, $TARGET);
print "100th SSE => ", $sse;
