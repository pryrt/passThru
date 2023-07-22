package ToyNN::PerceptronLayer 0.001;
use 5.014; # //, strict, say, s///r
use warnings;
use PDL;

my $this;
thread_define('this_fn(a();[o]b())',  over { $_[1] .= $this->fn($_[0]) });
thread_define('this_df(a();[o]b())',  over { $_[1] .= $this->df($_[0]) });
sub prepare_broadcast { $this = $_[0] }

sub new
{
    my ($class, $nIn, $nOut) = @_;

    my $self = bless {
        n => $nOut,
        W => sequence($nIn, $nOut)/10,      #random($nIn, $nOut),           # one column per input, one row per output
        B => sequence($nOut)->transpose/10, #random($nOut)->transpose(),    # one column, one row per output
        fn => \&sigmoid,
        df => \&dsigmoid,
        lr => 0.01, # learning_rate
    }, $class;

    return $self;
}

sub W { $_[0]->{W} }; sub weights { $_[0]->{W} };
sub B { $_[0]->{B} }; sub biases  { $_[0]->{B} };
sub fn { $_[0]->{fn}->($_[1]) }
sub df { $_[0]->{df}->($_[1]) }
sub lr { $_[0]->{lr} }
sub set_learning_rate { $_[0]->{lr} = $_[1]; }

sub feedforward
{
    my ($self, $inputs) = @_;
    my $sums = $self->W x $inputs  + $self->B;
    $self->prepare_broadcast;
    my $out = PDL->null; # using a thread_define function requires passing in a null matrix to hold the output
    this_fn($sums, $out);
    return $out;
}

sub backpropagate
{
    my ($self, $inputs, $outputs, $errors) = @_;
    print "backprop:errors => ", $errors;
    my $gradients = PDL->null;          # using a thread_define function requires passing in a null matrix to hold the output
    this_df($inputs, $gradients);       # Coding train used dsigmoid(outputs) because they did d(s(x)) = s(x)*(1-s(x)), so they passed in the known outputs
    print "gradients => ", $gradients;
    $gradients *= $inputs;
    print "element-multiplied by inputs => ", $gradients;
    $gradients *= $self->lr();
    print "scaled by learning rate => ", $gradients;

    my $in_t = $inputs->transpose();
    print "input transposed => ", $in_t;

    my $dw = $gradients x $in_t;
    print "weight change => ", $dw;

    # adjust the weights
    $self->{W} += $dw;
    print "updated weights => ", $self->W;

    # the bias uses the same gradients, but since the "input" to the bias is all 1,
    $self->{B} += $gradients;
    print "updated biases => ", $self->B;

}

sub sigmoid($)
{
    my ($x) = @_;
    return 1 / (1 + exp(-$x));
}

sub dsigmoid($)
{
    my ($x) = @_;
    my $s = sigmoid($x);
    return $s * (1 - $s);
}



1;

__END__
Reference: https://github.com/CodingTrain/Toy-Neural-Network-JS/blob/5c1e9f46bdb125aff84cfe703664a474f319d320/nn.js

inp =
[ 1 ]
[ 2 ]
[ 3 ]

w =
[ 4 5 6 ]
[ 7 8 9 ]
[ 3 2 1 ]
[ 1 0 1 ]

out =
[ 32 ]
[ 50 ]
[ 10 ]
[  4 ]

target =
[ 40 ]
[ 45 ]
[ 20 ]
[  0 ]

err =
[ +8 ]
[ -5 ]
[ 10 ]
[ -4 ]

grad =
[ slope(32) ]   [ +8 ]       = [ +0.8 ]
[ slope(50) ]   [ -5 ]       = [ -0.5 ]
[ slope(10) ]   [ 10 ]       = [ +1.0 ]
[ slope( 4) ] * [ -4 ] * lr  = [ -0.4 ]

It must be elementwise-product, not matrix product, given the dimensions.. and that makes sense
the change in output for a given weight

f(x) = sigmoid(x*w+b)
df/dw = d(sigmoid)/d(arg) * d(arg)/d(w) by the chain rule
    arg = xw+b, so darg/dw = x
    d(sigmoid)/darg = sigmoid(arg)*(1-sigmoid(arg)) # property of hte sigmoid function

though it's a bit confusing to me why Coding Train calculated it as dsigmoid(output) instead of dsigmoid(input)
I may have to try both, and see which trains better

anyway,
hidden_T = inp->transpose = [ 1 2 3 ]
dw = grad x hidden_T

    [ +0.8 ] x  [ 1 2 3]  = [ +0.8 +1.6 +2.4 ]
    [ -0.5 ] x            = [ -0.5 -1.0 -1.5 ]
    [ +1.0 ] x            = [ +1.0 +2.0 +3.0 ]
    [ -0.4 ] x            = [ -0.4 -0.8 -1.2 ]

And yes, that's the right dimension for adjusting the weights

    // Calculate the error
    // ERROR = TARGETS - OUTPUTS
    let output_errors = Matrix.subtract(targets, outputs);

    // let gradient = outputs * (1 - outputs);
    // Calculate gradient
    let gradients = Matrix.map(outputs, dsigmoid);
        # pryrt: I was confused why Coding train said it this way... but
        #        I forgot that they wrote the dsigmoid to calculate the
        #        dsigmoid(s) = s * (1-s), so they are passing in
        #        the values of s(x) = sigmoid(wx+b)
    gradients.multiply(output_errors);
    gradients.multiply(this.learning_rate);


    // Calculate deltas
    let hidden_T = Matrix.transpose(hidden);
    let weight_ho_deltas = Matrix.multiply(gradients, hidden_T);

    // Adjust the weights by deltas
    this.weights_ho.add(weight_ho_deltas);
    // Adjust the bias by its deltas (which is just the gradients)
    this.bias_o.add(gradients);
