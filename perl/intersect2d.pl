#!perl -l

use 5.012; # strict, //
use warnings;
use Carp;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Intersect;

# convert this to the test suite
use Test::More tests => 6;
$| = 1;

eval {
    my $space1 = V(1,2,0);
    my $space2 = V(3,4,0);
    my $got = $space1 x $space2;
    my $exp = V(0, 0, -2);
    is_deeply $got, $exp, "space";
    note sprintf "\t\tspace: %s x %s = %s vs %s", $space1 , $space2, $got, $exp;
    1;
} or warn $@;
eval {
    my $plane1 = V(1,2);
    my $plane2 = V(3,4);
    my $got = $plane1 x $plane2;
    my $exp = -2;
    is_deeply $got, $exp, "plane";
    note sprintf "\t\tplane: %s x %s = %s vs %s", $plane1 , $plane2, $got, $exp;
    1;
} or warn $@;

eval {
    my $v1 = V(0,0);
    my $v2 = V(1,1);
    my $d1 = V(1,0);
    my $d2 = V(0,-1);
    my $got = intersect_lines($v1,$d1, $v2,$d2);
    my $exp = V(1,0);
    is_deeply $got, $exp, "intersect_lines: simple";
    note sprintf "\t\tintersect_lines(%s @ %s, %s @ %s) = %s vs %s", $v1 , $d1, $v2 , $d2, $got, $exp;
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
    # this test case found a bug in the original code
    my $sq = sqrt(0.5);
    my $v1 = V(1,0);
    my $v2 = V($sq,$sq);
    my $d1 = V(0,1);
    my $d2 = -V(-$sq,$sq);
    my $got = intersect_lines($v1,$d1, $v2,$d2);
    my $exp = V(1,sqrt(2)-1);
    is_deeply $got, $exp, "intersect_lines: test case up-vs-diagonal";
    note sprintf "\t\tintersect_lines(%s @ %s, %s @ %s) = %s vs %s: test case that found bug in original code", $v1 , $d1, $v2 , $d2, $got, $exp;
    1;
} or warn $@;


eval {
    my ($c1,$r1) = (V(0,0), 3.14159);
    my ($c2,$r2) = (V(3,4), 2.71828);
    my $got = intersect_circles($c1,$r1,$c2,$r2);
    my $exp = V(0.430890340295233, 3.11189994099108);
    is_deeply $got, $exp, "intersect_circles: positive polarity";
    note sprintf "\t\tintersect_circles(%s,%s,%s,%s) = %s vs %s", $c1,$r1,$c2,$r2, $got, $exp;

    $r2 *= -1;
    $got = intersect_circles($c1,$r1,$c2,$r2);
    $exp = V(2.86677464806877, 1.28498671016092);
    is_deeply $got, $exp, "intersect_circles: negative polarity";
    note sprintf "\t\tintersect_circles(%s,%s,%s,%s) = %s vs %s", $c1,$r1,$c2,$r2, $got, $exp;
    1;
} or warn $@;
