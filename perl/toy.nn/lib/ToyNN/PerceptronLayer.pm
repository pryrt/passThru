package ToyNN::PerceptronLayer;
use 5.014; # //, strict, say, s///r
use warnings;
use PDL;

our $VERSION = '0.001'; # auto-populated from Makefile.PL

=pod

=encoding utf8

=head1 NAME

ToyNN::PerceptronLayer - a single layer of Perceptron neurons

=head1 SYNPOSIS

    # standalone layer
    my $layer = ToyNN::PerceptronLayer::->new($nIn, $Out);

    # normally used instead through PerceptronNetwork object instead

=head1 DESCRIPTION

Uses PDL ndarrays (or "piddles" as they used to be called) for propagating
and backpropagating data through a layer of Perceptron neurons.

=head1 METHODS

=cut

my $this;
thread_define('this_fn(a();[o]b())',  over { $_[1] .= $this->fn($_[0]) });
thread_define('this_df(a();[o]b())',  over { $_[1] .= $this->df($_[0]) });
sub _prepare_broadcast { $this = $_[0] }

=head2 new

    my $layer = ToyNN::PerceptronLayer::->new($nIn, $Out);

Define the number of inputs and outputs

=cut

sub new
{
    my ($class, $nIn, $nOut) = @_;

    my $self = bless {
        n => $nOut,
        W => ones($nIn, $nOut),      #random($nIn, $nOut),           # one column per input, one row per output
        B => ones($nOut)->transpose, #random($nOut)->transpose(),    # one column, one row per output
        fn => \&actv_sig,
        df => \&dactv_sig,
        lr => 0.01, # learning_rate
    }, $class;

    return $self;
}


=head2 weights

=head2 W

=head2 biases

=head2 B

    print $layer->weights;
    print $layer->biases;

Returns the weights and bias ndarrays for this layer.

=head2 fn

=head2 df

    my $activated = $layer->fn($sum);
    my $gradient = $layer->df($sum);

Runs the activation function and activation slope function on a given C<$sum>
(or on any other ndarray).

=head2 lr

=head2 set_learning_rate

    my $current_learning_rate = $layer->lr();
    $layer->set_learning_rate($new_learning_rate);

Retrieve or set the layer's learning rate

=cut

sub W { $_[0]->{W} };
sub weights { $_[0]->{W} };
sub B { $_[0]->{B} };
sub biases  { $_[0]->{B} };
sub fn { $_[0]->{fn}->($_[1]) }
sub df { $_[0]->{df}->($_[1]) }
sub lr { $_[0]->{lr} }
sub set_learning_rate { $_[0]->{lr} = $_[1]; }

=head2 feedforward

    my $Q = $layer->feedforward($X);

Activates the layer on a given set of inputs, including performing the
weighted sum, adding biases, and passing through the activation function.

It performs the matrix equation:

    Q = fn( W * X + B )

In that equation, C<W> is the weight matrix, C<*> is the matrix multiplication operator,
C<X> is the input matrix (each column is one set of inputs, so you can calculate
a whole epoch with a single call to C<feedforward>), C<B> is the bias column matrix,
C<fn> is the activation function, and C<Q> is the output matrix.

=cut

sub feedforward
{
    my ($self, $inputs) = @_;
    my $sums = $self->W x $inputs  + $self->B;
    $self->_prepare_broadcast;
    my $out = PDL->null; # using a thread_define function requires passing in a null matrix to hold the output
    this_fn($sums, $out);
    return $out;
}

=head2 backpropagate

    $Q = $layer->feedforward($X);
    $E = $TARGET - $Q;
    $layer->backpropagate($X, $Q, $E);

Uses gradient descent to backpropagate the output error C<$E> through
the layer to calculate and apply the change in weights.

=cut

