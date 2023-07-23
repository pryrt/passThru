package ToyNN::PerceptronNetwork 0.001;
use 5.014; # //, strict, say, s///r
use warnings;
use PDL;
use ToyNN::PerceptronLayer;


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

1;
