use 5.014; # //, strict, say, s///r
use warnings;
use PDL;
use ToyNN::PerceptronLayer;
use Test::More tests => 29;
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

BEGIN {
    *actv_sig = \&ToyNN::PerceptronLayer::actv_sig;
    *dactv_sig = \&ToyNN::PerceptronLayer::dactv_sig;
    *actv_tanh = \&ToyNN::PerceptronLayer::actv_tanh;
    *dactv_tanh = \&ToyNN::PerceptronLayer::dactv_tanh;
}

# actv_sig:  s = 1/(1 + exp(-x))
# dactv_sig: ds = s*(1-s)
is_float_close_enough actv_sig(0),           0.50000000, 'Activation: actv_sig(0)';
is_float_close_enough dactv_sig(0),          0.25000000, 'Activation Slope: dactv_sig(0)';
is_float_close_enough actv_sig(-log(3)),     0.25000000, 'Activation: actv_sig(-log(3))';
is_float_close_enough dactv_sig(-log(3)),    0.18750000, 'Activation Slope: dactv_sig(-log(3))';
is_float_close_enough actv_sig(log(3)),      0.75000000, 'Activation: actv_sig(log(3))';
is_float_close_enough dactv_sig(log(3)),     0.18750000, 'Activation Slope: dactv_sig(log(3))';
is_float_close_enough actv_sig(-log(15)),    0.06250000, 'Activation: actv_sig(-log(3))';
is_float_close_enough dactv_sig(-log(15)),   0.05859375, 'Activation Slope: dactv_sig(-log(15))';
is_float_close_enough actv_sig(log(15)),     0.93750000, 'Activation: actv_sig(log(3))';
is_float_close_enough dactv_sig(log(15)),    0.05859375, 'Activation Slope: dactv_sig(log(15))';

# tanh:     t = (exp(2x)-1)/(exp(2x)+1)
# dtanh:    dt = 1 - dt*dt
is_float_close_enough actv_tanh(0),          0.00000000, 'Activation: actv_tanh(0)';
is_float_close_enough dactv_tanh(0),         1.00000000, 'Activation Slope: dactv_tanh(0)';
is_float_close_enough actv_tanh(log(2)),     0.60000000, 'Activation: actv_tanh(log(2))';
is_float_close_enough dactv_tanh(log(2)),    0.64000000, 'Activation Slope: dactv_tanh(log(2))';
is_float_close_enough actv_tanh(-log(2)),   -0.60000000, 'Activation: actv_tanh(-log(2))';
is_float_close_enough dactv_tanh(-log(2)),   0.64000000, 'Activation Slope: dactv_tanh(-log(2))';

# verify change in activation
my $layer = ToyNN::PerceptronLayer::->new(1,1);
is $layer->{fn}, \&actv_sig,    'Default Activation: actv_sig';
is $layer->{df}, \&dactv_sig,   'Default Activation Slope: dactv_sig';
$layer->set_activation('tanh');
is $layer->{fn}, \&actv_tanh,   'set_activation("tanh") => {fn} = actv_tanh';
is $layer->{df}, \&dactv_tanh,  'set_activation("tanh") => {df} = dactv_tanh';
$layer->set_activation('sigmoid');
is $layer->{fn}, \&actv_sig,    'set_activation("sigmoid") => {fn} = actv_sig';
is $layer->{df}, \&dactv_sig,   'set_activation("sigmoid") => {df} = dactv_sig';
my $fn = sub { 'fn' };
my $df = sub { 'df' };
$layer->set_activation($fn, $df);
is $layer->{fn}, $fn,           'set_activation(fn,df) => {fn} = \&fn';
is $layer->{df}, $df,           'set_activation(fn,df) => {df} = \&df';

# verify error handling
sub throws_like(&$;$) {
    my ($cref, $re, $name) = @_;
    my $x = 0;
    eval { $cref->(); $x = 1 };
    my $msg = $@ // '<no thrown message>';
    my $ok = ($x==0);
    $ok &= ($msg =~ $re );
    chomp($msg);
    ok $ok, $name // "check that $cref throws a message like $re"
        or diag sprintf "\tthrown?  %s\n\tmessage: %s\n\tregexp:  %s\n", ($x==0)?'yes':'no', length($msg)?$msg:'<empty string>', "$re";
}

throws_like { $layer->set_activation() } qr/\busage\b/, 'throws ok: set_activation() with no args';
throws_like { $layer->set_activation('unknown') } qr/\busage\b/, 'throws ok: set_activation("unknown") with unknown string';
throws_like { $layer->set_activation(sub{}) } qr/\busage\b/, 'throws ok: set_activation(\&fn) with only one sub';
throws_like { $layer->set_activation(sub{}, []) } qr/\busage\b/, 'throws ok: set_activation(\&fn,[]) with wrong reference args';
throws_like { $layer->set_activation([], sub{}) } qr/\busage\b/, 'throws ok: set_activation([],\&fn) with wrong arg types';
