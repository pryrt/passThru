#!perl -l

use 5.012; # strict, //
use warnings;
use Carp;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Intersect;
$| = 1;

eval {
    my $space1 = V(1,2,0);
    my $space2 = V(3,4,0);
    print "space: $space1 x $space2 = ", $space1 x $space2;
    1;
} or warn $@;
eval {
    my $plane1 = V(1,2);
    my $plane2 = V(3,4);
    print "plane: $plane1 x $plane2 = ", $plane1 x $plane2;
    1;
} or warn $@;

eval {
    my $v1 = V(0,0);
    my $v2 = V(1,1);
    my $d1 = V(1,0);
    my $d2 = V(0,-1);
    print "intersect_lines($v1 @ $d1, $v2 @ $d2) = ", intersect_lines($v1,$d1, $v2,$d2);
    #                               .   (1,1) @ (0,-1)
    #                               |
    #                               V
    #   (0,0) @ (1,0)       .------>*
    #
    #   [ dx1    -dx2 ] . [ s ] = [ x2-x1 ]         a b    e
    #   [ dy1    -dy2 ]   [ t ]   [ y2-y1 ]         c d    f
    #
    #   [ 1      -0   ] . [ s ] = [ 1-0 ]         a b    e
    #   [ dy1    -dy2 ]   [ t ]   [ y2-y1 ]         c d    f
    #
    1;
} or warn $@;


eval {
    my ($c1,$r1) = (V(0,0), 3.14159);
    my ($c2,$r2) = (V(3,4), 2.71828);
    print "EVAL intersect_circles($c1,$r1,$c2,$r2) = ", intersect_circles($c1,$r1,$c2,$r2);
    $r2 *= -1;
    print "EVAL intersect_circles($c1,$r1,$c2,$r2) = ", intersect_circles($c1,$r1,$c2,$r2);
    1;
} or warn $@;
