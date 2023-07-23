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
        W => ones($nIn, $nOut),      #random($nIn, $nOut),           # one column per input, one row per output
        B => ones($nOut)->transpose, #random($nOut)->transpose(),    # one column, one row per output
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
    my $DEBUG = 0;
    my $gradients = PDL->null;          # using a thread_define function requires passing in a null matrix to hold the output
    $DEBUG and print "backprop:inputs => ", $inputs;
    my $sum = $self->W x $inputs + $self->B;
    $DEBUG and print "backprop:sum    => ", $sum;
    this_df($sum, $gradients);       # Coding train used dsigmoid(outputs) because they did d(s(x)) = s(x)*(1-s(x)), so they passed in the known outputs
    $DEBUG and print "dsigmoid => ", $gradients;
    $DEBUG and print "backprop:errors => ", $errors;
    $gradients *= $errors;
    $DEBUG and print "element-multiplied by errors => ", $gradients;
    $gradients *= $self->lr();
    $DEBUG and print "scaled by learning rate => ", $gradients;

    my $in_t = $inputs->transpose();
    $DEBUG and print "input transposed => ", $in_t;

    my $dw = $gradients x $in_t;
    $DEBUG and print "weight change => ", $dw;

    # adjust the weights
    $self->{W} += $dw;
    $DEBUG and print "updated weights => ", $self->W;

    # the bias uses the same gradients, but since the "input" to the bias is all 1,
    #   but I still have to sum the gradients for each row
    $DEBUG and print "gradients->sumover->T => ", $gradients->sumover()->transpose();
    $self->{B} += $gradients->sumover()->transpose();
    $DEBUG and print "updated biases => ", $self->B;

}

# there are three reasonable options for calculating Sum Squared Error,
#   depending on what you already have available/calculated
# 1) You know the errors, so you just have to square and sum
sub eSSE
{
    my ($self, $err) = @_;
    return ($err**2)->sum();
}
# 2) You know the outputs and targets, so have to compute the error,
#       then square and sum
sub oSSE
{
    my ($self, $outputs, $targets) = @_;
    return (($targets - $outputs)**2)->sum();
}
# 3) You know the input and targets, so have to compute the output,
#       then compute the error, then square and sum
sub iSSE
{
    my ($self, $inputs, $targets) = @_;
    my $outputs = $self->feedforward($inputs);
    return (($targets - $outputs)**2)->sum();
}

sub sigmoid($)
{
    my ($sum) = @_;
    #print "sigmoid($sum) = ", 1 / (1 + exp(-$sum)), "\n";
    return 1 / (1 + exp(-$sum));
}

sub dsigmoid($)
{
    my ($sum) = @_;
    my $s = sigmoid($sum);
    #print "dsigmoid($sum) = $s(1-$s) = ", $s*(1-$s), "\n";
    return $s * (1 - $s);
}



1;

__END__
Reference: https://github.com/CodingTrain/Toy-Neural-Network-JS/blob/5c1e9f46bdb125aff84cfe703664a474f319d320/nn.js

TODO:
_ I really want to just use a PDL-ly way of automatically extending the input of any layer to have a row of 1s,
    and to have an extra column in the weights, so that I don't have to handle each separately
    ... look into "dummy" or maybe "append" or "glue"
_ Add method ->setActivationFunction to allow it to change the activation function and derivative
