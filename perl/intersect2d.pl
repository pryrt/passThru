#!perl -l

use 5.012; # strict, //
use warnings;
use autodie;
use Carp;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Intersect;
use Test::More tests => 34;
BEGIN { $| = 1; }

# utilities for capturing DEBUG
{
    my ($_cap_mem, $_cap_fh, $_old_fh) = ('');  # uncoverable statement count:2
    sub setDEBUG {
        my $dbg = shift // 1;
        $Math::Vector::Real::Intersect::DEBUG = $dbg;
        if($dbg) {
            $_cap_mem = '';
            open $_cap_fh, '>', \$_cap_mem;
            $_old_fh = select $_cap_fh;
        } else {
            select $_old_fh;
            close($_cap_fh) if defined $_cap_fh;
            ($_cap_mem,$_cap_fh,$_old_fh) = (undef)x3;
        }
        $dbg;
    }
    sub getOUTPUT {
        $_cap_mem;
    }
    END { setDEBUG(0) }
}

##############################
# Cross Products
##############################

do {    # 3d cross
    my $space1 = V(1,2,0);
    my $space2 = V(3,4,0);
    my $got = $space1 x $space2;
    my $exp = V(0, 0, -2);
    is_deeply $got, $exp, "cross product: 3d";
    #note sprintf "\t\tspace: %s x %s = %s vs %s", $space1 , $space2, $got, $exp;
};

do {    # cross with aref, reverse order (covers mixed-aref/object and the cross-order-swap)
    my $space1 = [1,2,0];
    my $space2 = V(3,4,0);
    my $got = $space1 x $space2;
    my $exp = V(0, 0, -2);
    is_deeply $got, $exp, "cross product: aref x vector";
    #note sprintf "\t\taref x vector: %s x %s = %s vs %s", "[".join(",",@$space1)."]" , $space2, $got, $exp;
};

do {
    my $plane1 = V(1,2);
    my $plane2 = V(3,4);
    my $got = $plane1 x $plane2;
    my $exp = -2;
    is_deeply $got, $exp, "cross product: 2d";
    #note sprintf "\t\tplane: %s x %s = %s vs %s", $plane1 , $plane2, $got, $exp;
};

##############################
# Lines
##############################

do {
    my $v1 = V(0,0);
    my $v2 = V(1,1);
    my $d1 = V(1,0);
    my $d2 = V(0,-1);
    my $got = intersect_lines($v1,$d1, $v2,$d2);
    my $exp = V(1,0);
    is_deeply $got, $exp, "intersect_lines: simple";
    #note sprintf "\t\tintersect_lines(%s @ %s, %s @ %s) = %s vs %s", $v1 , $d1, $v2 , $d2, $got, $exp;
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

    # 'swapped' coverage:
    $got = intersect_lines($v2,$d2, $v1,$d1);
    is_deeply $got, $exp, "intersect_lines: simple (swapped vector order)";

    # DEBUG coverage
    setDEBUG(1);
    $got = intersect_lines($v1,$d1, $v2,$d2);
    is_deeply $got, $exp, "intersect_lines: simple w/ DEBUG";
    like getOUTPUT, qr/\Q[ s ]\E[^\r\n]+\n[^\r\n]+\Q[ t ]\E/s, 'reasonable DEBUG output ['.__LINE__.']';
    setDEBUG(0);

    # error condition coverage: direction1 is zero-vector
    my $dz = V(0,0);
    undef $@;
    undef $got;
    eval {
        $got = intersect_lines($v1,$dz, $v2,$d2);
    };
    like $@, qr/d1=.* is the zero vector/, "error coverage: throws for d1 being <0,0>";

    # error condition coverage: direction2 is zero-vector
    undef $@;
    undef $got;
    eval {
        $got = intersect_lines($v1,$d1, $v2,$dz);
    };
    like $@, qr/d2=.* is the zero vector/, "error coverage: throws for d2 being <0,0>";

    # error condition coverage: parallel
    my $dp = V(@$d2);
    undef $@;
    undef $got;
    eval {
        $got = intersect_lines($v1,$dp, $v2,$d2);
    };
    like $@, qr/could not solve .* parallel/, "error coverage: throws for d1 being parallel to d2";
};

