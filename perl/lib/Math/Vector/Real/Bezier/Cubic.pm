package Math::Vector::Real::Bezier::Cubic;
use 5.014; # strict, //, s//r
use warnings;
use Carp qw/carp croak/;
use Exporter 5.57 'import';
use Math::Vector::Real qw/V/;
our @EXPORT_OK = qw/CubicBezier V/; # the Bezier generator, and the MVR generator
our @EXPORT = qw/CubicBezier/;      # by default, only export Bezier generator (so it's compatible with also importing MVR into caller)

BEGIN {
    unless(Math::Vector::Real->can('rotate_2d')) {
        *Math::Vector::Real::rotate_2d = sub {
            my ($v, $angle, @vecs) = @_;    # $v->rotate_2d($angle, @vecs) will rotate each of @vecs around center $v by ccw $angle
            my $c = cos($angle);
            my $s = sin($angle);
            my $rotated = sub {
                my $delta = $_[0] - $v;
                my ($x,$y) = @$delta;
                my $out = V( $x*$c-$y*$s, $x*$s+$y*$c ) + $v;
                #print STDERR "DEBUG: rotate_2d($v, $angle, $_[0]) => delta=<$x,$y> => out=$out\n";
                $out;
            };
            return wantarray
                ? map {$rotated->($_)} @vecs
                : $rotated->($vecs[0]);
        };
    }
}



sub CubicBezier {
    return __PACKAGE__->new(@_);
}

sub new {
    my ($class, $p0,$p1,$p2,$p3) = @_;
    my $self = bless {}, $class;
    $self->{p0} = $p0;
    $self->{p1} = $p1;
    $self->{p2} = $p2;
    $self->{p3} = $p3;
    return $self;
}

sub B {
    my ($self, $t) = @_;
    # print STDERR sprintf "compute(%s,%s)\n", $self, $t//'<undef>';
    croak "need a time t" unless defined $t;
    return
        +   1 * (1-$t)**3 *  1    * $self->{p0}
        +   3 * (1-$t)**2 * $t    * $self->{p1}
        +   3 * (1-$t)    * $t**2 * $self->{p2}
        +   1             * $t**3 * $self->{p3}
        ;
}

sub Bx {
    my ($self, $t) = @_;
    return $self->B($t)->[0];
}

sub By {
    my ($self, $t) = @_;
    return $self->B($t)->[1];
}

# partial with respect to time
sub dBdt {
    my ($self, $t) = @_;
    croak "need a time t" unless defined $t;
    my $a = -1*$self->{p0} +3*$self->{p1} -3*$self->{p2} +1*$self->{p3};
    my $b = +3*$self->{p0} -6*$self->{p1} +3*$self->{p2};
    my $c = -3*$self->{p0} +3*$self->{p1};
    my $d = +1*$self->{p0};
    # B = a*t^3 + b*t^2 + c*t + d
    # => B' = 3at^2 + 2bt + c
    return
        +   3 * $a * $t**2
        +   2 * $b * $t
        +   1 * $c
        ;
}

