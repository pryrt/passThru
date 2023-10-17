#!perl

use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "${FindBin::Bin}/lib";
use GDP5;

use Carp::Always;   # turn this on during debug...

GDP5::Run('ProjectNameHere');

sub setup {
    createCanvas(100,100);
    print STDERR "inside sketch's setup() function\n";
}

sub draw {
    GDP5::background(255,255,255);
    printf STDERR "blue = %s\n", my $blue = gd->colorResolve(0,0,rand 255);
    gd->filledEllipse(40 + rand 20,40 + rand 20,25,25,$blue);
    GDP5::noLoop() if 1/32 > rand();
}


=encoding utf8

=head1 INTRODUCTION

This is a semi-template for CodingTrain style code...  It will hopefully improve over time. :-)

=cut