sub backpropagate
{
    my ($self, $inputs, $outputs, $errors, $DEBUG) = @_;
    my $gradients = PDL->null;          # using a thread_define function requires passing in a null matrix to hold the output
    $DEBUG and print "backprop:inputs => ", $inputs;
    my $sum = $self->W x $inputs + $self->B;
    $DEBUG and print "backprop:sum    => ", $sum;
    this_df($sum, $gradients);       # Coding train used dactv_sig(outputs) because they did d(s(x)) = s(x)*(1-s(x)), so they passed in the known outputs
    $DEBUG and print "gradient => ", $gradients;
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

=head2 iSSE

=head2 oSSE

=head2 eSSE

    $iSSE = $layer->iSSE($X, $TARGET);

    $Q = $layer->feedforward($X);
    $oSSE = $layer->oSSE($Q, $TARGET);

    $E = $TARGET - $Q;
    $eSSE = $layer->eSSE($E);

Three methods to calculate the SSE (sum-squared error), which is the "quality" score for
a layer.  C<iSSE> is based on inputs and target; C<oSSE> is based on precomputed outputs and
target; C<eSSE> is based on precomputed output error.  All three are equivalent.

=cut

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

=head2 set_activation

    $layer->set_activation('tanh');
    $layer->set_activation('sigmoid');

Sets the activation functions to either the default 'sigmoid' or the alternate 'tanh',
and the activation-slope function to the derivative of each.

    $layer->set_activation(\&fn, \&df);

Sets the activation function and slope-function to any functions you define.  Each
needs to accept an ndarray where each column is a set of weighted sums, each with
one row for each neuron in the layer.

=cut

sub set_activation
{
    my ($self, $act, $dact) = @_;
    my $usg = <<~'EOD';
        set_activation usage:
            $layer->set_activation($string);            # arg must be in qw/sigmoid tanh/
          or
            $layer->set_activation(\&fn, \&df)          # args must be coderefs
        EOD
    if(!defined $act) {
        die $usg;
    }
    if("$act" eq 'sigmoid') {
        $self->{fn} = \&actv_sig;
        $self->{df} = \&dactv_sig;
        return 1;
    }
    if("$act" eq 'tanh') {
        $self->{fn} = \&actv_tanh;
        $self->{df} = \&dactv_tanh;
        return 2;
    }
    if((ref($act)eq'CODE') && (ref($dact//{})eq'CODE')) {
        $self->{fn} = $act;
        $self->{df} = $dact;
        return -1;
    }
    die $usg;
}

=head2 activation functions

=head3 actv_sig

=head3 dactv_sig

Sigmoid activation and slope (gradient).  Takes inputs from negative infinity to infinity
and outputs values from 0 to 1.

    sigmoid(x) = 1 / (1 + exp(-x))
    dsigmoid(x) = sigmoid(x) * (1 - sigmoid(x))

=cut

sub actv_sig($)
{
    my ($sum) = @_;
    #print "actv_sig($sum) = ", 1 / (1 + exp(-$sum)), "\n";
    return 1 / (1 + exp(-$sum));
}

sub dactv_sig($)
{
    my ($sum) = @_;
    my $s = actv_sig($sum);
    #print "dactv_sig($sum) = $s(1-$s) = ", $s*(1-$s), "\n";
    return $s * (1 - $s);
}


=head3 actv_tanh

=head3 dactv_tanh

tanh activation and slope (gradient) use the hyperbolic tangent function and its derivative.
Takes inputs from negative infinity to infinity and outputs values from -1 to 1.

    tanh(x) = (exp(2x)-1) / (exp(2x)+1)
    dtanh(x) = 1-(tanh(x)**2)

=cut


sub actv_tanh($)
{
    my ($sum) = @_;
    my $e2x = exp(2*$sum);
    return ($e2x-1)/($e2x+1);
}

sub dactv_tanh($)
{
    my ($sum) = @_;
    my $t = tanh($sum);
    return 1-$t*$t;
}

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

=head1 COPYRIGHT

Copyright (C) 2023 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;

__END__
Reference: https://github.com/CodingTrain/Toy-Neural-Network-JS/blob/5c1e9f46bdb125aff84cfe703664a474f319d320/nn.js

TODO:
_ I really want to just use a PDL-ly way of automatically extending the input of any layer to have a row of 1s,
    and to have an extra column in the weights, so that I don't have to handle each separately
    ... look into "dummy" or maybe "append" or "glue"
_ Add method ->setActivationFunction to allow it to change the activation function and derivative