# finding min/max with respect to time
sub dBeq0 {
    my ($self, $min_or_max, $x_or_y, $t0, $t1) = @_;

    # make sure we chose min or max
    my %h = (min=>0, max=>1);
    croak "dBeq0: must choose min or max" unless exists $h{$min_or_max//'<undef>'};
    # I will need to pick the right element $i from the vector:

    # make sure we chose x or y
    my %dir = (x=>0, y=>1);
    croak "dBeq0: must choose x or y" unless exists $dir{$x_or_y//'<undef>'};
    my $i = $dir{$x_or_y};

    # make sure t0 and t1 are defined, defaulting to 0..1
    $t0 //= 0;
    $t1 //= 1;
    ($t0,$t1) = ($t1,$t0)   if($t0 > $t1); # swap if out of order

    # these are the ad=(3a), bd=(2b), cd=(1c) relative to the a,b,c from dBdt, above
    #   note that a,b,c are _vectors_ still, because {pN} are vectors
    my $a = -3*$self->{p0} + 9*$self->{p1} -9*$self->{p2} +3*$self->{p3};
    my $b = +6*$self->{p0} -12*$self->{p1} +6*$self->{p2};
    my $c = -3*$self->{p0} + 3*$self->{p1};

    # solving for a*t^2 + b*t + c = 0 will give the t values for local minima/maxima
    my $bb4ac = ($b->[$i])*($b->[$i]) - 4*($a->[$i])*($c->[$i]);
    croak "b²-4ac<0, so t is unreal" if $bb4ac<0;
    my $tp = (-($b->[$i]) + sqrt($bb4ac)) / (2*($a->[$i]));
    my $tm = (-($b->[$i]) - sqrt($bb4ac)) / (2*($a->[$i]));

    # x or y value for B(t) for the four different t values
    my $B0 = $self->B($t0)->[$i];
    my $B1 = $self->B($t1)->[$i];
    my $Bm = $self->B($tm)->[$i];
    my $Bp = $self->B($tp)->[$i];

    my $t = $tp;
    if( $h{$min_or_max} == $h{max} ) {  # max value
        $t = $tm if $Bm > $Bp;
        if($t0 > $t or $t > $t1) {
            $t = ($B1 > $B0) ? $t1 : $t0;
        }
    } else {                            # min value
        $t = $tm if $Bm < $Bp;
        if($t0 > $t or $t > $t1) {
            $t = ($B1 < $B0) ? $t1 : $t0;
        }
    }
    return $t;

}

# partials with respect to control-points
sub dBdp0 { my ($self, $t) = @_;    return 1 * (1-$t)**3 *  1;      }
sub dBdp1 { my ($self, $t) = @_;    return 3 * (1-$t)**2 * $t;      }
sub dBdp2 { my ($self, $t) = @_;    return 3 * (1-$t)    * $t**2;   }
sub dBdp3 { my ($self, $t) = @_;    return 1             * $t**3;   }

our $DEBUG_CLOSEST = 0;
# computes the t in the curve that gets closest to the given point
#   No closed form, so just binary-search between t=0 and t=1
#   Returns ($t time, $dsq square dist, $V vector)
sub old_closestToPoint {
    my ($self, $pt) = @_;
    my ($t0,$t1,$t) = (0,1);
    my $V = $self->B($t0);
    my $dsq0 = $V->dist2($pt);
    printf STDERR "dbg: B(0=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", $t0, @$V, $dsq0   if $DEBUG_CLOSEST;
    return ($t0, $dsq0, $V) if !$dsq0;  # found it exactly if distance is 0
    $V = $self->B($t1);
    my $dsq1 = $V->dist2($pt);
    printf STDERR "dbg: B(1=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", $t1, @$V, $dsq1   if $DEBUG_CLOSEST;
    return ($t1, $dsq1, $V) if !$dsq1;  # found it exactly if distance is 0
    my $dsq = $dsq1;
    for(1..10) {
        $t = ($t0 + $t1)/2;
        $V = $self->B($t);
        $dsq = $V->dist2($pt);
        printf STDERR "dbg: B(1=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f vs %.6f...%.6f\n", $t, @$V, $dsq, $dsq0, $dsq1 if $DEBUG_CLOSEST;
        return ($t, $dsq, $V) if !$dsq; # found it exactly if distance is 0

        if($dsq0 <= $dsq1) {
            # start is closer than end, so go from start to new
            $dsq1 = $dsq;
            $t1 = $t;
        } else {
            # start is farther than end, so go from new to end
            $dsq0 = $dsq;
            $t0 = $t;
        }
        printf STDERR "\tNEXT t range:%+9.6f...%+9.6f\n", $t0, $t1 if $DEBUG_CLOSEST;
    }
    # in the end, return the closest of the three points
    return ($t0, $dsq0, $self->B($t0)) if $dsq0 < $dsq and $dsq0 < $dsq1;
    return ($t1, $dsq1, $self->B($t1)) if $dsq1 < $dsq;
    return ($t, $dsq, $V);
}

# computes the t in the curve that gets closest to the given point
#   No closed form, and binary search doesn't work on distance
#   try to use Newton's method (t{n+1}=t{n} - f(t{n})/f'(t{n}) to come close.
#   Since the dist2 doesn't go to 0, and what I'm really looking for is the
#   _slope_ of dist2 going to 0, which will always happen (or it will hit an edge)
#   in which case, f=slope(dist2(t)), and df(t)/dt will be how that changes near t
sub newt_closestToPoint {
    my ($self, $pt) = @_;
    my ($t0,$t1) = (0,1);
    my $t = ($t0 + $t1)/2;
    my $V = $self->B($t0);
    my $dsq0 = $V->dist2($pt);
    printf STDERR "dbg: B(0=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", $t0, @$V, $dsq0   if $DEBUG_CLOSEST;
    return ($t0, $dsq0, $V) if !$dsq0;  # found it exactly if distance is 0
    $V = $self->B($t1);
    my $dsq1 = $V->dist2($pt);
    printf STDERR "dbg: B(1=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", $t1, @$V, $dsq1   if $DEBUG_CLOSEST;
    return ($t1, $dsq1, $V) if !$dsq1;  # found it exactly if distance is 0
    my $dsq = $dsq1;
    my $m = 0.1;
    for(1..25) {
        $V = $self->B($t);
        $dsq = $V->dist2($pt);
        printf STDERR "dbg: B(1=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f vs %.6f...%.6f\n", $t, @$V, $dsq, $dsq0, $dsq1 if $DEBUG_CLOSEST;
        return ($t, $dsq, $V) if !$dsq; # found it exactly if distance is 0

        # newton's method needs a slope; since I don't have an easy formula for dist2
        #   it's simplest to just take a couple points near the current, and use the
        #   secant of those two as the tangent of the center
        my $tm = ($t<=0.01) ? $t0 : 0.999*$t;
        my $dsqm = $self->B($tm)->dist2($pt);
        my $tp = ($t>=0.99) ? $t1 : 1.001*$t;
        my $dsqp = $self->B($tp)->dist2($pt);

        # approximate the main F = secant@t using F(tp)-F(tm);
        my $F = ($dsqp - $dsqm) / ($tp - $tm);

        # approximate the dF between secant@tm (F(t)-F(tm)) and secant@tp (F(tp)-F(t))
        my $Fm = ($dsq - $dsqm) / ($t - $tm);
        my $Fp = ($dsqp - $dsq) / ($tp - $t);
        my $dFdt = ($Fp-$Fm)/($t ? $tp-$tm : 0.01);
        printf STDERR "\tsecants: %+9.6f...%+9.6f...%+9.6f => dF/dt=%+9.6f\n", $Fm,$F,$Fp,$dFdt if $DEBUG_CLOSEST;
        my $delta_t = $dFdt ? $m * $F / $dFdt : 0;          # F/F', with scaling to limit overshoot
        if($t-$delta_t < 0) { $delta_t = 0.99*$t; }         # don't go negative
        if($t-$delta_t > 1) { $delta_t = 0.99*($t - 1); }   # or above 1

        # new t
        $t -= $delta_t;
        printf STDERR "\titer %d: t -= %+9.6f => %+9.6f\n", $_, $delta_t, $t if $DEBUG_CLOSEST;
        my $dsqnew = $self->B($t)->dist2($pt);
        #if ($dsqnew > $dsq) { $m *= 0.5; }  # smaller steps every time I increase
        last if abs($delta_t)<1e-6;
    }

    # in the end, return the closest of the three points
    return ($t0, $dsq0, $self->B($t0)) if $dsq0 < $dsq and $dsq0 < $dsq1;
    return ($t1, $dsq1, $self->B($t1)) if $dsq1 < $dsq;
    return ($t, $dsq, $V);
}

# computes the t in the curve that gets closest to the given point
#   No closed form, and binary search doesn't work on distance
#   Newton's method didn't converge well
#   Trying an iterative sampling approach
sub closestToPoint {
    my ($self, $pt) = @_;
    my ($t0,$t1,$t) = (0,1);
    my $V = $self->B($t0);
    my $dsq0 = $V->dist2($pt);
    printf STDERR "dbg: B(0=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", $t0, @$V, $dsq0   if $DEBUG_CLOSEST;
    return ($t0, $dsq0, $V) if !$dsq0;  # found it exactly if distance is 0
    $V = $self->B($t1);
    my $dsq1 = $V->dist2($pt);
    printf STDERR "dbg: B(1=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", $t1, @$V, $dsq1   if $DEBUG_CLOSEST;
    return ($t1, $dsq1, $V) if !$dsq1;  # found it exactly if distance is 0
    my $dsq = $dsq1;
    my $m = 0.1;

    my ($tleft, $tright) = ($t0,$t1);
    for my $il (0..7) {     # 8 loops
        my @keep = (undef,0+'Inf',undef,undef);
        for my $ip (0..5) { # 6 points per loop => 48 points
            my $tt = $tleft + ($ip)/5*($tright-$tleft);
            $V = $self->B($tt);
            $dsq = $V->dist2($pt);
            printf STDERR "dbg[%d,%d]: B(1=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f\n", $il,$ip,$tt, @$V, $dsq if $DEBUG_CLOSEST;
            return ($tt, $dsq, $V) if !$dsq; # found it exactly if distance is 0
            if($dsq < $keep[1]) {   # if this is the lowest for this loop, keep it
                @keep = ($tt, $dsq, $V, $ip);
            }
        }
        my $tlnew = $tleft + ( ($keep[3]>0) ? $keep[3]-1 : $keep[3] )/5*($tright-$tleft);
        my $trnew = $tleft + ( ($keep[3]<5) ? $keep[3]+1 : $keep[3] )/5*($tright-$tleft);
        ($tleft,$tright) = ($tlnew,$trnew);
        ($t, $dsq, $V) = @keep;
        printf STDERR "dbg[%d,-]: B(1=%+9.6f) = [%+9.6f,%+9.6f] => dsq:%.6f, new rng=%+9.6f...%+9.6f \n", $il,$t, @$V, $dsq, $tlnew, $trnew if $DEBUG_CLOSEST;
    }

    # in the end, return the closest of the three points
    return ($t0, $dsq0, $self->B($t0)) if $dsq0 < $dsq and $dsq0 < $dsq1;
    return ($t1, $dsq1, $self->B($t1)) if $dsq1 < $dsq;
    return ($t, $dsq, $V);
}

# returns a new bezier that rotates the source bezier control points by ccw $angle about some $center
sub rotate {
    my ($source, $angle, $center) = @_;
    my %new;
    for my $pN ( qw/p0 p1 p2 p3/ ) {
        $new{$pN} = $center->rotate_2d( $angle, $source->{$pN} );
        #printf "DEBUG: angle:%s center:%s new{%s}:%s\n", $angle, $center, $pN, $new{$pN};
    }
    return CubicBezier(@new{qw/p0 p1 p2 p3/});
}

1;
