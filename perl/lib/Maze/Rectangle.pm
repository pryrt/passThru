package Maze::Rectangle 1.000000;
# https://github.com/emadehsan/maze/blob/main/src/rectangular.py
use 5.012; # //, strict, say
use warnings;
use autodie;
use GD::Simple;

sub n { $_[0]->{n} }
sub sideLen { $_[0]->{sideLen} }
sub turtle { $_[0]->{gd} }

sub GD::Simple::right
{
    my ($self, $deg) = @_;
    $self->angle( $self->angle() + $deg);
    while( 360 <= (my $a = $self->angle()) ) {
        $self->angle($a - 360);
    }
    while( 0 > (my $a = $self->angle()) ) {
        $self->angle($a + 360);
    }
    return $self->angle();
}

sub GD::Simple::left
{
    my ($self, $deg) = @_;
    $self->angle( $self->angle() - $deg);
    while( 360 <= (my $a = $self->angle()) ) {
        $self->angle($a - 360);
    }
    while( 0 > (my $a = $self->angle()) ) {
        $self->angle($a + 360);
    }
    return $self->angle();
}

sub new
{
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{n} = (exists $args{n}) ? $args{n} : 5;
    $self->{sideLen} = (exists $args{sideLen}) ? $args{sideLen} : 20;
    $self->{gd} = GD::Simple::->new(800,800);
    for my $t ($self->turtle) {
        $t->bgcolor('white');
        $t->fgcolor('darkgray');
        $t->rectangle(400,400,400,400); # a dot at the center of the screen, for reference
        $t->fgcolor('black');
        $t->moveTo(400,400);    # start at the center
        $t->angle(0);
    }
    return $self;
}

sub save
{
    my ($self, $fname) = @_;

    open my $fh, '>:raw', $fname;
    print {$fh} $self->{gd}->png();
    close $fh;
    system(1,$fname);
    return $self;
}

sub dbg_square
{
    my ($self) = @_;
    my $side = $self->sideLen * 5;
    my $dx = - $side / 2;
    my $dy = - $side / 2;
    $self->turtle->move($dx,$dy);
    for(1..4) {
        $self->turtle->line($side);
        $self->turtle->right(90);
    }
    return $self;
}

sub dbg_grid
{
    my ($self) = @_;
    my $dx = - ($self->sideLen * $self->n) / 2;
    my $dy = $dx;
    my $d  = $self->sideLen;
    my $n1 = $self->n - 1;

    for my $t ($self->turtle) {
        my ($x0,$y0) = $t->curPos();
        $t->moveTo($x0+$dx,$y0+$dy);
        for my $row ( 0 .. $n1 ) {
            for my $col ( 0 .. $n1 ) {
                for(1..4) {
                    $t->line($d);
                    $t->right(90);
                }
                $t->move($d);
            }
            $dy += $self->sideLen;
            $t->moveTo($x0+$dx,$y0+$dy);
        }
    }
}

1;
