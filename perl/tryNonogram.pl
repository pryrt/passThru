#!perl
use 5.014; # strict, //, s//r
use warnings;

use FindBin;
use lib "${FindBin::Bin}/lib"; # to find App::NonagramGameEngine

use App::NonogramGameEngine;
use Data::Dump;

my $game = App::NonogramGameEngine->createRandomBoard(15,15); # App::NonogramGameEngine->new(5,5);
$game->debug_printBoard();
# dd {%$game};
