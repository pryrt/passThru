package App::StarLord::StarMap;
use 5.014; # strict, //, s//r
use warnings;
use Carp qw/carp croak/;
use Exporter 5.57 'import';
use App::StarLord::Star;
use Math::Vector::Real ();
use Scalar::Util ();
our @EXPORT_OK = qw/CreateDefaultStarMap CreatePoissonStarMap/;
our @EXPORT = qw/CreateDefaultStarMap CreatePoissonStarMap/;

my $fnV = \&Math::Vector::Real::V;

sub CreateDefaultStarMap {
    my $self = __PACKAGE__->new(@_);
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0));
    $self->append_star($fnV->(0,0,0), name => 'Ylem');
    return $self;
}

sub new {
    my ($class) = @_;

    my $self = bless { _stars => [], _nextAutoName => 'A', _name_to_star => {} }, $class;
    return $self;
}

sub count {
    my ($self) = @_;
    return scalar @{ $self->{_stars} };
}

sub append_star {
    my ($self) = shift;
    my $star = App::StarLord::Star::CreateStar(@_);
    my $name = $star->name();
    if(!defined $name) {
        $name = $star->name( $self->{_nextAutoName} );
        ++$self->{_nextAutoName};
    }
    $self->{_name_to_star}{$name} = $star;
    push @{$self->{_stars}}, $star;
    return $star;
}

1;
