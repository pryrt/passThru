#!perl
package Math::Vector::Real::Intersect 0.00;

=encoding utf8

=head1 NAME

Math::Vector::Real::Intersect - Make it easy to intersect lines or circles with Math::Vector::Real objects

=cut

use 5.012; # strict, //
use warnings;
use Carp;
use Math::Vector::Real;
use Exporter 5.57 qw(import);
our @EXPORT_OK = qw(V intersect_lines intersect_circles);
our @EXPORT = @EXPORT_OK;

package Math::Vector::Real {
    sub mycross {
        &_check_dim; # uncoverable pod # this is calling a private function to the MVR module; it is not my job to have POD for such
        my ($v0, $v1) = ($_[2] ? @_[1, 0] : @_);
        my $dim = @$v0;
        if ($dim == 2) {
            return $v0->[0] * $v1->[1] - $v0->[1] * $v1->[0]
        }
        goto \&cross;
    }
    use overload 'x' => \&mycross;
}

our $DEBUG = 0;
our $TOLERANCE = 1e-9;

sub intersect_lines {
    my ($p1,$d1, $p2,$d2) = @_;
    Math::Vector::Real::_check_dim($p1,$p2);
    Math::Vector::Real::_check_dim($p1,$d1);
    Math::Vector::Real::_check_dim($p2,$d2);
    # <p1> + s*<d1> = <p2> + t*<d2>
    #   [ dx1    -dx2 ] . [ s ] = [ x2-x1 ]         a b    e
    #   [ dy1    -dy2 ]   [ t ]   [ y2-y1 ]         c d    f
    my ($a,$b,$c,$d,$e,$f);
    my ($div, $mul);
    my $swap = 0;

    # error checking
    if( abs($d1) < $TOLERANCE ) { croak "d1=$d1 is the zero vector" }
    if( abs($d2) < $TOLERANCE ) { croak "d2=$d2 is the zero vector" }

    # (essentially) same point: intersects at that point
    if( abs($p1->dist($p2))<$TOLERANCE) {
        return $p1;
    }

    # if directions parallel to each other and to vector from p1 to p2, can just go partway between the two
    #   originally I was going to go halfway, but decided to balance it so if |d1|>|d2|, then it will be proportionally farther from p1 than from p2
    if( abs($d1 x $d2)<$TOLERANCE ) {
        my $delta = $p2 - $p1;
        if($DEBUG) {
            printf "intersect_lines: checking for parallelism: %s x %s = %s => are they parallel to each other? also look at d# x delta=%s = %s as well\n", $d1, $d2, $d1 x $d2, $delta, $d1 x $delta;
        }
        if( abs($d1 x $delta)<$TOLERANCE ) {
            my $m1 = abs($d1);
            my $m2 = abs($d2);
            my $f = $m1 / ($m1+$m2);    # divide-by-zero-check is in the error-checking zero-vector checks, above
            return ($p2-$p1)*$f+$p1;
        }
    }

    # use matrixes
    if( $d1->[0] ) {            # first row can be x's
        $a = $d1->[0];
        $b = -$d2->[0];
        $c = $d1->[1];
        $d = -$d2->[1];
        $e = $p2->[0] - $p1->[0];
        $f = $p2->[1] - $p1->[1];
    } else {                    # swap x and y (due to if-zero check above, it will never get here with the condition that both d1x and d1y are zero)
        $a = $d1->[1];
        $b = -$d2->[1];
        $c = $d1->[0];
        $d = -$d2->[0];
        $e = $p2->[1] - $p1->[1];
        $f = $p2->[0] - $p1->[0];
        $swap = 1;
    }
    if($DEBUG) { printf "[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n\n", $a, $b, ($swap ? 't' : 's'), $e, $c, $d, ($swap ? 's' : 't'), $f; }

    # normalize abe to 1be
    $div = $a;
    $_ /= $div for $a,$b,$e;
    if($DEBUG) { printf "[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n\n", $a, $b, ($swap ? 't' : 's'), $e, $c, $d, ($swap ? 's' : 't'), $f; }

    # subtract cdf - mul*(abe) (where mul is c) to get 0df
    $mul = $c;
    $c -= $mul*$a;
    $d -= $mul*$b;
    $f -= $mul*$e;
    if($DEBUG) { printf "[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n\n", $a, $b, ($swap ? 't' : 's'), $e, $c, $d, ($swap ? 's' : 't'), $f; }

    # normalize 0df to 01f
    if( $d ) {                  # first row can be x's
        $div = $d;
    } else {
        croak "could not solve ($p1,$d1, $p2,$d2): parallel";
    }
    $_ /= $div for $c,$d,$f;
    if($DEBUG) { printf "[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n\n", $a, $b, ($swap ? 't' : 's'), $e, $c, $d, ($swap ? 's' : 't'), $f; }

    # subtract 1be - mul*(01f) [where mul is b]
    $mul = $b;
    $a -= $mul*$c;
    $b -= $mul*$d;
    $e -= $mul*$f;

    my $s = $e;
    my $t = $f;
    if($DEBUG) {
        printf "solve => s = %+010.6f, t = %+010.6f\t=>\t", $s, $t;
        printf "$p1 + $s*$d1 = %s\t|vs|\t$p2 + $t*$d2 = %s\n\n", $p1 + $s * $d1, $p2 + $t * $d2;
    }

    return $p1 + $s * $d1;
}

