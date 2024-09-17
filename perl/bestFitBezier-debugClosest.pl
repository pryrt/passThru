#!perl

use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real;
use Math::Vector::Real::Bezier::Cubic;
use utf8;
use autodie;
use GD;

BEGIN { $| = 1; }

my $im = GD::Image::->new(400*1,400,1);
my $c_bg = $im->colorAllocate(51,51,51);
my $c_plot = $im->colorAllocate(191,191,191);
my $c_samp = $im->colorAllocate(255,0,0);
my $c_close = $im->colorAllocate(0,0,255);

END {
    open my $fh, '>:raw', 'out.png';
    print {$fh} $im->png();
    close $fh;
    system(1,'out.png');
}

sub v2px {
    my ($v) = @_;
    return @{V(400*$v->[0], 400*$v->[1])};
}

my @samples = (
    V(+0.5475, +0.6075),
    V(+0.5873, +0.6059),
    V(+0.6456, +0.5966),
    V(+0.7052, +0.5761),
    V(+0.7629, +0.5403),
    V(+0.7775, +0.5276),
    V(+0.8246, +0.4698),
    V(+0.8523, +0.4124),
    V(+0.8687, +0.3523),
    V(+0.8750, +0.2825),
);
my $P0 = $samples[0];
my $P3 = $samples[-1];
my $PM = V( $P3->[0], $P0->[1] );

# initial guess vs samples
my $guess = CubicBezier($P0, $PM, $PM, $P3);
printf "GUESS BEZ(%s,%s,%s,%s)\n", $P0, $PM, $PM, $P3;
for (1 .. 10) {
    my $t = $_/10;
    my $prev = ($_-1)/10;
    my $v = $guess->B($t);
    my $p = $guess->B($prev);
    $im->line(v2px($p), v2px($v), $c_plot);
}
$Math::Vector::Real::Bezier::Cubic::DEBUG_CLOSEST = 0;
for my $s (@samples) {
    $im->filledEllipse(v2px($s), 8,8, $c_samp);
    my ($t, $d, $v) = $guess->closestToPoint($s);
    printf "s:[%+9.6f,%+9.6f] -> B(t:%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", @$s, $t, @$v, $d;
    $im->line(v2px($s), v2px($v), $c_close);
    $im->filledEllipse(v2px($v), 4,4, $c_close);
}


# Maybe the visualization I really want is just to plot sum(dsq) as
#   color, for each of the handful of <p2x,p1y> pairs I pick.
my @keep = ('Inf', undef, undef, undef);
my $max = 50;
for my $j ( 0 .. $max ) {
    my $p1x = $j / $max;
    for my $i ( 0 .. $max ) {
        my $p2y = $i / $max;
        my $g = CubicBezier($P0, V($p1x,$P0->[1]), V($P3->[0],$p2y), $P3);
        my $sum_dsq = 0;
        for my $s (@samples) {
            my ($t, $d, $v) = $g->closestToPoint($s);
            $sum_dsq += $d;
        }
        if($sum_dsq < $keep[0]) {
            @keep = ($sum_dsq, $p1x, $p2y, $g);
        }
        #printf "p1x=%+6.3f, p2y=%+6.3f -> sum(dsq) = %+.6f\n", $p1x, $p2y, $sum_dsq;
        my $m = 255-int(255*$sum_dsq*2.5);
        my $c = $im->colorResolve(0,$m,$m);
        my $ppt = V($p1x,$p2y);
        #printf "[%+6.3f,%+6.3f] 0x%06X\n", @$ppt, $c;
        $im->setPixel( v2px(V(1,0)+$ppt), $c);
    }
}
print "final => @keep\n";

# final guess
$guess = $keep[3];
printf "FINAL BEZ(%s,%s,%s,%s)\n", $guess->{p0}, $guess->{p1}, $guess->{p2}, $guess->{p3};
my $Q = V(0,0);
for (1 .. 10) {
    my $t = $_/10;
    my $prev = ($_-1)/10;
    my $v = $guess->B($t);
    my $p = $guess->B($prev);
    $im->line(v2px($Q+$p), v2px($Q+$v), $c_plot);
}
for my $s (@samples) {
    $im->filledEllipse(v2px($Q+$s), 8,8, $c_samp);
    my ($t, $d, $v) = $guess->closestToPoint($s);
    printf "s:[%+6.3f,%+6.3f] -> B(t:%+6.3f) = [%+6.3f,%+6.3f] => dsq:%.3f\n", @$s, $t, @$v, $d;
    $im->filledEllipse(v2px($Q+$v), 4,4, $c_close);
}


__END__
GUESS BEZ({0.5475, 0.6075},{0.875, 0.6075},{0.875, 0.6075},{0.875, 0.2825})
The closestToPoint($samples[2]) is finding
    s:[+0.645600,+0.596600] -> B(t:+0.125000) = [+0.655601,+0.606865] => dsq:0.000205
In the 400px square, that's s:<258.24,238.64> -> <262.24,242.75>, which is <4px,4.11px> away (d=5.74)
So I need to debug.  Add the DEBUG_CLOSEST in the module.
Ah, okay, the distances from $samples[2] to BEZ(t) are _not_ linear, so the linear binary search doesn't work

Tried Newton's Method on F=dsq (t_new = t - F(t)/F'(t)),
    but newton's method tries to converge on 0, rather than finding minimum
        approximation:
            F' using [F(t+d)-F(t-d)]/[2d]
Next, tried Newton's Method on the slope, because I'm trying to find where slope=0:
    which should work for Newton's Method, since it crosses 0 somewhere.
        approximations:
            F using [dsq(t+d)-dsq(t-d)]/[2d]
            Fm = [dsq(t)-dsq(t-d)]/[d]
            Fp = [dsq(t)-dsq(t-d)]/[d]
            F' = [Fp-Fm]/[2d]
    but it wouldn't converge, whether I clamp 0<=t<=1 or not, and whether I
    scale F/F' by m or not.
Newton's Method on the F=dsq, with my clamping, was probably working better, but neither are working great.

Next, try doing 8 loops of 6 points each -- in each loop, find the smallest of the 6 values,
then narrow the range to be +/-1 point from the smallest, and loop again.  This searches 48
total values, and should narrow in close enough to the smallest distance, thus finding the
closest point.
