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

our $DEBUG_P_DETL = 0;
our $DEBUG_P_LMTD = 0;
our $DEBUG_P_SOLV = 0;
our $DEBUG_GRAD = 0;

=head3 unit

returns unit vector

=cut

sub unit
{
    my ($x,$y) = @_;
    my $m = sqrt($x**2+$y**2);
    if($m==+'Inf') {
        $x = ($x==+'Inf') ? +1 : ($x==-'Inf') ? -1 : 0;
        $y = ($y==+'Inf') ? +1 : ($y==-'Inf') ? -1 : 0;
        $m=1;
    }
    if($m) {    # avoid divide-by-zero
        $_ /= $m for $x,$y;
    }

    return ($x,$y);
}

=head3 sgn

returns sign of argument

=cut

sub sgn { $_[0]<0 ? -1 : $_[0]>0 ? +1 : 0 }

=head3 superellipse_point

returns the (x,y) for the superellipse with parameters a,b,n, evaluated at t

=cut
sub superellipse_point
{
    my ($t, $a, $b, $n) = @_;
    die "meaningless ellipse" if !$a or !$b or !$n;

    my $x = $a * sgn(cos($t)) * abs(cos($t))**(2/$n);
    my $y = $b * sgn(sin($t)) * abs(sin($t))**(2/$n);

    return ($x,$y);
}

=head3 superellipse_grad

returns the gradient (dx,dy) for the superellipse with parameters a,b,n, evaluated at t

=cut
sub superellipse_grad
{
    my ($t, $a, $b, $n) = @_;
    die "meaningless ellipse" if !$a or !$b or !$n;

    my $dx = $a * (2/$n) * abs(cos($t))**(2/$n-1) * -sin($t);
    my $dy = $b * (2/$n) * abs(sin($t))**(2/$n-1) * +cos($t);

    printf STDERR "  grad(%+06.3f,%+06.3f,%+06.3f,%+06.3f) = <%+06.3f,%+06.3f>\n", $t, $a, $b, $n, $dx, $dy if $DEBUG_GRAD;
    state $depth=0;
    if(!$dx and !$dy) {
        die "superellipse_grad(): deep recursion" if $depth;
        ++$depth;
        printf STDERR "  - orig: grad(%+012.9f,%+06.3f,%+06.3f,%+06.3f) = <%+06.3f,%+06.3f>\n", $t, $a, $b, $n, $dx, $dy if $DEBUG_GRAD;
        ($dx,$dy) = superellipse_grad($t+1e-9, $a, $b, $n);
        printf STDERR "  - redo: grad(%+012.9f,%+06.3f,%+06.3f,%+06.3f) = <%+06.3f,%+06.3f>\n", $t+1e-9, $a, $b, $n, $dx, $dy if $DEBUG_GRAD;
        --$depth;
    }
    return ($dx,$dy);
}

=head3 superellipse_quarter_perim

Tries to approximate the quarter-perimeter for the superellipse

