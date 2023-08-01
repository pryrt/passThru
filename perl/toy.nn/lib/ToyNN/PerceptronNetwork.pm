package ToyNN::PerceptronNetwork;
use 5.014; # //, strict, say, s///r
use warnings;
use PDL;
use ToyNN::PerceptronLayer;

our $VERSION = '0.001'; # auto-populated from Makefile.PL

=pod

=encoding utf8

=head1 NAME

ToyNN::PerceptronNetwork - a multi-layer network of Perceptron neurons

=head1 SYNPOSIS

    # normally used instead through PerceptronNetwork object instead
    my $network = ToyNN::PerceptronNetwork::->new($nIn, $nHidden, ..., $nHiddenN, $nOut);

=head1 DESCRIPTION

Uses PDL ndarrays (or "piddles" as they used to be called) for propagating
and backpropagating data through one or more layer of Perceptron neurons.

=head1 METHODS

=head2 new

    my $network = ToyNN::PerceptronLayer::->new($nIn, $nOut); # 1 output layer
    my $network = ToyNN::PerceptronLayer::->new($nIn, $nHidden, $nOut); # 1 hidden layer, 1 output layer
    my $network = ToyNN::PerceptronLayer::->new($nIn, $nHidden, ..., $nHiddenN, $nOut); # N hidden layer, 1 output layer

Define the number of inputs to the network and the number of outputs for each of the 0 or more hidden layers, and the
number of outputs for the network.

=cut

sub new
{
    my ($class, $nIn, @nOutPerLayer) = @_;
    my $self = bless {
        layers => [],
    }, $class;

    for my $n (@nOutPerLayer) {
        push @{$self->{layers}}, ToyNN::PerceptronLayer::->new($nIn, $n);
        $nIn = $n; # the next layer will have the number of its inputs be the same as the number of outputs from this layer
    }

    return $self;
}

=head2 nLayers

    print $network->nLayers();  # similar to scalar(@array)

Returns number of layers in the network

=cut

sub nLayers
{
    my ($self) = @_;
    return scalar @{ $self->{layers}};
}

=head2 lastLayerIndex

    print $network->lastLayerIndex();  # similar to $#array

Returns the index of the last layers in the network.

=cut

sub lastLayerIndex
{
    my ($self) = @_;
    return $self->nLayers - 1;
}

=head2 L

    for my $i ( 0 .. $network->lastLayerIndex ) {
        my $layer = $network->L($i);
        ...
    }

Easily access a single layer.

=cut

sub L
{
    my ($self, $lNum) = @_;
    return $self->{layers}[$lNum];
}

=head2 feedforward

    my $Q = $network->feedforward($X);

Activates the each layer of the network in sequence, including performing the
weighted sum, adding biases, and passing through the activation function for each layer.

=cut

sub feedforward
{
    my ($self, $X) = @_;

    my $Y;
    for my $layer (@{ $self->{layers} }) {
        $Y = $layer->feedforward($X);
        $X = $Y; # the next layer will have its inputs be the outputs from this layer
    }
    return $Y;
}

=head2 backpropagate

    $Q = $network->feedforward($X);
    $layer->backpropagate($X, $TARGET);

Uses gradient descent to backpropagate the output error C<$E> through
all the layers in the network, to calculate and apply the changes in each
layer's weights and biases.

=cut



