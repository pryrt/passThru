#!perl
#   #SoME2: rectangular maze: https://www.youtube.com/watch?v=d5yzKkG1n1U
#   which pointed to https://github.com/emadehsan/maze/
#   There are also other videos by the same author
#   Since GD::Simple comes with Turtle graphics, I should be able to replicate.

use 5.012; # //, strict, say
use warnings;
use lib './lib';
use Maze::Rectangle;

my $rectMaze = Maze::Rectangle::->new(n => 21, sideLen => 25);
#$rectMaze->dbg_square;
#$rectMaze->dbg_grid;
$rectMaze->generate_maze();
$rectMaze->save('rect.png');