=cut
sub superellipse_quarter_perim
{
    my ($a, $b, $n, $imax) = @_;
    $imax ||= 100;
    die "meaningless ellipse" if !$a or !$b or !$n;

    # for a true circle, just use math rather than iteration
    if($n==2 and $a==$b) {
        return $a*M_PI_2, $b*M_PI_2;
    }

    # the low estimation is the inner polygon, with imax segments
    # the big estimation is the outer polygon, with imax+1 segments
    my $inner = 0;
    my $outer = 0;
    printf STDERR "perim(%d,%d,%d,%d):\n", $a, $b, $n, $imax if $DEBUG_P_DETL or $DEBUG_P_SOLV;
    for my $i (1 .. $imax) {
        # for the inner, I just need the coordinates of the previous point and ith point, and compute distance between
        my ($t0,$t1) = map {M_PI_2 / $imax * $_} $i-1,$i;
        my ($x0,$y0) = superellipse_point($t0, $a, $b, $n);
        my ($x1,$y1) = superellipse_point($t1, $a, $b, $n);
        $inner += sqrt(($x1-$x0)**2 + ($y1-$y0)**2);

        # for the outer, I need to compute the intersection of P0+G0*u = P1-G1*v (for point vector P# and grad vector G#)
        my ($dx0,$dy0) = unit(superellipse_grad($t0, $a, $b, $n));
        my ($dx1,$dy1) = unit(superellipse_grad($t1, $a, $b, $n));
        if($DEBUG_GRAD) {
            printf STDERR "\tunit(grad0): <%+06.3f,%+06.3f>\n", $dx0, $dy0;
            printf STDERR "\tunit(grad1): <%+06.3f,%+06.3f>\n", $dx1, $dy1;
        }
        # x0+dx0*u = x1-dx1*v   =>   [ dx0 dx1 | x1-x0 ]    =>  [ A B C ]
        # y0+dy0*u = y1-dy1*v   =>   [ dy0 dy1 | y1-y0 ]    =>  [ D E F ]
        my ($xc,$yc);
        my ($A,$B,$C,$D,$E,$F,$isSwapped) = $dx0 ?
            ( $dx0, $dx1, $x1-$x0, $dy0, $dy1, $y1-$y0, 0 ) :
            $dy0 ?
            ( $dy0, $dy1, $y1-$y0, $dx0, $dx1, $x1-$x0, 1 ) :
            die "point(0) has gradient=(0,0)";

        if($A==$B and $D==$E) {
            # if the grads are parallel, then just average between the two points
            $xc = ($x0+$x1) / 2;
            $yc = ($y0+$y1) / 2;
        } else {
            printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", $isSwapped?"swpd":"orig",$A,$B,$C,$D,$E,$F if $DEBUG_P_SOLV;
            # normalize row1 by A
            my $tmp = $A;
            $_ /= $tmp for $A,$B,$C;
            printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", "nrm1",$A,$B,$C,$D,$E,$F if $DEBUG_P_SOLV;
            # zero out first column of row2
            $tmp = $D;
            $D -= $tmp*$A;
            $E -= $tmp*$B;
            $F -= $tmp*$C;
            printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", "zro1",$A,$B,$C,$D,$E,$F if $DEBUG_P_SOLV;
            # normalize row2 by E
            die "divide by 0" if !$E;
            $tmp = $E;
            $_ /= $tmp for $D, $E, $F;
            printf STDERR "\n\t%s=[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", "nrm2",$A,$B,$C,$D,$E,$F if $DEBUG_P_SOLV;
            # zero out second column of row1
            $tmp = $B;
            $A -= $tmp*$D;
            $B -= $tmp*$E;
            $C -= $tmp*$F;
            printf STDERR "\n\tslvd:[%+09.3f %+09.3f %+09.3f]\n\t     [%+09.3f %+09.3f %+09.3f]\n", $A,$B,$C,$D,$E,$F if $DEBUG_P_SOLV;

            # doesn't matter whether swapped or not, the u value will always end up in C, and the v value in F
            $xc = $x0 + $C*$dx0;
            $yc = $y0 + $C*$dy0;
        }

        # now do distance from 0 to C and C to 1
        $outer += sqrt(($xc-$x0)**2 + ($yc-$y0)**2);
        $outer += sqrt(($xc-$x1)**2 + ($yc-$y1)**2);

        if($DEBUG_P_DETL) {
            # full debug output
            printf STDERR "* %d: %+06.3f:(%+06.3f,%+06.3f) %.3f:(%+06.3f,%+06.3f) => inner:%+06.3f", $i, $t0, $x0, $y0, $t1, $x1, $y1, $inner;
            printf STDERR "\tG0:(%+06.3f,%.3f) G1:(%+06.3f,%.3f) u:%+06.3f v:%+06.3f C:(%+06.3f,%+06.3f) => outer:%.3f\n", $dx0,$dy0, $dx1,$dy1, $C,$F, $xc, $yc, $outer;
        } elsif ($DEBUG_P_LMTD) {
            # limited debug output
            printf STDERR "%+06.3f\t%+06.3f\n", $x0, $y0 if $i==1;
            printf STDERR "%+06.3f\t%+06.3f\n%+06.3f\t%+06.3f\n", $xc, $yc, $x1, $y1;
        }

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
    is($qpi, float(sqrt(3**2+2**2)), 'inner quarter perim with imax=1 (diagonal from <3,0> to <0,2>)');
    is($qpo, float(2+3), 'outer quarter perim with imax=1 (up 2 from <3,0> to <3,2>; over 3 to <0,2>)');
    ($qpi,$qpo) = superellipse_quarter_perim(3,2,2);
    is($qpi, float(3.9664, tolerance=>1e-4), 'inner quarter perim with imax=default(100)');
    is($qpo, float(3.9664, tolerance=>1e-4), 'outer quarter perim with imax=default(100)');
    is($qpo, float($qpi  , tolerance=>2e-4), 'inner and outer quarter perim equivalent with imax=default(100)');
};

subtest "SE[3,3,1]" => sub {
    my($x,$y) = superellipse_point(M_PI_4, 3, 3, 1);
    is($x, float(1.5), 'x(π/4)');
    is($y, float(1.5), 'y(π/4)');
    my($dx,$dy) = superellipse_grad(M_PI_4, 3, 3, 1);
    is($dx, float(-3.0), 'dx(π/4)');
    is($dy, float(+3.0), 'dy(π/4)');
    my ($qpi,$qpo) = superellipse_quarter_perim(3,3,1,1);
    is($qpi, float(sqrt(3**2+3**2)), 'inner quarter perim with imax=1');
    is($qpo, float(2*sqrt(1.5**2+1.5**2)), 'outer quarter perim with imax=1');

    # Edgecase checking: θ=0 originally gave unit(grad)==divide-by-zero-error; θ=π/4 cames close, but not actually
    #   reworked grad() to call itself with t+1e-9 if it's going to return exactly <0,0>
    ($dx,$dy) = superellipse_grad(0, 3, 3, 1);
    is([$dx,$dy], [(float(0,tolerance=>1e-6))x2], '[edgecase] grad(rhombus,right)');
    ($dx,$dy) = superellipse_grad(M_PI_2, 3, 3, 1);
    is([$dx,$dy], [(float(0,tolerance=>1e-6))x2], '[edgecase] grad(rhombus,top)');
    ($dx,$dy) = superellipse_grad(M_PI, 3, 3, 1);
    is([$dx,$dy], [(float(0,tolerance=>1e-6))x2], '[edgecase] grad(rhombus,left)');
    ($dx,$dy) = superellipse_grad(3*M_PI_2, 3, 3, 1);
    is([$dx,$dy], [(float(0,tolerance=>1e-6))x2], '[edgecase] grad(rhombus,bottom)');
};

subtest "SE[1,1,1] edgecase" => sub {
    my($x,$y) = superellipse_point(M_PI_4, 1, 1, 1);
    is($x, float(0.5), 'x(π/4)');
    is($y, float(0.5), 'y(π/4)');
    my($dx,$dy) = superellipse_grad(M_PI_4, 1, 1, 1);
    is($dx, float(-1.0), 'dx(π/4)');
    is($dy, float(+1.0), 'dy(π/4)');
    todo "need to improve diamond handling" => sub {
    $DEBUG_P_SOLV=1; $DEBUG_GRAD=1;
    my ($qpi,$qpo) = eval { superellipse_quarter_perim(1,1,1,1); } or do { warn $@; (undef,undef); };
    is($qpi, float(sqrt(1**2+1**2)), 'inner quarter perim with imax=1');
    is($qpo, float(2*sqrt(0.5**2+0.5**2)), 'outer quarter perim with imax=1');
    $DEBUG_P_SOLV=0; $DEBUG_GRAD=0;
    };
};

subtest "SE[1,1,4]: Squircle" => sub {
    # the squircle is geometric mean of circle (✓0.5,✓0.5) and square(1,1), so corners will be at ✓(✓0.5*1)
    my $quadroot = sqrt(M_SQRT1_2);

    # use the squircle to test all four quadrants for _point
    my($x,$y) = superellipse_point(M_PI_4, 1, 1, 4);
    is($x, float($quadroot), 'x(π/4)');
    is($y, float($quadroot), 'y(π/4)');

    ($x,$y) = superellipse_point(3*M_PI_4, 1, 1, 4);
    is($x, float(-$quadroot), 'x(3π/4)');
    is($y, float(+$quadroot), 'y(3π/4)');

    ($x,$y) = superellipse_point(5*M_PI_4, 1, 1, 4);
    is($x, float(-$quadroot), 'x(5π/4)');
    is($y, float(-$quadroot), 'y(5π/4)');

    ($x,$y) = superellipse_point(7*M_PI_4, 1, 1, 4);
    is($x, float(+$quadroot), 'x(7π/4)');
    is($y, float(-$quadroot), 'y(7π/4)');

    # use the squircle to test all four quadrants for _grad
    my $deriv = 0.5*M_SQRT1_2 / $quadroot;
    my($dx,$dy) = superellipse_grad(M_PI_4, 1, 1, 4);
    is($dx, float(-$deriv), 'dx(π/4)');
    is($dy, float(+$deriv), 'dy(π/4)');

    ($dx,$dy) = superellipse_grad(3*M_PI_4, 1, 1, 4);
    is($dx, float(-$deriv), 'dx(3π/4)');
    is($dy, float(-$deriv), 'dy(3π/4)');

    ($dx,$dy) = superellipse_grad(5*M_PI_4, 1, 1, 4);
    is($dx, float(+$deriv), 'dx(5π/4)');
    is($dy, float(-$deriv), 'dy(5π/4)');

    ($dx,$dy) = superellipse_grad(7*M_PI_4, 1, 1, 4);
    is($dx, float(+$deriv), 'dx(7π/4)');
    is($dy, float(+$deriv), 'dy(7π/4)');

    my ($qpi,$qpo) = superellipse_quarter_perim(1,1,4,1);
    is($qpi, float(M_SQRT2), 'inner quarter perim with imax=1 (one diagonal)');
    is($qpo, float(2), 'outer quarter perim with imax=1 (vert+horiz)');

    #$DEBUG_P_DETL = 1;
    ($qpi,$qpo) = superellipse_quarter_perim(1,1,4,2);
    # inner is easy with geometry; outer is harder so just put in the approximate value
    #   The gradient at <$qr,$qr> is unit(-1,+1); it's 1-$qr from the x=1 right wall, so it will drop 1-$qr => yitc=qr-(1-qr)=2qr-1
    #   symmetry says it's same length along top, so that's L(horiz+vert)=2qr-1
    #   the diagonal has each edge = 1-$yitc as well, so its L(diag) = sqrt( 2 * (1-$yitc)**2 )
    is($qpi, float(2*sqrt((1-$quadroot)**2+$quadroot**2)), 'inner quarter perim with imax=2 (two diagonals)');
    my $yitc = 2*$quadroot - 1;
    my $v = 1-$yitc;
    is($qpo, float(2*$yitc + sqrt(2*($v**2))), 'outer quarter perim with imax=2 (vert+diag+horiz)');

    ($qpi,$qpo) = superellipse_quarter_perim(1,1,4);
    is($qpo, float($qpi, tolerance=>100e-6), 'convergence: inner vs outer quarter perim');
};

# not a test, but just noting results:
do {
    for my $b (1 .. 10) {
        my ($qpi,$qpo) = superellipse_quarter_perim(1,$b,2);
        my $qp = ($qpi+$qpo)/2;
        note sprintf "SE[1,%2d,2] => q=%+010.6f=%+010.6fπ\t[circle->ellipse]\n", $b, $qp, $qp/M_PI;
    }

    for my $p (map {$_/2} 2 .. 8) {   # 1.5 to 4 by 0.5; $p=1 gives divide-by-zero
        my ($qpi,$qpo) = superellipse_quarter_perim(1,1,$p);
        my $qp = ($qpi+$qpo)/2;
        note sprintf "SE[1,1,%03.1f] => q=%+010.6f=%+010.6fπ\t[circle->squircle]\n", $p, $qp, $qp/M_PI;
    }

    for my $b (1 .. 10) {
        my ($qpi,$qpo) = superellipse_quarter_perim(1,$b,4);
        my $qp = ($qpi+$qpo)/2;
        note sprintf "SE[1,%2d,4] => q=%+010.6f=%+010.6fπ\t[squircle->superellipse]\n", $b, $qp, $qp/M_PI;
    }
};

done_testing();
