package Math::ScratchHAT::Qubit;
use 5.014; # strict, //, s//r
use warnings;

our $VERSION = 0.01;

sub new
{
    my ($class) = @_;
    return bless { trueAmp => 0, falseAmp => 1, observed => 0 }, $class;
}


sub _internal_value
{
    my ($self) = @_;
    # this method doesn't collapse state, because it's just used internally

    # calculate the probability that it's true: (trueAmp**2) / sumsq(trueAmp,falseAmp)
    my $p = ($self->{trueAmp} ** 2) / ($self->{trueAmp} ** 2 + $self->{falseAmp} ** 2);
    my $state = (rand() < $p);
    return $state||0;
}

sub observe
{
    my ($self) = @_;

    my $state = $self->_internal_value;

    # true observation collapses the probabilities to a known state
    $self->{trueAmp} = ($state)||0;
    $self->{falseAmp} = (!$state)||0;
    $self->{observed} = 1;

    return $state||0;
}

sub hadamardMe
{
    my ($self) = @_;
    my $sum = $self->{falseAmp} + $self->{trueAmp};
    my $dif = $self->{falseAmp} - $self->{trueAmp};
    $self->{falseAmp} = $sum;
    $self->{trueAmp} = $dif;
    return $self;
}

sub toggle
{
    my ($self) = @_;
    # I _think_ that it just swaps the true and false amplitudes, but I'm not 100% sure
    ( $self->{falseAmp}, $self->{trueAmp} ) = ( $self->{trueAmp}, $self->{falseAmp} );
    return $self;
}

1;
