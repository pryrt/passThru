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
    $self->append_star($fnV->(  2, 17,  0), name => 'Alden');
    $self->append_star($fnV->(  3,  7, -2), name => 'Beku');
    $self->append_star($fnV->(  7,  1,  1), name => 'Cang');
    $self->append_star($fnV->(  9,  9, -1), name => 'Dyor');
    $self->append_star($fnV->( 15,  3,  4), name => 'Etos');
    $self->append_star($fnV->( 13, 13,  2), name => 'Filbin');
    $self->append_star($fnV->( -3, 18, -1), name => 'Gynor');
    $self->append_star($fnV->( -1, 13, -3), name => 'Holrax');
    $self->append_star($fnV->( -4,  6,  3), name => 'Iyx');
    $self->append_star($fnV->(-12, 14, -2), name => 'Jorr');
    $self->append_star($fnV->(-11,  5,  2), name => 'Klixor');
    $self->append_star($fnV->(-16,  2,  4), name => 'Lyman');
    $self->append_star($fnV->( -5, -1,  0), name => 'Mida');
    $self->append_star($fnV->( -1, -9, -1), name => 'Nedrik');
    $self->append_star($fnV->( -4,-15,  3), name => 'Obdat');
    $self->append_star($fnV->(-12, -3,  3), name => 'Ploon');
    $self->append_star($fnV->(-10,-10,  2), name => 'Quinlix');
    $self->append_star($fnV->(-14, -7, -3), name => 'Redlan');
    $self->append_star($fnV->(  3, -4, -3), name => 'Solex');
    $self->append_star($fnV->(  5,-10, -4), name => 'Thil');
    $self->append_star($fnV->(  3,-15,  2), name => 'Urdon');
    $self->append_star($fnV->( 10, -3,  3), name => "V'indil");
    $self->append_star($fnV->( 11,-11, -2), name => 'Wari');
    $self->append_star($fnV->( 16, -6,  0), name => 'Xeno');
    $self->append_star($fnV->(  0,  0,  0), name => 'Ylem');
    return $self;
}

sub new {
    my ($class) = @_;

    my $self = bless {
        _stars => [],
        _nextAutoName => 'A',
        _name_to_star => {}
    }, $class;
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

sub get_star_named {
    my ($self, $name) = @_;
    croak "No star named '$name'" unless exists $self->{_name_to_star}{$name};
    return $self->{_name_to_star}{$name};
}

1;
