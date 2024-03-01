#!perl
use 5.014; # strict, //, s//r
use warnings;
use Test::More;
use Test::Deep;

use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Bezier::Cubic qw/CubicBezier V/;

my $n100 = num(100,0.001);
my $n50 = num(50,0.001);
my $n0 = num(0,0.001);

# check initialization
my $B = CubicBezier(V(100,100), V(100,50), V(50,0), V(0,0));
cmp_deeply(
    $B,
    bless(
        {
            p0 => V($n100,$n100),
            p1 => V($n100,$n50),
            p2 => V($n50,$n0),
            p3 => V($n0,$n0),
        },
        'Math::Vector::Real::Bezier::Cubic'
    ),
    'Make sure Cubic Bezier B initialized correctly'
);

# check evaluation
my $b0p5x = num(68.75, 0.001);
my $b0p5y = num(31.25, 0.001);
for([0, V($n100,$n100)], [0.5, V($b0p5x,$b0p5y)], [1, V($n0,$n0)]) {
    my ($t, $exp) = @$_;
    cmp_deeply( $B->B($t), $exp, "check B->B($t)");
}

# check dBeq0 functionality
{
    my $t;
    $t = $B->dBeq0('max', 'x',-2.3, 2.3);   cmp_deeply $t, num( 0.0, 0.001), "max x [-2.3, 2.3]";
    $t = $B->dBeq0('max', 'x');             cmp_deeply $t, num( 0.0, 0.001), "max x [ 0.0, 1.0]";
    $t = $B->dBeq0('max', 'x', 0.3, 0.7);   cmp_deeply $t, num( 0.3, 0.001), "max x [ 0.3, 0.7]";
    $t = $B->dBeq0('min', 'x', 0.3, 0.7);   cmp_deeply $t, num( 0.7, 0.001), "min x [ 0.3, 0.7]";
    $t = $B->dBeq0('min', 'x');             cmp_deeply $t, num( 1.0, 0.001), "min x [ 0.0, 1.0]";
    $t = $B->dBeq0('min', 'x',-2.3, 2.3);   cmp_deeply $t, num( 2.0, 0.001), "min x [-2.3, 2.3]";

    $t = $B->dBeq0('max', 'y',-2.3, 2.3);   cmp_deeply $t, num(-1.0, 0.001), "max y [-2.3, 2.3]";
    $t = $B->dBeq0('max', 'y');             cmp_deeply $t, num( 0.0, 0.001), "max y [ 0.0, 1.0]";
    $t = $B->dBeq0('max', 'y', 0.3, 0.7);   cmp_deeply $t, num( 0.3, 0.001), "max y [ 0.3, 0.7]";
    $t = $B->dBeq0('min', 'y', 0.3, 0.7);   cmp_deeply $t, num( 0.7, 0.001), "min y [ 0.3, 0.7]";
    $t = $B->dBeq0('min', 'y');             cmp_deeply $t, num( 1.0, 0.001), "min y [ 0.0, 1.0]";
    $t = $B->dBeq0('min', 'y',-2.3, 2.3);   cmp_deeply $t, num( 1.0, 0.001), "min y [-2.3, 2.3]";

}

# check MVR 2d rotations
my $n150 = num(150, 0.001);
my $n200 = num(200, 0.001);
for (0,2,4,6,8,-2) {
    my $th =  $_*atan2(1,1);
    my %exp = (
        0 => [ V($n100,$n100), V($n100,$n50), V($n50,$n0), V($n0,$n0) ],
        2 => [ V($n100,$n100), V($n150,$n100), V($n200,$n50), V($n200,$n0) ],
        4 => [ V($n100,$n100), V($n100,$n150), V($n150,$n200), V($n200,$n200) ],
        6 => [ V($n100,$n100), V($n50,$n100), V($n0,$n150), V($n0,$n200) ],
    );
    $exp{8} = $exp{0};
    $exp{-2} = $exp{6};
    my $got = [$B->{p0}->rotate_2d($th, $B->{p0}, $B->{p1}, $B->{p2}, $B->{p3} )];
    cmp_deeply $got, $exp{$_}, sprintf('MVR::rotate_2d(%+6.3f rad)', $th);
}

my $R = $B->rotate(-2*atan2(1,1), V(50,50));
cmp_deeply(
    $R,
    bless(
        {
            p0 => V($n100,$n0),
            p1 => V($n50,$n0),
            p2 => V($n0,$n50),
            p3 => V($n0,$n100),
        },
        'Math::Vector::Real::Bezier::Cubic'
    ),
    'Make sure Cubic Bezier R rotated correctly'
);

done_testing;

