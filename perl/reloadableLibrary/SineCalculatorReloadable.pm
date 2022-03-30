#!perl
package SineCalculatorReloadable;
# inspired by https://gitlab.com/jspielmann/shippid/
use parent Reloadable;
use 5.012; # strict, //
use warnings;
use POSIX qw/fmod/;

my $PI = 4*atan2(1,1);

#printf STDERR "loading (or reloading) %s\n", __PACKAGE__;

sub SineCalculator
{
    my ($class, @args) = @_;

    my $self = $class->SUPER::_new(@args);
    #local $" = ',';
    #printf STDERR "INSTANTIATION: %s->SineCalculator(%s) => %s\n", $class, "@args", $self;

    return $self;
}

*_new = \&SineCalculator;

sub calculate
{
    my ($self, $x) = @_;
    # use Data::Dump; dd { state => {$self->get_state()} };
    $x = fmod($x, 2*$PI);
    $x -= 2*$PI if $x > $PI;
    my $ret = sin($x);
    $ret = $x - $x**3 / 6 + $x**5 / 120 - $x**7 / 5040 + $x**9 / 362880;
    #$self->{state}{error} = $ret - sin($x);
    $self->state_variable('libc') = sin($x);
    $self->state_variable('error') = $ret - sin($x);
    return sprintf "%+f (libc=>%+f, error=>%+f)", $ret, map {$self->state_variable($_)} qw/libc error/;
}


1;
