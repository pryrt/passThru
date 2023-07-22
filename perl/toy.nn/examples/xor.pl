#!perl -l

use 5.014; # //, strict, say, s///r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";
use PDL;
use ToyNN::PerceptronNetwork;

my $w = pdl [[ 1.0 , 1.0 ],[ 1.0 , 1.0 ]];
my $b = pdl([ -1.5, -0.5 ])-> transpose;
my $xcols = pdl [[ 0, 0, 1, 1],[ 0, 1, 0, 1]];
#print "manual xor = w * xcols + b => ",my $manual_xor = $w x $xcols + $b;

# debugging
use Data::Dump;
my $layer = ToyNN::PerceptronLayer::->new(2, 2);
printf "%+5.1f => %+9.6f %+9.6f\n", $_, $layer->{fn}->($_), $layer->{df}->($_) for map {$_} -10 .. 10;exit;
#print "Layer.Bias    => ", $layer->B;
#print "Layer.Weights => ", $layer->W;
$layer->feedforward( $xcols->slice('3,:') );    # third column only
