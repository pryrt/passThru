package App::StarLord::Star;
use 5.014; # strict, //, s//r
use warnings;
use Carp qw/carp croak/;
use Exporter 5.57 'import';
use Math::Vector::Real ();
use Scalar::Util ();
our @EXPORT_OK = qw/CreateStar/;
our @EXPORT = qw/CreateStar/;

my $fnV = \&Math::Vector::Real::V;

sub CreateStar {
    return __PACKAGE__->new(@_);
}

sub new {
    my ($class, $x,$y,$z, @extras) = @_;
    if(!defined $x) {
        $x = $fnV->( int -16+32*rand(), int -16+32*rand(), int -4+8*rand() );
    } elsif (!ref $x and defined $y and defined $z) {
        $x = $fnV->( $x, $y, $z, @extras );
    } elsif (!Scalar::Util::blessed($x) and UNIVERSAL::isa($x,'ARRAY')) {
        $x = $fnV->(@$x);
    } elsif (!Scalar::Util::blessed($x) or !$x->isa('Math::Vector::Real')) {
        croak __PACKAGE__ . "::new(): must be given nothing, or x,y,z, or a Math::Vector::Real object, but you gave me $x";
    }

    unless(3 == scalar @$x) {
        croak __PACKAGE__ . "::new(): initial position must be three-dimensional: $x";
    }

    my $self = bless { _pos => $x }, $class;
    return $self;
}

sub position {
    my ($self) = @_;
    return $self->{_pos};
}

1;