do {    # this test case found a bug in the original code
    my $sq = sqrt(0.5);
    my $v1 = V(1,0);
    my $v2 = V($sq,$sq);
    my $d1 = V(0,1);
    my $d2 = -V(-$sq,$sq);
    my $got = intersect_lines($v1,$d1, $v2,$d2);
    my $exp = V(1,sqrt(2)-1);
    is_deeply $got, $exp, "intersect_lines: test case up-vs-diagonal";
    #note sprintf "\t\tintersect_lines(%s @ %s, %s @ %s) = %s vs %s: test case that found bug in original code", $v1 , $d1, $v2 , $d2, $got, $exp;

    # coverage: 'swapped' flag
    $got = intersect_lines($v2,$d2, $v1,$d1);
    is_deeply $got, $exp, "intersect_lines: test case up-vs-diagonal (swapped vector order)";


    # DEBUG coverage
    setDEBUG(1);
    $got = intersect_lines($v1,$d1, $v2,$d2);
    is_deeply $got, $exp, "intersect_lines: swapped w/ DEBUG";
    like getOUTPUT, qr/\Q[ t ]\E[^\r\n]+\n[^\r\n]+\Q[ s ]\E/s, 'reasonable DEBUG output ['.__LINE__.']';
    setDEBUG(0);

};

do {    # found another bug: swapping pairs didn't work; this was used to debug/verify, but I've added other swap-order tests above as well
    #                           * <-----. v2 = (0,15) @ (-1,0)
    #                           ^
    #                           |
    #   (-100,0) @ (0,1) = v1   .
    #   where v2,d2,v1,d1 worked, but v1,d1,v2,d2 did not
    my $v1 = V(-100,0);
    my $d1 = V(0,1);
    my $v2 = V(0,15);
    my $d2 = V(-1,0);
    my $exp = V(-100,15);
    my $got = intersect_lines($v2,$d2, $v1,$d1);
    is_deeply $got, $exp, "intersect_lines: test case: v2, left, v1, up";

    $got = intersect_lines($v1,$d1, $v2,$d2);
    is_deeply $got, $exp, "intersect_lines: test case: v1, up, v2, left";
};

do {    # test case: parallel-but-meeting (co-linear)
    my $v1 = V(0,0);
    my $v2 = V(3,4);
    my $d1 = V(3,4);
    my $d2 = V(3,4);
    my $got = intersect_lines($v1,$d1, $v2,$d2);
    my $exp = ($v1+$v2)/2;  # equal |dir| so halfway between
    is_deeply $got, $exp, "intersect_lines: test case: parallel intersection (co-linear)";
    #note sprintf "\t\tintersect_lines(%s @ %s, %s @ %s) = %s vs %s: parallel intersection", $v1 , $d1, $v2 , $d2, $got, $exp;

    # swap order
    $got = intersect_lines($v2,$d2, $v1,$d1);
    is_deeply $got, $exp, "intersect_lines: test case: parallel intersection (co-linear) (swapped vector order)";

};

do {    # test case: vertically aligned: co-linear _and_ dx1=dx2=0 _and_ DEBUG
    my $v1 = V(0,0);
    my $v2 = V(0,6);
    my $d1 = V(0,1);
    my $d2 = -2*$d1;
    setDEBUG(1);
    my $got = intersect_lines($v1,$d1, $v2,$d2);
    like getOUTPUT, qr/intersect_lines: checking for parallelism/, 'reasonable DEBUG output ['.__LINE__.']';
    setDEBUG(0);
    my $exp = ($v2-$v1)*1/3+$v1;    # |d1|=|d2|/2, so only 1/3 of the way between v1 and v2
    is_deeply $got, $exp, "intersect_lines: test case: vertical imbalanced distance";
    #note sprintf "\t\tintersect_lines(%s @ %s, %s @ %s) = %s vs %s: vertical and inline and imbalanced", $v1 , $d1, $v2 , $d2, $got, $exp;

    # swap order
    $got = intersect_lines($v2,$d2, $v1,$d1);
    is_deeply $got, $exp, "intersect_lines: test case: vertical imbalanced distance (swapped vector order)";
};

