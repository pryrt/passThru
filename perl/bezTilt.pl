#!perl

use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Bezier::Cubic qw/CubicBezier V/;

my $top = 80;
my $B = CubicBezier(V(100,$top), V(100,$top-50), V(50,$top-100), V(0,$top-100));
for my $t ( map {$_/10} 0 .. 10) {
    printf "print \@ t:%+06.3f => Bez=<%+8.3f,%+8.3f>\n", $t, @{ $B->B($t) };
}

# want to find the tilt angle such that the lowest point of B(t) is at y=0
# to do so, I need to loop on tilt, and for each tilt, find dB(t)/dt = 0
# By = (1-t)^3 * P0 + 3*(1-t)^2*t * P1 + 3*(1-t)*t^2 * P2 + t^3 * P3
# By = (-t^3 + 3*t^2 - 3*t + 1) * P0 + 3*(t^3 - 2*t^2 + t) * P1 + 3*(-t^3 + t^2) * P2 + (t^3) * P3
# By = (-1*P0 + 3*P1 - 3*P2 + 1*P3)*t^3 + (3*P0 - 6*P1 + 3*P2)*t^2 + (-3*P0 + 3)*t + (1*P0)*1
# dBy/dt = 3*(-1*P0 + 3*P1 - 3*P2 + 1*P3)*t^2 + 2*(3*P0 - 6*P1 + 3*P2)*t + 1*(-3*P0 + 3)
# dBy/dt = (-3*P0 + 9*P1 - 9*P2 + 3*P3)*t^2 + (6*P0 - 12*P1 + 6*P2)*t + (-3*P0 + 3)
# solve for a*t^2 + b*t + c = 0 using quadratic formula

# so, I will need these things in the library:
#   - something that does the quadratic solver for dBeq0 (for x or y),
#   - a wrapper that can do min or max using dBeq0, with or without limiting t to 0..1
#   - a method to tilt all the points in the Bezier controls around some center point
#       - this will require a rotate_2d, which M::V::R does not currently provide, but should

# verify min and max are working:
my $t;
$t = $B->dBeq0('max', 'y',-2.3, 2.3);   printf "min y [-2.3,2.3]\@ t:%+06.3f => Bez=<%+8.3f,%+8.3f>\n", $t, @{ $B->B($t) };
$t = $B->dBeq0('max', 'y');             printf "max y [ 0.0,1.0]\@ t:%+06.3f => Bez=<%+8.3f,%+8.3f>\n", $t, @{ $B->B($t) };
$t = $B->dBeq0('max', 'y', 0.3, 0.7);   printf "max y [ 0.3,0.7]\@ t:%+06.3f => Bez=<%+8.3f,%+8.3f>\n", $t, @{ $B->B($t) };
$t = $B->dBeq0('min', 'y', 0.3, 0.7);   printf "min y [ 0.3,0.7]\@ t:%+06.3f => Bez=<%+8.3f,%+8.3f>\n", $t, @{ $B->B($t) };
$t = $B->dBeq0('min', 'y');             printf "min y [ 0.0,1.0]\@ t:%+06.3f => Bez=<%+8.3f,%+8.3f>\n", $t, @{ $B->B($t) };
$t = $B->dBeq0('min', 'y',-2.3, 2.3);   printf "min y [-2.3,2.3]\@ t:%+06.3f => Bez=<%+8.3f,%+8.3f>\n", $t, @{ $B->B($t) };


use Data::Dump qw/dd/;
#dd \%::Math::;

$| = 1;
dd [0*atan2(1,1), $B->{p0}->rotate_2d( 0*atan2(1,1), $B->{p0}, $B->{p1}, $B->{p2}, $B->{p3} )];
dd [2*atan2(1,1), $B->{p0}->rotate_2d( 2*atan2(1,1), $B->{p0}, $B->{p1}, $B->{p2}, $B->{p3} )];
dd [4*atan2(1,1), $B->{p0}->rotate_2d( 4*atan2(1,1), $B->{p0}, $B->{p1}, $B->{p2}, $B->{p3} )];
dd [6*atan2(1,1), $B->{p0}->rotate_2d( 6*atan2(1,1), $B->{p0}, $B->{p1}, $B->{p2}, $B->{p3} )];
dd [8*atan2(1,1), $B->{p0}->rotate_2d( 8*atan2(1,1), $B->{p0}, $B->{p1}, $B->{p2}, $B->{p3} )];
dd [-2*atan2(1,1), $B->{p0}->rotate_2d(-2*atan2(1,1),$B->{p0}, $B->{p1}, $B->{p2}, $B->{p3} )];

dd {rotate_around_55 => [$B, $B->rotate(-2*atan2(1,1), V(50,50))] };
