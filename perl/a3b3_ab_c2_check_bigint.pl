#!perl

use 5.014; # //, strict, say, s///r
use warnings;
use Math::BigInt lib => 'GMP';
use Math::BigRat lib => 'GMP';

# 275095828218, 5162
for my $pair ( ['2','1'], ['-10', '6'], ['13','11'], ['-814', '517'], ['214367','6721'], ['83804', '39900']) {
    my ($sa,$sb) = @$pair;
    my $a = Math::BigRat->new($sa);
    my $b = Math::BigRat->new($sb);
    my $ratio = ($a**3 + $b**3) / ($a - $b);
    my $c = sqrt($ratio);
    my $csq = $c**2;
    my $rf = $a / $b;
    printf "(a,b,c) = (%s,%s,%s) f=%s: ratio=%s vs c**2=%s => %s\n", $a, $b, $c, $rf, $ratio, $csq, ($ratio==$csq) ? 'EQ' : 'FAIL';
}
