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
    }, $class;

    return $self;
}

sub W { $_[0]->{W} }; sub weights { $_[0]->{W} };
sub B { $_[0]->{B} }; sub biases  { $_[0]->{B} };
sub fn { $_[0]->{fn}->($_[1]) }
sub df { $_[0]->{df}->($_[1]) }

sub feedforward
{
    my ($self, $inputs) = @_;
    my $sums = $self->W x $inputs  + $self->B;
    $self->prepare_broadcast;
    my $out = PDL->null;
    this_fn($sums, $out);
    return $out;
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
