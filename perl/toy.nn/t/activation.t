use 5.014; # //, strict, say, s///r
use warnings;
use PDL;
use ToyNN::PerceptronLayer;
use Test::More tests => 16;
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

# sigmoid:  s = 1/(1 + exp(-x))
# dsigmoid: ds = s*(1-s)
is_float_close_enough ToyNN::PerceptronLayer::sigmoid(0),           0.500000, 'Activation: sigmoid(0)';
is_float_close_enough ToyNN::PerceptronLayer::dsigmoid(0),          0.250000, 'Activation Slope: dsigmoid(0)';
is_float_close_enough ToyNN::PerceptronLayer::sigmoid(-log(3)),     0.250000, 'Activation: sigmoid(-log(3))';
is_float_close_enough ToyNN::PerceptronLayer::dsigmoid(-log(3)),    0.187500, 'Activation Slope: dsigmoid(-log(3))';
is_float_close_enough ToyNN::PerceptronLayer::sigmoid(log(3)),      0.750000, 'Activation: sigmoid(log(3))';
is_float_close_enough ToyNN::PerceptronLayer::dsigmoid(log(3)),     0.187500, 'Activation Slope: dsigmoid(log(3))';
is_float_close_enough ToyNN::PerceptronLayer::sigmoid(-log(15)),    0.062500, 'Activation: sigmoid(-log(3))';
is_float_close_enough ToyNN::PerceptronLayer::dsigmoid(-log(15)),   0.05859375, 'Activation Slope: dsigmoid(-log(15))';
is_float_close_enough ToyNN::PerceptronLayer::sigmoid(log(15)),     0.937500, 'Activation: sigmoid(log(3))';
is_float_close_enough ToyNN::PerceptronLayer::dsigmoid(log(15)),    0.05859375, 'Activation Slope: dsigmoid(log(15))';

# tanh:     t = (exp(2x)-1)/(exp(2x)+1)
# dtanh:    dt = 1 - dt*dt
is_float_close_enough ToyNN::PerceptronLayer::actv_tanh(0),         0.000000, 'Activation: actv_tanh(0)';
is_float_close_enough ToyNN::PerceptronLayer::dactv_tanh(0),        1.000000, 'Activation Slope: dactv_tanh(0)';
is_float_close_enough ToyNN::PerceptronLayer::actv_tanh(log(2)),    0.600000, 'Activation: actv_tanh(log(2))';
is_float_close_enough ToyNN::PerceptronLayer::dactv_tanh(log(2)),   0.640000, 'Activation Slope: dactv_tanh(log(2))';
is_float_close_enough ToyNN::PerceptronLayer::actv_tanh(-log(2)),  -0.600000, 'Activation: actv_tanh(-log(2))';
is_float_close_enough ToyNN::PerceptronLayer::dactv_tanh(-log(2)),  0.640000, 'Activation Slope: dactv_tanh(-log(2))';