do {    # test case: same point (within tolerance)
    $Math::Vector::Real::Intersect::TOLERANCE = 0.05;
    my $v1 = V(0,0);
    my $v2 = V(0,0.01); # within tolerance of being the same point
    my $d1 = V(4,3);
    my $d2 = V(3,4);
    my $got = intersect_lines($v1,$d1, $v2,$d2);
    my $exp = $v1;
    is_deeply $got, $exp, "intersect_lines: test case: distance within tolerance";
    #note sprintf "\t\tintersect_lines(%s @ %s, %s @ %s) = %s vs %s: distance within tolerance", $v1 , $d1, $v2 , $d2, $got, $exp;

    # swap order: but when within tolerance, it _always_ returns the first vector, so change expected value
    $got = intersect_lines($v2,$d2, $v1,$d1);
    $exp = $v2;
    is_deeply $got, $exp, "intersect_lines: test case: distance within tolerance (swapped vector order, so swap expected value)";

};

##############################
# Circles
##############################


do {
    my ($c1,$r1) = (V(0,0), 3.14159);
    my ($c2,$r2) = (V(3,4), 2.71828);

    # different expectations depending on clockwise or counter-clockwise
    my $expP = V(0.430890340295233, 3.11189994099108);
    my $expN = V(2.86677464806877, 1.28498671016092);

    # positive polarity
    my $got = intersect_circles($c1,$r1,$c2,$r2);
    is_deeply $got, $expP, "intersect_circles: positive polarity";
    #note sprintf "\t\tintersect_circles(%s,%s,%s,%s) = %s vs %s", $c1,$r1,$c2,$r2, $got, $exp;

    # coverage: swap order, so swap expectation as well
    $got = intersect_circles($c2,$r2,$c1,$r1);
    is_deeply $got, $expN, "intersect_circles: positive polarity (swap center order)";

    # coverage: DEBUG
    setDEBUG(1);
    $got = intersect_circles($c1,$r1,$c2,$r2);
    is_deeply $got, $expP, "intersect_circles: positive polarity w/ DEBUG";
    my $out = getOUTPUT();
    like $out, qr/\ADEBUG intersect_circles/, 'reasonable DEBUG output [' . __LINE__ . ']';
    setDEBUG(0);

    # coverage: negative polarity in original order
    $r2 *= -1;
    $got = intersect_circles($c1,$r1,$c2,$r2);
    is_deeply $got, $expN, "intersect_circles: negative polarity";
    #note sprintf "\t\tintersect_circles(%s,%s,%s,%s) = %s vs %s", $c1,$r1,$c2,$r2, $got, $exp;

    # coverage: swap order so swap expectation
    $got = intersect_circles($c2,$r2,$c1,$r1);
    my $gotRounded = sprintf "{%.6f,%.6f}", @$got;
    my $expRounded = sprintf "{%.6f,%.6f}", @$expP;
    is_deeply $gotRounded, $expRounded, "intersect_circles: negative polarity (swap center order)";

    # coverage: DEBUG in negative polarity
    setDEBUG(); # setDEBUG(1);
    $got = intersect_circles($c1,$r1,$c2,$r2);
    is_deeply $got, $expN, "intersect_circles: negative polarity w/ DEBUG";
    $out = getOUTPUT();
    like $out, qr/\ADEBUG intersect_circles/, 'reasonable DEBUG output [' . __LINE__ . ']';
    setDEBUG(0);
};

do {
    # zero distance on d1, but the center1 _is_ on the second circle's perimeter
    my ($c1,$r1,$c2,$r2) = (V(0,0), 0, V(1,0), 1);
    my $exp = $c1;
    my $got = intersect_circles($c1,$r1,$c2,$r2);
    is_deeply $got, $exp, "intersect_circles: d1==0";

    # zero distance on d2, but the center2 _is_ on the first circle's perimeter
    ($r1,$r2) = (1,0);
    $exp = $c2;
    $got = intersect_circles($c1,$r1,$c2,$r2);
    is_deeply $got, $exp, "intersect_circles: d2==0";

    # too far apart
    $c2 = V(2,0);
    undef $got;
    undef $@;
    eval { $got = intersect_circles($c1,$r1,$c2,$r2) };
    like $@, qr/intersect_circles.*are too far apart/, "intersect_circles: throw because too far apart";
};

