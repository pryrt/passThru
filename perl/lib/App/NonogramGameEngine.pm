package App::NonogramGameEngine;
use 5.014; # strict, //, s//r
use warnings;

our $VERSION = '0.001';



sub new {
    my ($class, $nRows, $nCols) = @_;
    my @board = ();
    for(1..$nRows) {
        push @board, '-'x$nCols;
    }
    my $self = bless {
        nRows => $nRows,
        nCols => $nCols,
        board => \@board,
        hHints => [],
        vHints => [],
    }, $class;
    return $self;
}

sub debug_printBoard
{
    my ($self) = @_;
    # in 5x5,   widest hint =  5: "1 1 1"
    # in 10x10, widest hint =  9: "1 1 1 1 1"
    # in 15x15, widest hint = 15: "1 1 1 1 1 1 1 1"
    my $hintwidth = $self->{nCols} + 1 - ( $self->{nCols} % 2);
    for my $r ( 0 .. $self->{nRows}-1 ) {
        my $hint = $self->{hHints}[$r] // '<>';
        my $str = $self->{board}[$r];
        printf "%*.*s: %s\n", $hintwidth, $hintwidth, join(' ', @$hint), $str;
    }
    printf "vHint: %s\n", join(' ', @$_) for @{$self->{vHints}};
}

sub createRandomBoard
{
    my ($class, $nRows, $nCols) = @_;
    my $self = $class->new($nRows, $nCols);
    for my $r ( 0 .. $self->{nRows}-1 ) {
        $self->{board}[$r] = join '', (' ','*')[map { int rand 2 } 1 .. $self->{nCols}];
    }
    $self->generateHintsFromBoard();
    return $self;
}

sub generateHintsFromBoard
{
    my ($self) = @_;
    my $b = $self->{board};
    # horizontal
    for my $r ( 0 .. $self->{nRows}-1 ) {
        my $count = 0;
        my @h;
        for my $c ( 0 .. $self->{nCols}-1 ) {
            if('*' eq substr $b->[$r], $c, 1 ) {
                $count++;
            } else {
                push @h, $count if $count;
                $count = 0;
            }
        }
        push @h, $count if $count;
        push @{ $self->{hHints}[$r] }, @h;
    }
    # vertical
    for my $c ( 0 .. $self->{nCols}-1 ) {
        my $count = 0;
        my @h;
        for my $r ( 0 .. $self->{nRows}-1 ) {
            if('*' eq substr $b->[$r], $c, 1 ) {
                $count++;
            } else {
                push @h, $count if $count;
                $count = 0;
            }
        }
        push @h, $count if $count;
        push @{ $self->{vHints}[$c] }, @h;
    }
}

1;
