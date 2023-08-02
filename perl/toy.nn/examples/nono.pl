#!perl
use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";   # ToyNN
use lib "${FindBin::Bin}/../../lib";   # App::NonogramGameEngine
use PDL;
use ToyNN::PerceptronNetwork;
use App::NonogramGameEngine;
use Data::Dump;
$| = 1;

my $w = 5;
my $nHints = int($w/2)+1;
my $nIn = $w*$nHints*2;  # $w rows/columns of the game, with up to nHints per row/column, two directions
my $nOut = $w*$w;
# no clue how many hidden layers or how many neurons per hidden layer; for now, guess 1 layer with more nodes than inputs or outputs
my $nHid = $nIn + $nOut;

my (@aXt, @aTt);  # input and target AoA (will create $X and $T PDLs from their transposes
for (1 .. 5) {
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
    push @aXt, \@x;
    my @t;
    my %m = ( '*' => 1, ' ' => 0);
    for my $r ( 0 .. $w-1 ) {
        for my $c ( 0 .. $w-1 ) {
            push @t, map { $m{$_} } substr $game->{board}[$r], $c, 1;
        }
    }
    push @aTt, \@t;
}
#dd { Xt => \@aXt, Tt => \@aTt };

my $network = ToyNN::PerceptronNetwork::->new($nIn, $nHid, $nOut);
my $ll = $network->lastLayerIndex;
print "X => ", my $X = pdl(\@aXt)->transpose / $w;
print "T => ", my $T = pdl(\@aTt)->transpose;
print "Q => ", my $Q = $network->feedforward($X);
print "SSE => ", $network->L($ll)->oSSE($Q, $T), "\n";
print "W => ", $network->L($ll)->weights;
print "B => ", $network->L($ll)->biases;
<STDIN>;
$network->backpropagate($X, $T);
print "Q2 => ", $Q = $network->feedforward($X);
print "SSE2 => ", $network->L($ll)->oSSE($Q, $T), "\n";
print "W2 => ", $network->L($ll)->weights;
print "B2 => ", $network->L($ll)->biases;

__END__
