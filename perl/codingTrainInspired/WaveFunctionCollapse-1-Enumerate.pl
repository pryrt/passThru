#!perl

use 5.014; # strict, //, s//r
use warnings;
use autodie;
use FindBin;
use lib "${FindBin::Bin}/lib";
# use GD ();
use GDP5;
use Carp::Always;

GDP5::Run('WaveFunctionCollapse1');

sub setup {
    createCanvas(100,100);
    print STDERR "inside sketch's setup() function\n";
}

sub draw {
    GDP5::background(255,255,255);
    printf STDERR "blue = %s\n", my $blue = gd->colorResolve(0,0,rand 255);
    gd->filledEllipse(25 + rand 50,25 + rand 50,25,25,$blue);
    GDP5::noLoop() if 1/32 > rand();
}

=encoding utf8

=head1 INTRODUCTION

In the CodingTrain:WaveFunctionCollapse video, there were three distinct sections:

=over

=item 1. Simple version where he just enumerated all the possible connections

=item 2. Improved version where he was able to auto-generate the possible connections based on a single-index descrption on the side

=item 3. Fancy version with length-3 descriptions to be able to align asymmetric sides

=back

This will be version 1: simple

=head1 STARTING FROM MEMORY

My notes from the video aren't here right now, so I'm starting from memory.  Depending on how far I get, and how poorly my memory matches my notes, I may have significant rework at some point.

=cut
