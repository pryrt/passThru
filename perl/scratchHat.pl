#!perl

use 5.014; # strict, //, s//r
use warnings;

=begin TextBackground

in one of the #SOME3 video submissions, there was a guy who made "quantum computing" in the Scratch programming language,
by implementing a storage unit that stored the amplitudes for True and False for a given qubit, using a Hadamard Transformation
to provide the quantumness -- he called the block "Hadamard All the Things", or "HAT" (hence "scratchHat.pl")

=cut

use FindBin;
use lib $FindBin::Bin . '/lib';
use Math::ScratchHAT;

my $system = Math::ScratchHAT::->new();
$system->addQubit('m1');
$system->addQubit('m1');
use Data::Dump;
dd $system;