#!perl
use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";   # ToyNN
use lib "${FindBin::Bin}/../../lib";   # App::NonogramGameEngine
use PDL;
use ToyNN::PerceptronNetwork;
use App::NonogramGameEngine;
use Time::HiRes qw/time/;
use Data::Dump;
$| = 1;

my $w = 5;
my $nHints = int($w/2)+1;
my $nIn = $w*$nHints*2;  # $w rows/columns of the game, with up to nHints per row/column, two directions
my $nOut = $w*$w;
# no clue how many hidden layers or how many neurons per hidden layer; for now, guess 1 layer with more nodes than inputs or outputs
my $nHid = $nIn + $nOut;

sub make_games {
    my ($max) = @_;
    my $X = PDL->null;
    my $T = PDL->null;

    for (1 .. $max) {
        my $game = App::NonogramGameEngine->createRandomBoard($w,$w);
        my @x;
        for my $r ( 0 .. $w-1 ) {
            my @hints = (@{ $game->{hHints}[$r] }, (0) x $nHints);
            $#hints = $nHints-1;
            push @x, @hints;
        }
        for my $c ( 0 .. $w-1 ) {
            my @hints = (@{ $game->{hHints}[$c] }, (0) x $nHints);
            $#hints = $nHints-1;
            push @x, @hints;
        }
        $X = $X->append( pdl(@x)->transpose()/$w ); # scaled to bring inputs into the +/-1 range
        my @t;
        my %m = ( '*' => 1, ' ' => 0);
        for my $r ( 0 .. $w-1 ) {
            for my $c ( 0 .. $w-1 ) {
                push @t, map { $m{$_} } substr $game->{board}[$r], $c, 1;
            }
        }
        $T = $T->append( pdl(@t)->transpose());
    }
    #dd { Xt => \@aXt, Tt => \@aTt };
    return $X,$T;
}

my ($X,$T) = make_games(10);
my $network = ToyNN::PerceptronNetwork::->new($nIn, $nHid, $nOut);
my $ll = $network->lastLayerIndex;
my $Q = $network->feedforward($X);
my $perLoop = 10;
my $cnt = 0;
my $t0 = time;
printf "%-12.1f SSE(%06d) => %6.3f\n", (time-$t0), $cnt * $perLoop, $network->L($ll)->oSSE($Q, $T);
for $cnt ( 1 .. 100 ) {
    $network->backpropagate($X, $T) for 1..$perLoop;
    $Q = $network->feedforward($X);

    printf "%-12.1f SSE(%06d) => %6.3f, max|err| = %6.3f\n", (time-$t0), $cnt * $perLoop, $network->L($ll)->oSSE($Q, $T), my $maxerr = ($T - $Q)->abs()->max();
    last if $maxerr < 0.1;
}

my ($Xtest, $Ttest) = make_games(10);
$Q = $network->feedforward($Xtest);
printf "%-12.1f SSE(%6.6s) => %6.3f, max|err| = %6.3f\n", (time-$t0), 'test', $network->L($ll)->oSSE($Q, $Ttest), my $maxerr = ($Ttest - $Q)->abs()->max();


__END__
