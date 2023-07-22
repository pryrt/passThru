#!perl -l

use 5.014; # //, strict, say, s///r
use warnings;
use FindBin;
use PDL;

# in matrix algebra, (1 row 3 col) x (3 row 1 col) would give a (1 row 1 col) result
# a lot of the features of PDL (including the function version of methods, and broadcast/thread_define) are broken when you try to fix matrixes using PDL::Matrix
#   so instead, I need to figure out how
print "row   => ", my $row = pdl(1,2,4);
print "col   => ", my $col = pdl(3,5,7)->transpose();
print "r x c => ", my $mrc = $row x $col;   # expected (1 row 1 col), got that
print "c x r => ", my $mcr = $col x $row;   # expected (3 row 3 col), got that
# so those actually work as expected, other than when it shows the _order_ of dimensions; I guess it's not as evil as I remembered
print "row->dims: ", join ',', $row->dims;
print "col->dims: ", join ',', $col->dims;

# https://stackoverflow.com/questions/72589417/is-there-a-map-equivalent-for-pdl-without-doing-pdl-map-unpdl
# => broadcast_define (newer name) => thread_define (older name in strawberry 5.32 version of PDL)
# https://metacpan.org/release/CHM/PDL-2.019/view/Basic/Core/Core.pm#thread_define

thread_define('square(a();[o]b())', over { $_[1] .= $_[0] ** 2 });
my $pdl = pdl [[1,2,3], [4,5,6]];
square($pdl, (my $out = PDL->null));
print($out); # $out is pdl [[1,4,9], [16,25,36]]

