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

my $im = GD::Image::->new(300,100,1);
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
    return @{V(100*$v->[0], 100-100*$v->[1])};
}

my $actual = CubicBezier(V(0,0), V(0,0.5), V(0.5,1), V(1,1));

srand(19750118);
my @samples = map { my $v; printf "%+6.3f [%+6.3f,%+6.3f]\n", $_, @{$v=$actual->B($_)}; $v } sort 0,1, map {rand()} 1..9; print "\n";
print "End Slopes: ", $actual->dBdt(0), " ... ", $actual->dBdt(1), "\n";

# initial guess vs samples
my $guess = CubicBezier(V(0,0), V(0,1), V(0,1), V(1,1));
for (1 .. 10) {
    my $t = $_/10;
    my $prev = ($_-1)/10;
    my $v = $guess->B($t);
    my $p = $guess->B($prev);
    $im->line(v2px($p), v2px($v), $c_plot);
}
for my $s (@samples) {
    $im->filledEllipse(v2px($s), 8,8, $c_samp);
    my ($t, $d, $v) = $guess->closestToPoint($s);
    printf "s:[%+6.3f,%+6.3f] -> B(t:%+6.3f) = [%+6.3f,%+6.3f] => dsq:%.3f\n", @$s, $t, @$v, $d;
    $im->line(v2px($s), v2px($v), $c_close);
    $im->filledEllipse(v2px($v), 4,4, $c_close);
}

# I was going to try to plot the gradient <x:d/dp2x,y:d/dp1y> across
#   a parametric grid... but  the dBdpN values are independent of the
#   current values of the parameters, and only depend on t,
#   so the gradient field will have a bunch of constant values
#   for a given t, so a parameter-space plot would be really boring
#   without being able to also include t information
#   I don't think I can turn those into a helpful visualization

# Maybe the visualization I really want is just to plot sum(dsq) as
#   color, for each of the handful of <p2x,p1y> pairs I pick.
my @keep = ('Inf', undef, undef, undef);
my $max = 50;
for my $j ( 0 .. $max ) {
    my $p1y = $j / $max;
    for my $i ( 0 .. $max ) {
        my $p2x = $i / $max;
        my $g = CubicBezier(V(0,0), V(0,$p1y), V($p2x,1), V(1,1));
        my $sum_dsq = 0;
        for my $s (@samples) {
            my ($t, $d, $v) = $g->closestToPoint($s);
            $sum_dsq += $d;
        }
        if($sum_dsq < $keep[0]) {
            @keep = ($sum_dsq, $p2x, $p1y, $g);
        }
        #printf "p2x=%+6.3f, p1y=%+6.3f -> sum(dsq) = %+.6f\n", $p2x, $p1y, $sum_dsq;
        my $m = 255-int(255*$sum_dsq*2.5);
        my $c = $im->colorResolve(0,$m,$m);
        my $ppt = V($p2x,$p1y);
        #printf "[%+6.3f,%+6.3f] 0x%06X\n", @$ppt, $c;
        $im->setPixel( v2px(V(1,0)+$ppt), $c);
    }
}
print "final => @keep\n";

# final guess
$guess = CubicBezier(V(0,0), V(0,$keep[2]), V($keep[1],1), V(1,1));
my $Q = V(2,0);
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
