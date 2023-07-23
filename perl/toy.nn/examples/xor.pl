#!perl -l

use 5.014; # //, strict, say, s///r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";
use PDL;
use ToyNN::PerceptronNetwork;
$| = 1;

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
print "calculate SSE from errors                        => ", my $eSSE = $layer->eSSE($target - $outN);
print "calculate SSE from outputs and targets           => ", my $oSSE = $layer->oSSE($outN, $target);
print "calculate SSE from inputs and targets            => ", my $iSSE = $layer->iSSE($xcols, $target);

$layer->backpropagate($inp1, $out1, $err1);
$outN = $layer->feedforward( $xcols ); # update outN based on new network
print "calculate SSE from errors                        => ",    $eSSE = $layer->eSSE($target - $outN);
print "calculate SSE from outputs and targets           => ",    $oSSE = $layer->oSSE($outN, $target);
print "calculate SSE from inputs and targets            => ",    $iSSE = $layer->iSSE($xcols, $target);

for(1..2) {
$layer->backpropagate($xcols, $outN, $target - $outN);
$outN = $layer->feedforward( $xcols ); # update outN based on new network
print "calculate SSE from errors                        => ",    $eSSE = $layer->eSSE($target - $outN);
print "calculate SSE from outputs and targets           => ",    $oSSE = $layer->oSSE($outN, $target);
print "calculate SSE from inputs and targets            => ",    $iSSE = $layer->iSSE($xcols, $target);
}
print "Final weights and biases => ", $layer->W, $layer->B;
print "element => ", $layer->{W}->at(1,1);
$layer->{W}->set(0,0,1);
$layer->W->slice(1,0) .= 1;
$layer->{W} .= 1;   # set all elements to 1
$layer->B->set(0,0,-1.5);
$layer->B->set(0,1,-0.5);
print "Final weights and biases => ", $layer->W, $layer->B;
print "updated outN => ",
$outN = $layer->feedforward( $xcols ); # update outN based on new network
print "calculate SSE from outputs and targets           => ",    $oSSE = $layer->oSSE($outN, $target);
