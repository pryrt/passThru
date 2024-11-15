#!perl
# Trying to calculate the perimeter (or, actually, quarter perimeter) of a superellipse
#   Ellipses and superellipses
#       x(t) = a*|cos(t)|**(2/n)*sgn(cos(t))
#       y(t) = b*|sin(t)|**(2/n)*sgn(sin(t))
#       where t is the parameter, but is only the angle Θ when a=b=r and n=2
#   n=1 ⇒ rhombus
#   n=2 ⇒ standard ellipse
#   n=4 ⇒ original squircle -- geometric mean between square and circle

use 5.014; # strict, //, s//r
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use POSIX qw/M_PI M_PI_2 M_PI_4 M_SQRT2 M_SQRT1_2/;

=head3 superellipse_point

returns the (x,y) for the superellipse with parameters a,b,n, evaluated at t

=cut
sub superellipse_point
{
    my ($t, $a, $b, $n) = @_;
    die "not implemented yet" unless $n == 2;   # right now, stick with normal ellipse only

    # for normal ellipse:
    my $x = $a * cos($t);
    my $y = $b * sin($t);
    return ($x,$y);
}

=head3 superellipse_grad

returns the gradient (dx,dy) for the superellipse with parameters a,b,n, evaluated at t

=cut
sub superellipse_grad
{
    my ($t, $a, $b, $n) = @_;
    die "not implemented yet" unless $n == 2;   # right now, stick with normal ellipse only

    # for normal ellipse:
    my $dx = $a * -sin($t);
    my $dy = $b * cos($t);
    return ($dx,$dy);
}

=head3 superellipse_quarter_perim

Tries to approximate the quarter-perimeter for the superellipse

=cut
sub superellipse_quarter_perim
{
    my ($a, $b, $n) = @_;
    die "not implemented yet" unless $n == 2;   # right now, stick with normal ellipse only
    die "not implemented yet" unless $a == $b;  # right now, stick with circle only

    if($a==$b) {
        return $a*M_PI_4;
    }
}

use Test2::Bundle::More;
use Test2::Tools::Compare qw/is float/;        # to use float, either use the ::Bundle::More::is_deeply($got, float(...)) or the ::Tools::Compare::is($got, float(...))
#       precision=>#digits or tolerance=>absolute+/-value; default with neither specified is tolerance=>1e-08
#   is_deeply(3.14, float(4*atan2(1,1), precision => 2), 'pi');
#   is(3.14, float(4*atan2(1,1), precision => 2), 'pi');  # only with Test2::Tools::Compare::is(...)

subtest "SE[1,1,2]" => sub {
    my($x,$y) = superellipse_point(M_PI_4, 1, 1, 2);
    is($x, float(M_SQRT1_2), 'x(π/4)');
    is($y, float(M_SQRT1_2), 'y(π/4)');
    my($dx,$dy) = superellipse_grad(M_PI_4, 1, 1, 2);
    is($dx, float(-M_SQRT1_2), 'dx(π/4)');
    is($dy, float(M_SQRT1_2), 'dy(π/4)');
};

subtest "SE[3,2,2]" => sub {
    my($x,$y) = superellipse_point(M_PI/6, 3, 2, 2);
    is($x, float(3*sqrt(0.75)), 'x(π/6)');
    is($y, float(2*sqrt(0.25)), 'y(π/6)');
    my($dx,$dy) = superellipse_grad(M_PI/6, 3, 2, 2);
    is($dx, float(-3*sqrt(0.25)), 'dx(π/6)');
    is($dy, float(+2*sqrt(0.75)), 'dy(π/6)');
};

subtest "SE[5,5,2]" => sub {
    my $qp = superellipse_quarter_perim(5,5,2);
    is($qp, float(5*M_PI_4), 'quarter perim');
};

done_testing();
