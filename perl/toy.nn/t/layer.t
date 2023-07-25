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
use Test::More tests => 37;
$| = 1;

sub is_float_close_enough($$$;$) {
    my ($got, $exp, $tolerance, $name) = @_;
    if(!defined $name) {
        $name = $tolerance;
        $tolerance = 1e-6;
    }
    my $abserr = abs( $got - $exp );
    ok $abserr <= $tolerance, $name
        or diag sprintf "\tgot       '%s'\n\texpected  '%s'\n\ttolerance '%s'", map {$_//'<undef>'} $got, $exp, $tolerance;
}

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

# verify biases and weights are ndarrays of the right size
my $ok = isa_ok $layer->W, 'PDL', 'layer->W';
SKIP: {
    skip "cannot check dimensions if not a PDL", 3 unless $ok;
    my ($c,$r,@d) = $layer->W->dims();
    is $c, 2, "'layer->W' has 2 cols";
    is $r, 2, "'layer->W' has 2 rows";
    is scalar(@d), 0, "'layer->W' has no other dimensions";
}
isa_ok $layer->B, 'PDL', 'layer->B';
SKIP: {
    skip "cannot check dimensions if not a PDL", 3 unless $ok;
    my ($c,$r,@d) = $layer->B->dims();
    is $c, 1, "'layer->B' has 1 col";
    is $r, 2, "'layer->B' has 2 rows";
    is scalar(@d), 0, "'layer->B' has no other dimensions";
}

# verify activation function and activation slope are correct for the default sigmoid activation function
is_float_close_enough $layer->fn(0), 0.5, 'Activation: sigmoid(0)';
is_float_close_enough $layer->fn(-log(3)), 0.25, 'Activation: sigmoid(-log(3))';
is_float_close_enough $layer->df(0), 0.25, 'Activation Slope: dsigmoid(0)';

# update the weights/biases to known values
$layer->{W} .= 1;   # set all elements to 1
is_float_close_enough $layer->W->at(0,0), 1, 'W[0,0] == 1';
is_float_close_enough $layer->W->at(0,1), 1, 'W[0,1] == 1';
is_float_close_enough $layer->W->at(1,0), 1, 'W[1,0] == 1';
is_float_close_enough $layer->W->at(1,1), 1, 'W[1,1] == 1';
$layer->{B} .= 1;   # set all elements to 1
is_float_close_enough $layer->B->at(0,0), 1, 'B[0,0] == 1';
is_float_close_enough $layer->B->at(0,1), 1, 'B[0,1] == 1';

# set and verify learning rate
$layer->set_learning_rate(1);
is_float_close_enough $layer->lr, 1, 'learning rate set to 1';

my ($Q,$E, $SSE1, $SSE100);
for(1..100) {
    $Q = $layer->feedforward($X);
    $E = $TARGET - $Q;
    #printf "%-15.15s => %s\n", "SSE($_)", $layer->eSSE($E);
    $layer->backpropagate($X, $Q, $E);
    if($_==1) {
        is_float_close_enough $Q->at(0,0), 0.731, 0.0005, 'epoch(1): Q[0,0]';
        is_float_close_enough $Q->at(1,0), 0.881, 0.0005, 'epoch(1): Q[1,0]';
        is_float_close_enough $Q->at(2,0), 0.881, 0.0005, 'epoch(1): Q[2,0]';
        is_float_close_enough $Q->at(3,0), 0.953, 0.0005, 'epoch(1): Q[3,0]';
        is_float_close_enough $Q->at(0,1), 0.731, 0.0005, 'epoch(1): Q[0,1]';
        is_float_close_enough $Q->at(1,1), 0.881, 0.0005, 'epoch(1): Q[1,1]';
        is_float_close_enough $Q->at(2,1), 0.881, 0.0005, 'epoch(1): Q[2,1]';
        is_float_close_enough $Q->at(3,1), 0.953, 0.0005, 'epoch(1): Q[3,1]';
        $SSE1 = $layer->iSSE($X, $TARGET);
        $Q = $layer->feedforward($X);
        $E = $TARGET - $Q;
        is_float_close_enough $layer->oSSE($Q,$TARGET), $SSE1, 'oSSE == iSSE';
        is_float_close_enough $layer->eSSE($E), $SSE1, 'eSSE == iSSE';
    }
}
$Q = $layer->feedforward($X);
$SSE100 = $layer->oSSE($Q, $TARGET);
is_float_close_enough $Q->at(0,0), 0.017, 0.0005, 'epoch(100): Q[0,0]';
is_float_close_enough $Q->at(1,0), 0.192, 0.0005, 'epoch(100): Q[1,0]';
is_float_close_enough $Q->at(2,0), 0.192, 0.0005, 'epoch(100): Q[2,0]';
is_float_close_enough $Q->at(3,0), 0.767, 0.0005, 'epoch(100): Q[3,0]';
is_float_close_enough $Q->at(0,1), 0.202, 0.0005, 'epoch(100): Q[0,1]';
is_float_close_enough $Q->at(1,1), 0.878, 0.0005, 'epoch(100): Q[1,1]';
is_float_close_enough $Q->at(2,1), 0.878, 0.0005, 'epoch(100): Q[2,1]';
is_float_close_enough $Q->at(3,1), 0.995, 0.0005, 'epoch(100): Q[3,1]';
cmp_ok $SSE100, '<', $SSE1, 'Training Improved Things: SSE(100) < SSE(1)';
