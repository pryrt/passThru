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
    __PACKAGE__->new(@_);
}

sub new {
    my ($class, $x,$y,$z, %opts) = @_;
    if(!defined $x) {
        $x = $fnV->( int -16+32*rand(), int -16+32*rand(), int -4+8*rand() );
    } elsif (!ref $x and defined $y and defined $z) {
        $x = $fnV->( $x, $y, $z );
        undef $y;
        undef $z;
    } elsif (!Scalar::Util::blessed($x) and UNIVERSAL::isa($x,'ARRAY')) {
        $x = $fnV->(@$x);
    } elsif (!Scalar::Util::blessed($x) or !$x->isa('Math::Vector::Real')) {
        croak __PACKAGE__ . "::new(): must be given nothing, or x,y,z, or a Math::Vector::Real object, but you gave me $x";
    }

    unless(3 == scalar @$x) {
        croak __PACKAGE__ . "::new(): initial position must be three-dimensional: $x";
    }

    if(defined $y and defined $z) {
        $opts{$y} = $z;
    }

    my %attribs = (
        _name => undef,
        _planets => undef,
        _ic => undef,
        _discovered => undef,
        _owner => undef,
        _stockpile => undef,
    );

    for my $k (sort keys %opts) {
        my $a = "_" . $k;
        if( exists $attribs{$a} ) {
            $attribs{$a} = $opts{$k};
        } else {
            croak __PACKAGE__ . "::new(): unknown attribute $k => $opts{$k}";
        }
    }

    my $self = bless { _pos => $x , %attribs }, $class;
    $self;
}

sub position {
    my ($self) = @_;
    $self->{_pos};
}

sub name {
    my ($self, $newname) = @_;
    $self->{_name} = $newname if defined $newname;
    $self->{_name};
}

sub make_home {
    my ($self, $owner) = @_;
    for my $attrib (qw/_planets _ic _discovered/) {
        croak sprintf "%s Already discovered", $self->name() if defined $self->{$attrib};
    }
    $self->{_planets} = 5;
    $self->{_ic} = 1;
    $self->{_discovered} = 1;
    $self->{_stockpile} = 0;
    $self->{_owner} = $owner;
    $self;
}

sub discover {
    my ($self, $owner) = @_;
    for my $attrib (qw/_planets _ic _discovered/) {
        croak sprintf "%s Already discovered", $self->name() if defined $self->{$attrib};
    }
    $self->{_planets} = 1 + int rand 5; # 1..5 planets
    $self->{_ic} = (int rand 6 > 4) ? 1 : 0;
    $self->{_discovered} = 1;
    $self->{_stockpile} = 0;
    $self->{_owner} = $owner if defined $owner;
    $self;
}

sub discovered {
    my ($self) = @_;
    $self->{_discovered};
}

sub is_ic {
    my ($self) = @_;
    $self->discovered ? $self->{_ic} : undef;
}

sub has_planets {
    my ($self) = @_;
    $self->discovered ? $self->{_planets} : undef;
}

sub capacity {
    my ($self) = @_;
    $self->discovered ? 2*$self->{_planets} : undef;
}

sub controlled_by {
    my ($self) = @_;
    $self->discovered ? $self->{_owner} : undef;
}

sub stockpile {
    my ($self) = @_;
    $self->discovered ? $self->{_stockpile} : undef;
}

sub add_minerals {
    my ($self, $added) = @_;
    return undef unless $self->discovered;
    croak sprintf "%s->add_minerals(%d): Cannot add negative minerals; use \$self->remove_minerals instead", $self->name, $added if $added < 0;
    my $total = $self->stockpile + $added;
    if($total > $self->capacity) {
        croak sprintf "%s->add_minerals(%d): Would result in %d minerals, which is more than capacity of %s minerals in the system", $self->name, $added, $total, $self->capacity;
    }
    $self->{_stockpile} = $total;
}

sub remove_minerals {
    my ($self, $removed) = @_;
    return undef unless $self->discovered;
    croak sprintf "%s->remove_minerals(%d): Cannot remove negative minerals; use \$self->add_minerals instead", $self->name, $removed if $removed < 0;
    my $total = $self->stockpile - $removed;
    if($total < 0) {
        croak sprintf "%s->remove_minerals(%d): There are only %d minerals to remove in the system, so cannot remove that many!", $self->name, $removed, $self->stockpile;
    }
    $self->{_stockpile} = $total;
}

1;
