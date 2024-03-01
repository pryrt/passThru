#!perl

use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Bezier::Cubic qw/CubicBezier V/;

my $top = 100;
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
#   x something that does the quadratic solver for dBeq0 (for x or y),
#   x a wrapper that can do min or max using dBeq0, with or without limiting t to 0..1
#   x a method to tilt all the points in the Bezier controls around some center point
#       x this will require a rotate_2d, which M::V::R does not currently provide, but should

# verify min and max are working:

# TODO: start tilting...
