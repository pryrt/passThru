package ToyNN::PerceptronLayer 0.001;
use 5.014; # //, strict, say, s///r
use warnings;
use PDL;

sub new
{
    my ($class, $nIn, $nOut) = @_;

    my $self = bless {
        n => $nOut,
        W => random($nIn, $nOut),           # one column per input, one row per output
        B => random($nOut)->transpose(),    # one column, one row per output
    }, $class;

    return $self;
}

1;
