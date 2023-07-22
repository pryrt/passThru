#!perl -l

use 5.014; # //, strict, say, s///r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/../lib";
use PDL;
#use ToyNN::PerceptronNetwork;

thread_define('square(a();[o]b())', over { $_[1] .= $_[0] ** 2 });
my $pdl = pdl [[1,2,3], [4,5,6]];
square($pdl, (my $out = PDL->null));
print($out); # $out is pdl [[1,4,9], [16,25,36]]


# in matrix algebra, (1 row 3 col) x (3 row 1 col) would give a (1 row 1 col) result
# a lot of the features of PDL (including the function version of methods, and broadcast/thread_define) are broken when you try to fix matrixes using PDL::Matrix
#   so instead, I need to figure out how
print "row   => ", my $row = pdl(1,2,4);
print "col   => ", my $col = pdl(3,5,7)->transpose();
print "r x c => ", my $mrc = $row x $col;   # expected (1 row 1 col), got that
print "c x r => ", my $mcr = $col x $row;   # expected (3 row 3 col), got that
# so those actually work as expected, other than when it shows the _order_ of dimensions
print "row->dims: ", join ',', $row->dims;
print "col->dims: ", join ',', $col->dims;

my $w = pdl [[ 1.0 , 1.0 ],[ 1.0 , 1.0 ]];
my $b = pdl([ -1.5, -0.5 ])-> transpose;
my $xcols = pdl [[ 0, 0, 1, 1],[ 0, 1, 0, 1]];
print "manual xor = w * xcols + b => ",my $manual_xor = $w x $xcols + $b;

print "exp(M) => ", $manual_xor->exp();

thread_define('exponential(a();[o]b())', over { $_[1] .= exp($_[0]) });
exponential($manual_xor, ($out = PDL->null));
print "exponential(M) => ", $out;