sub intersect_circles {
    my ($c1,$r1, $c2,$r2) = @_;
    Math::Vector::Real::_check_dim($c1,$c2);
    # if you change coordinates from (x,y) to e*<u>+f*<v>, where <u> is unit(c2-c1) and <v> is +/- 90deg from that (depending on r1/r2 sign),
    #   then you have a simplified equation, because both circles are on the <u> axis, with second circle offset by d along that axis
    #       equations       e**2 + f**2 = r1**2                 (e-d)**2 + f**2 = r2**2
    #       expand          e**2 + f**2 = r1**2                 e**2 + d**2 - 2*e*d + f**2 = r2**2
    #       subtract                                                   d**2 - 2*e*d = r2**2 - r1**2
    #       solve for e     e = (r2**2 - r1**2 - d**2) / (-2*d)
    #       solve for f     f = sqrt( r1**2 - e**2 )
    my $delta = $c2 - $c1;  # vector from c1 to c2
    croak "intersect_circles($c1,$r1,$c2,$r2) are too far apart" if abs($delta) > abs($r1)+abs($r2);
    if($DEBUG) {
        printf "DEBUG intersect_circles($c1,$r1,$c2,$r2):\n";
        printf "\tdelta = %s: abs=%+010.6f, |r1|+|r2|=\%+010.6f\n", $delta, abs($delta), abs($r1)+abs($r2);
    }
    my $u = $delta->versor;
    if($DEBUG) { printf "\t<u> = %s\n", $u; }
    my $sign = ($r2 ? $r1/$r2 : 0);
    my $v = ($sign>0) ? V(-($u->[1]), +($u->[0])) : V(+($u->[1]), -($u->[0]));
    if($DEBUG) { printf "\t<v> = %s\n", $v; }

    # d: distance between c2 and c1 => |$delta|
    my $d = abs($delta);

    # solve for e and f using equations above
    my $e = ($r2**2 - $r1**2 - $d**2) / (-2*$d);
    my $f = sqrt($r1**2 - $e**2);

    my $solve = $c1 + $e*$u + $f*$v;
    if($DEBUG) { printf "\t%s + %s*%s + %s*%s = %s\n", $c1, $e, $u, $f, $v, $solve; }

    return $solve;
}

1;
=head1 TODO

document, test, etc...

=head1 TEST

=head2 mycross

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

=head2 intersect_lines

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

=head2 intersect_circles

    eval {
        my ($c1,$r1) = (V(0,0), 3.14159);
        my ($c2,$r2) = (V(3,4), 2.71828);
        print "EVAL intersect_circles($c1,$r1,$c2,$r2) = ", intersect_circles($c1,$r1,$c2,$r2);
        $r2 *= -1;
        print "EVAL intersect_circles($c1,$r1,$c2,$r2) = ", intersect_circles($c1,$r1,$c2,$r2);
        1;
    } or warn $@;

=head2 $DEBUG

    $Math::Vector::Real::Intersect::DEBUG = 1;

Turns on debug printing when set true.  Defaults to C<0>.

=head2 $TOLERANCE

    $Math::Vector::Real::Intersect::TOLERANCE = 1e-12;

Since floating point math isn't exact, use this for tolerances for zero-checks.  Defaults to C<1e-9>.

=cut
