package Math::Vector::Real::Bezier::Cubic;
use 5.014; # strict, //, s//r
use warnings;
use Carp qw/carp croak/;
use Exporter 5.57 'import';
our @EXPORT = qw/CubicBezier/;

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

# computes the t in the curve that gets closest to the given point
#   No closed form, so just binary-search between t=0 and t=1
#   Returns ($t time, $dsq square dist, $V vector)
sub closestToPoint {
    my ($self, $pt) = @_;
    my ($t0,$t1,$t) = (0,1);
    my $V = $self->B($t0);
    my $dsq0 = $V->dist2($pt);
    #printf STDERR "dbg: B(0=%+6.3f) = [%+6.3f,%+6.3f] => dsq:%.3f\n", $t0, @$V, $dsq0;
    return ($t0, $dsq0, $V) if !$dsq0;  # found it exactly if distance is 0
    $V = $self->B($t1);
    my $dsq1 = $V->dist2($pt);
    #printf STDERR "dbg: B(1=%+6.3f) = [%+6.3f,%+6.3f] => dsq:%.3f\n", $t1, @$V, $dsq1;
    return ($t1, $dsq1, $V) if !$dsq1;  # found it exactly if distance is 0
    my $dsq = $dsq1;
    for(1..10) {
        $t = ($t0 + $t1)/2;
        $V = $self->B($t);
        $dsq = $V->dist2($pt);
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
    }
    return ($t, $dsq, $V);
}

__PACKAGE__;
