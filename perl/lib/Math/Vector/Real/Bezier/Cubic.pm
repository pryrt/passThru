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

__PACKAGE__;
