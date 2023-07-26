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
    [map {ToyNN::PerceptronLayer::sigmoid($_)} -15,-5,-5,5],
    [map {ToyNN::PerceptronLayer::sigmoid($_)} -5,5,5,15]
];

# create a network with just one layer
my $network = ToyNN::PerceptronNetwork::->new(2, 2);
for my $layer ( @{ $network->{layers} }) {
    # for testing purposes, guarantee that all weights and biases are 1
    $layer->{W} .= 1;   # set all elements to 1
    $layer->{B} .= 1;   # set all elements to 1
    $layer->set_learning_rate(1);
    print $layer->W, $layer->B;
}

my $output = $network->feedforward($X);
print "Output => ", $output;

# next, do a single training epoch -- start without any of the complications of multiple layers, but add that in later
$network->backpropagate($X, $output, $TARGET);

__END__

# train 100 epochs
for(1..100) {
    my $Q = $layer->feedforward($X);
    my $E = $TARGET - $Q;
    #printf "%-15.15s => %s\n", "SSE($_)", $layer->eSSE($E);
    $layer->backpropagate($X, $Q, $E);
}
print "final weights & biases => ", $layer->W, $layer->B;
printf "%-15.15s => %s\n", "SSE(END)", $layer->iSSE($X, $TARGET);
