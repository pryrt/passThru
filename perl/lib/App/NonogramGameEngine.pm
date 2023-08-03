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

__END__

Originally planning on using this with ToyNN, but that doesn't seem to be able to train in a reasonable amount of time.
I would have thought it would be a pretty linear combination of cell(0,0) = LinCombo(rHints[0], cHints[0]), but even
with three hidden layers, I couldn't do it.

However, I found the following description of the brute-force algorithm with python implementation.
    https://towardsdatascience.com/solving-nonograms-with-120-lines-of-code-a7c6e0f627e4
I accept their claim that you can reduce it down to the same as if all the blocks of 1s were just width one,
but with a shorter row.
    a = count of groups of ones = length(@input)
    z = total zeroes = length(row) - sum(@input)
And I think I accept that because there has to be at least a single zero between each, you can do the
number of zeroes minus the number of required gaps (which is one less than the number of blocks) as the count
of zeroes that you need to actually find the combinations for
    g = required gaps = a - 1
    c = zeroes to place = z - g
But they say that there are nCr combos.  I agree with their enumeration in that example,
but their explanation to get the n and r for nCr is too handwavy for me:
    in their example, there are a=3 groups (6,2,3), and z=15-sum(6,2,3)=15-11=4
    so g=a-1=3-1=2, and yes, there need to be two gaps between
    and c = z - g = 4 - 2 = 2.
    but they say n=3+2 -- I think they mean the a=3 groups and c=2, but it's confusing because both c and g are 2
    and r=3... but we aren't changing the order of those three.
    And there are really 7 spots to fill
    Hmm, well, really, the first a-1 groups can be considered as consisting of hte group of 1s _plus_ the gap 0
    ... so then there are only 5 slots to fill
        [1111110][110][111][0][0] = ooozz
    for purposes of this, then, 5-choose-3 (pick the 3 locations of the o groups) or 5-choose-2 (pick the 2 locations of the z elements)
    both do make sense.
    Okay, I'm understanding it now... it's just harder to understand when they say n=5 but their drawing has 7 locations.
    So in their 5-choose-3, they are choosing the starting point for the three groups of 1s
    They could have just as easily done 5-choose-2 to list just the indexes for the non-fixed gaps, instead
So with that, look back over my suite of three combinatoric modules that I use
    Algorithm::Permute = only does permutations, not combinations
    Math::Combinatorics = pure perl; has iterator or permute/combine/derange all-at-once functions
    Algorithm::Combinatorics = XS; has iterator or all-at-once functions

It would seem to me that there would be too many combinations when taking the drawing as a whole to do it brute force,
but that article (and a couple other google summaries) seem to indicate that up to 100x100, it's quite doable.
