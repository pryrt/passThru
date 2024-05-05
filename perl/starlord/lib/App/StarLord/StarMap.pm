package App::StarLord::StarMap;
use 5.014; # strict, //, s//r
use warnings;
use Carp qw/carp croak/;
use Exporter 5.57 'import';
use Math::Vector::Real ();
use Scalar::Util ();
our @EXPORT_OK = qw/CreateDefaultStarMap CreatePoissonStarMap/;
our @EXPORT = qw/CreateDefaultStarMap CreatePoissonStarMap/;

my $fnV = \&Math::Vector::Real::V;

sub CreateDefaultStarMap {
    my $self = __PACKAGE__->new(@_);
    return $self;
}

sub new {
    my ($class) = @_;

    my $self = bless { _stars => [], _nextAutoName => 'A' }, $class;
    return $self;
}

sub position {
    my ($self) = @_;
    return $self->{_pos};
}

1;
