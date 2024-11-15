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

=head3 unit

returns unit vector

=cut

sub unit
{
    my ($x,$y) = @_;
    my $m = sqrt($x**2+$y**2);
    $_ /= $m for $x,$y;
    return ($x,$y);
}

=head3 superellipse_point

returns the (x,y) for the superellipse with parameters a,b,n, evaluated at t

=cut
sub superellipse_point
{
    my ($t, $a, $b, $n) = @_;
    die "meaningless ellipse" if !$a or !$b or !$n;
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
    die "meaningless ellipse" if !$a or !$b or !$n;
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
    my ($a, $b, $n, $imax) = @_;
    die "meaningless ellipse" if !$a or !$b or !$n;
    die "not implemented yet" unless $n == 2;   # right now, stick with normal ellipse only
    $imax ||= 100;

    if($n==2 and $a==$b) {
        return $a*M_PI_2, $b*M_PI_2;
    }

    # the low estimation is the inner polygon, with imax segments
    # the big estimation is the outer polygon, with imax+1 segments
    my $inner = 0;
    my $outer = 0;
    #printf STDERR "perim(%d,%d,%d,%d):\n", $a, $b, $n, $imax;
    for my $i (1 .. $imax) {
        # for the inner, I just need the coordinates of the previous point and ith point, and compute distance between
        my ($t0,$t1) = map {M_PI_2 / $imax * $_} $i-1,$i;
        my ($x0,$y0) = superellipse_point($t0, $a, $b, $n);
        my ($x1,$y1) = superellipse_point($t1, $a, $b, $n);
        $inner += sqrt(($x1-$x0)**2 + ($y1-$y0)**2);

        # for the outer, I need to compute the intersection of P0+G0*u = P1-G1*v (for point vector P# and grad vector G#)
        my ($dx0,$dy0) = unit(superellipse_grad($t0, $a, $b, $n));
        my ($dx1,$dy1) = unit(superellipse_grad($t1, $a, $b, $n));
        # x0+dx0*u = x1-dx1*v   =>   [ dx0 dx1 | x1-x0 ]    =>  [ A B C ]
        # y0+dy0*u = y1-dy1*v   =>   [ dy0 dy1 | y1-y0 ]    =>  [ D E F ]
        my ($A,$B,$C,$D,$E,$F,$isSwapped) = $dx0 ?
            ( $dx0, $dx1, $x1-$x0, $dy0, $dy1, $y1-$y0, 0 ) :
            $dy0 ?
            ( $dy0, $dy1, $y1-$y0, $dx0, $dx1, $x1-$x0, 1 ) :
            die "point(0) has gradient=(0,0)";

        #printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", $isSwapped?"swpd":"orig",$A,$B,$C,$D,$E,$F;
        # normalize row1 by A
        my $tmp = $A;
        $_ /= $tmp for $A,$B,$C;
        #printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", "nrm1",$A,$B,$C,$D,$E,$F;
        # zero out first column of row2
        $tmp = $D;
        $D -= $tmp*$A;
        $E -= $tmp*$B;
        $F -= $tmp*$C;
        #printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", "zro1",$A,$B,$C,$D,$E,$F;
        # normalize row2 by E
        die "divide by 0" if !$E;
        $tmp = $E;
        $_ /= $tmp for $D, $E, $F;
        #printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", "nrm2",$A,$B,$C,$D,$E,$F;
        # zero out second column of row1
        $tmp = $B;
        $A -= $tmp*$D;
        $B -= $tmp*$E;
        $C -= $tmp*$F;
        #printf STDERR "\n\tslvd:[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", $A,$B,$C,$D,$E,$F;

        # doesn't matter whether swapped or not, the u value will always end up in C, and the v value in F
        my $xc = $x0 + $C*$dx0;
        my $yc = $y0 + $C*$dy0;

        # now do distance from 0 to C and C to 1
        $outer += sqrt(($xc-$x0)**2 + ($yc-$y0)**2);
        $outer += sqrt(($xc-$x1)**2 + ($yc-$y1)**2);

        # full debug output
        #printf STDERR "* %d: %+06.3f:(%+06.3f,%+06.3f) %.3f:(%+06.3f,%+06.3f) => inner:%+06.3f", $i, $t0, $x0, $y0, $t1, $x1, $y1, $inner;
        #printf STDERR "\tG0:(%+06.3f,%.3f) G1:(%+06.3f,%.3f) u:%+06.3f v:%+06.3f C:(%+06.3f,%+06.3f) => outer:%.3f\n", $dx0,$dy0, $dx1,$dy1, $C,$F, $xc, $yc, $outer;

        # limited debug output
        #printf STDERR "%+06.3f\t%+06.3f\n", $x0, $y0 if $i==1;
        #printf STDERR "%+06.3f\t%+06.3f\n%+06.3f\t%+06.3f\n", $xc, $yc, $x1, $y1;

    }
    return ($inner,$outer);
}

use Test2::Bundle::More;
use Test2::Tools::Compare qw/is float/;        # to use float, either use the ::Bundle::More::is_deeply($got, float(...)) or the ::Tools::Compare::is($got, float(...))
#       precision=>#digits or tolerance=>absolute+/-value; default with neither specified is tolerance=>1e-08
#   is_deeply(3.14, float(4*atan2(1,1), precision => 2), 'pi');
#   is(3.14, float(4*atan2(1,1), precision => 2), 'pi');  # only with Test2::Tools::Compare::is(...)

subtest "SE[5,5,2]" => sub {
    my($x,$y) = superellipse_point(M_PI_4, 5, 5, 2);
    is($x, float(5*M_SQRT1_2), 'x(π/4)');
    is($y, float(5*M_SQRT1_2), 'y(π/4)');
    my($dx,$dy) = superellipse_grad(M_PI_4, 5, 5, 2);
    is($dx, float(-5*M_SQRT1_2), 'dx(π/4)');
    is($dy, float(5*M_SQRT1_2), 'dy(π/4)');
    my ($qpi,$qpo) = superellipse_quarter_perim(5,5,2);
    is($qpi, float(5*M_PI_2, tolerance=>1e-4), 'quarter perim');
};

subtest "SE[3,2,2]" => sub {
    my($x,$y) = superellipse_point(M_PI/6, 3, 2, 2);
    is($x, float(3*sqrt(0.75)), 'x(π/6)');
    is($y, float(2*sqrt(0.25)), 'y(π/6)');
    my($dx,$dy) = superellipse_grad(M_PI/6, 3, 2, 2);
    is($dx, float(-3*sqrt(0.25)), 'dx(π/6)');
    is($dy, float(+2*sqrt(0.75)), 'dy(π/6)');
    my ($qpi,$qpo) = superellipse_quarter_perim(3,2,2,1);
    is($qpi, float(sqrt(3**2+2**2)), '[tmp] inner quarter perim with imax=1 (diagonal from <3,0> to <0,2>)');
    is($qpo, float(2+3), '[tmp] outer quarter perim with imax=1 (up 2 from <3,0> to <3,2>; over 3 to <0,2>)');
    ($qpi,$qpo) = superellipse_quarter_perim(3,2,2);
    is($qpi, float(3.9664, tolerance=>1e-4), '[tmp] inner quarter perim with imax=default(100)');
    is($qpo, float(3.9664, tolerance=>1e-4), '[tmp] outer quarter perim with imax=default(100)');
    is($qpo, float($qpi  , tolerance=>2e-4), '[tmp] inner and outer quarter perim equivalent with imax=default(100)');
};

done_testing();
