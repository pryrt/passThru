#!perl

use 5.014; # strict, //, s//r
use warnings;
use autodie;
use FindBin;
use lib "${FindBin::Bin}/lib";
use GD ();

our ($doLoop,$canvas, $animgif) = (1,undef,'');
END { if(length $animgif) { open my $fh, '>:raw', 'CodingTrain.gif'; print {$fh} $animgif; } }
preload();
setup();
while($doLoop) { draw(); }

exit;

sub preload { ; }
sub setup {
    1;
}
sub draw {
    ;
}
sub noLoop { $doLoop = 0; }

=encoding utf8

=head1 INTRODUCTION

This is a semi-template for CodingTrain style code...  It will hopefully improve over time. :-)

=cut
