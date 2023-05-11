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
        &_check_dim;
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
    if( $d1->[0] ) {            # first row can be x's
        $div = $d1->[0];
        $a = $d1->[0];
        $b = -$d2->[0];
        $c = $d1->[1];
        $d = -$d2->[1];
        $e = $p2->[0] - $p1->[0];
        $f = $p2->[1] - $p1->[1];
    } elsif ( $d1->[1] ) {      # first row can be y's
        $div = $d1->[1];
        $a = $d1->[1];
        $b = -$d2->[1];
        $c = $d1->[0];
        $d = -$d2->[0];
        $e = $p2->[1] - $p1->[1];
        $f = $p2->[0] - $p1->[0];
        $swap = 1;
    } else { croak "neither $d1 nor $d2 has non-zero x component"; }
    if($DEBUG) { printf "[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n\n", $a, $b, ($swap ? 't' : 's'), $e, $c, $d, ($swap ? 's' : 't'), $f; }

    # normalize abe to 1be
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
    } else { croak "could not solve ($p1,$d1, $p2,$d2) at the second step"; }
    $_ /= $div for $c,$d,$f;
    if($DEBUG) { printf "[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n[ %+010.6f %+010.6f ] [ %s ] = [ %+010.6f ]\n\n", $a, $b, ($swap ? 't' : 's'), $e, $c, $d, ($swap ? 's' : 't'), $f; }

    # subtract 1be - mul*(01f) [where mul is b]
    $mul = $b;
    $a -= $mul*$c;
    $b -= $mul*$d;
    $e -= $mul*$f;

    my $s = $swap ? $f : $e;
    my $t = $swap ? $e : $f;
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
    die "intersect_circles($c1,$r1,$c2,$r2) are too far apart" if abs($delta) > abs($r1)+abs($r2);
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


=cut
