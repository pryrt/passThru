#!perl -l

use 5.014; # //, strict, say, s///r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";
use PDL;
use ToyNN::PerceptronNetwork;

# manual
my $w = pdl [[ 1.0 , 1.0 ],[ 1.0 , 1.0 ]];
my $b = pdl([ -1.5, -0.5 ])-> transpose;
my $xcols = pdl [[ 0, 0, 1, 1],[ 0, 1, 0, 1]];
my $manual = $w x $xcols + $b;

# define a target for the trained version
my $target = pdl [[0,0,0,1], [0,1,1,1]];

# debugging
use Data::Dump;
my $layer = ToyNN::PerceptronLayer::->new(2, 2);
# print "outN => ",
my $outN = $layer->feedforward( $xcols );    # all input data
# print "W    => ", $layer->W;
print "inp1 => ",
my $inp1 = $xcols->slice('3,:');             # third column only
print "out1 => ",
my $out1 = $layer->feedforward( $inp1 );
print "err1 => ",
my $err1 = $target->slice('3,:') - $out1;
$layer->backpropagate($inp1, $out1, $err1);
