use 5.014; # //, strict, say, s///r
use warnings;
use PDL;
use ToyNN::PerceptronNetwork;
use Test::More tests => 43;
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
    [map {ToyNN::PerceptronLayer::actv_sig($_)} -5,5,5,-5],
];

# create a network with two layers
my $network = ToyNN::PerceptronNetwork::->new(2, 2, 1);
isa_ok $network, 'ToyNN::PerceptronNetwork', 'network';

my $nL = $network->nLayers;
is $nL, 2, 'network: #layers';
my $ll = $network->lastLayerIndex;
is $nL, 2, 'network: last layer index';

# verify biases and weights are ndarrays of the right size

# HIDDEN LAYER
my $layer = $network->L(0);
isa_ok $layer, 'ToyNN::PerceptronLayer', 'layerH';
my $ok = isa_ok $layer->W, 'PDL', 'layerH->W';
SKIP: {
    skip "cannot check dimensions if not a PDL", 3 unless $ok;
    my ($c,$r,@d) = $layer->W->dims();
    is $c, 2, "'layerH->W' has 2 cols";
    is $r, 2, "'layerH->W' has 2 rows";
    is scalar(@d), 0, "'layerH->W' has no other dimensions";
}
isa_ok $layer->B, 'PDL', 'layerH->B';
SKIP: {
    skip "cannot check dimensions if not a PDL", 3 unless $ok;
    my ($c,$r,@d) = $layer->B->dims();
    is $c, 1, "'layerH->B' has 1 col";
    is $r, 2, "'layerH->B' has 2 rows";
    is scalar(@d), 0, "'layerH->B' has no other dimensions";
}
# update the weights/biases to known values
$layer->{W} .= 1;   # set all elements to 1
is_float_close_enough $layer->W->at(0,0), 1, 'layerH: W[0,0] == 1';
is_float_close_enough $layer->W->at(0,1), 1, 'layerH: W[0,1] == 1';
is_float_close_enough $layer->W->at(1,0), 1, 'layerH: W[1,0] == 1';
is_float_close_enough $layer->W->at(1,1), 1, 'layerH: W[1,1] == 1';
$layer->{B} .= 1;   # set all elements to 1
is_float_close_enough $layer->B->at(0,0), 1, 'layerH: B[0,0] == 1';
is_float_close_enough $layer->B->at(0,1), 1, 'layerH: B[0,1] == 1';
# set and verify learning rate
$layer->set_learning_rate(1);
is_float_close_enough $layer->lr, 1, 'layerH: learning rate set to 1';

# OUTPUT LAYER
$layer = $network->L(1);
isa_ok $layer, 'ToyNN::PerceptronLayer', 'layerQ';
$ok = isa_ok $layer->W, 'PDL', 'layerQ->W';
SKIP: {
    skip "cannot check dimensions if not a PDL", 3 unless $ok;
    my ($c,$r,@d) = $layer->W->dims();
    is $c, 2, "'layerQ->W' has 2 cols";
    is $r, 1, "'layerQ->W' has 1 rows";
    is scalar(@d), 0, "'layerQ->W' has no other dimensions";
}
isa_ok $layer->B, 'PDL', 'layerQ->B';
SKIP: {
    skip "cannot check dimensions if not a PDL", 3 unless $ok;
    my ($c,$r,@d) = $layer->B->dims();
    is $c, 1, "'layerQ->B' has 1 col";
    is $r, 1, "'layerQ->B' has 1 rows";
    is scalar(@d), 0, "'layerQ->B' has no other dimensions";
}
# update the weights/biases to known values
$layer->{W}->slice(0,0) .= -2;
$layer->{W}->slice(1,0) .= +2;
is_float_close_enough $layer->W->at(0,0), -2, 'layerQ: W[0,0] == -2';
is_float_close_enough $layer->W->at(1,0), +2, 'layerQ: W[0,1] == +2';
$layer->{B} .= -1;
is_float_close_enough $layer->B->at(0,0), -1, 'layerQ: B[0,0] == -1';
# set and verify learning rate
$layer->set_learning_rate(1);
is_float_close_enough $layer->lr, 1, 'layerQ: learning rate set to 1';
undef $layer;


my ($Q,$E, $SSE1, $SSE100);
for(1..100) {
    $Q = $network->feedforward($X);
    $E = $TARGET - $Q;
    my $SSE0;
    if($_==1) {
        $SSE0 = $network->L($ll)->eSSE($E);
        is_float_close_enough $SSE0, 1.18, 0.01, 'epoch(0): initial SSE';
    }
    $network->backpropagate($X, $TARGET);
    if($_==1) {
        is_float_close_enough $Q->at(0,0), 0.269, 0.0005, 'epoch(1): Q[0,0]';
        is_float_close_enough $Q->at(1,0), 0.269, 0.0005, 'epoch(1): Q[1,0]';
        is_float_close_enough $Q->at(2,0), 0.269, 0.0005, 'epoch(1): Q[2,0]';
        is_float_close_enough $Q->at(3,0), 0.269, 0.0005, 'epoch(1): Q[3,0]';
        $Q = $network->feedforward($X);
        $E = $TARGET - $Q;
        $SSE1 = $network->L($ll)->eSSE($E);
        cmp_ok $SSE1, '<', $SSE0, 'Training Improved Things: SSE(1) < SSE(0)';
    }
}

$Q = $network->feedforward($X);
$SSE100 = $network->L($ll)->oSSE($Q, $TARGET);
is_float_close_enough $Q->at(0,0), 0.210, 0.005, 'epoch(100): Q[0,0]';
is_float_close_enough $Q->at(1,0), 0.750, 0.005, 'epoch(100): Q[1,0]';
is_float_close_enough $Q->at(2,0), 0.750, 0.005, 'epoch(100): Q[2,0]';
is_float_close_enough $Q->at(3,0), 0.330, 0.005, 'epoch(100): Q[3,0]';
cmp_ok $SSE100, '<', $SSE1, 'Training Improved Things: SSE(100) < SSE(1)';

done_testing();