sub backpropagate
{
    my ($self, $initial_inputs, $final_target) = @_;

    # need all the intermediate outputs, not just the final outputs, so don't just use feedforward
    my @prop = ();
    my $X_l = $initial_inputs;
    for my $l ( 0 .. $#{ $self->{layers} }) {
        my $layer = $self->{layers}[$l];
        $prop[$l]{X} = $X_l;
        $prop[$l]{Y} = $layer->feedforward( $X_l );
        $X_l = $prop[0]{Y};  # this output is next input (if there is a next time)
    }

    # now backpropagate through all the layers
    my $E = $final_target - $prop[-1]{Y};
    for my $l ( reverse 0 .. $#{ $self->{layers} }) {
        my $layer = $self->{layers}[$l];
        $prop[$l]{E} = $E;
        ##### print STDERR "layer#$l: X, Y, E => ", @{$prop[$l]}{qw/X Y E/};
        ##### print STDERR "layer#$l: W,B before backprop => ", $layer->W, $layer->B;
        $layer->backpropagate( @{$prop[$l]}{qw/X E/} );
        ##### print STDERR "layer#$l: W,B after  backprop => ", $layer->W, $layer->B;

        # see "Calculate the hidden layer errors"
        #   E_h = W_ho^T x E_o
        my $Whot = $layer->W()->transpose();
        my $Eh = $Whot x $E;
        ##### print STDERR "layer#$l: W_ho^T , E_h => ", $Whot, $Eh;
        # DECISION: do I need to handle biases here?  No, I don't think so: the Coding Train didn't,

        $E = $Eh;   # the error at the input of this layer will be the error at the output of the previous layer (if there is a previous layer)
    }
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

__JS__
  train(input_array, target_array) {                                          | ### MY NOTES ###
    // Generating the Hidden Outputs                                          | This section is the feedforward loop
    let inputs = Matrix.fromArray(input_array);                               | {
    let hidden = Matrix.multiply(this.weights_ih, inputs);                    |     :
    hidden.add(this.bias_h);                                                  |     :
    // activation function!                                                   |     :
    hidden.map(sigmoid);                                                      |     :
                                                                              |     :
    // Generating the output's output!                                        |     :
    let outputs = Matrix.multiply(this.weights_ho, hidden);                   |     :
    outputs.add(this.bias_o);                                                 |     :
    outputs.map(sigmoid);                                                     | }
                                                                              |
    // Convert array to matrix object                                         | This is the final error
    let targets = Matrix.fromArray(target_array);                             | {
                                                                              |     :
    // Calculate the error                                                    |     :
    // ERROR = TARGETS - OUTPUTS                                              |     :
    let output_errors = Matrix.subtract(targets, outputs);                    | }
                                                                              |
    // let gradient = outputs * (1 - outputs);                                | This is backprop thru the output layer
    // Calculate gradient                                                     | {
    let gradients = Matrix.map(outputs, dsigmoid);                            |     :
    gradients.multiply(output_errors);                                        |     :
    gradients.multiply(this.learning_rate);                                   |     :
                                                                              |     :
                                                                              |     :
    // Calculate deltas                                                       |     :
    let hidden_T = Matrix.transpose(hidden);                                  |     :
    let weight_ho_deltas = Matrix.multiply(gradients, hidden_T);              |     :
                                                                              |     :
    // Adjust the weights by deltas                                           |     :
    this.weights_ho.add(weight_ho_deltas);                                    |     :
    // Adjust the bias by its deltas (which is just the gradients)            |     :
    this.bias_o.add(gradients);                                               | }
                                                                              |
    // Calculate the hidden layer errors                                      | This calculates the error at the output of the hidden layer
    let who_t = Matrix.transpose(this.weights_ho);                            | {
    let hidden_errors = Matrix.multiply(who_t, output_errors);                | }
                                                                              |
    // Calculate hidden gradient                                              | This is backprop thru the hidden layer
    let hidden_gradient = Matrix.map(hidden, dsigmoid);                       | {
    hidden_gradient.multiply(hidden_errors);                                  |     :
    hidden_gradient.multiply(this.learning_rate);                             |     :
                                                                              |     :
    // Calcuate input->hidden deltas                                          |     :
    let inputs_T = Matrix.transpose(inputs);                                  |     :
    let weight_ih_deltas = Matrix.multiply(hidden_gradient, inputs_T);        |     :
                                                                              |     :
    this.weights_ih.add(weight_ih_deltas);                                    |     :
    // Adjust the bias by its deltas (which is just the gradients)            |     :
    this.bias_h.add(hidden_gradient);                                         | }
                                                                              |
    // outputs.print();                                                       |
    // targets.print();                                                       |
    // error.print();                                                         |
  }                                                                           |
