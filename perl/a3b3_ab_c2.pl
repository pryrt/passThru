#!perl

use 5.014; # //, strict, say, s///r
use warnings;
use Math::BigRat lib => 'GMP';

## ratio (a³ + b³) / (a - b) = a² + ab + b² + 2b³ / (a - b)
## m = 2b³ / (a - b) => ratio = a² + ab + b² + m
##
##  1. pick b
##  2. @m = divisors(2b³)
##  3. for each m in @m, calculate a
##      => a = 2b³ ÷ m + b
##  4. for each (a,b) pair, add (a,b,c) to @results if ratio(a,b) is a perfect square

$| = 1;

my $t0 = time;

my %fractions = ();
for my $absb (10001 .. 100000) {
    my $two_b_cubed = 2 * ($absb**3);
    my @m = @{divisors($two_b_cubed)};
    for my $absm (@m) {
        # b and m can of either sign, so need to loop through those four conditions
        for (0..3) {
            my $b = (($_>1) ? -1 : 1) * $absb;
            my $m = (($_ % 2) ? -1 : 1) * $absm;

            # a = 2b³/m + b, but since 2b³/m is also one of the values from @m,
            #   that can be simplified to a = m + b, saving a division
            my $a = $m + $b;
            my $ratio = ($a**3 + $b**3) / ($a - $b);
            next if $ratio <= 0;
            my $c = sqrt($ratio);
            if( $c == int $c ) {
                # then it's a probably a perfect square (unless rounding issues)
                my $ra = Math::BigRat->new("$a");
                my $rb = Math::BigRat->new("$b");
                my $rf = $ra / $rb;
                next if exists $fractions{$rf};

                # check to make sure it's real
                my $rr = ($ra**3 + $rb**3) / ($ra - $rb);
                my $rc = sqrt($rr);
                my $rs = $rc**2;
                next if $rr != $rs;

                # print if it's real
                printf "(%s, %s, %s) => %s\n", $a, $b, $c, $rf;
                $fractions{$rf} = [$a,$b,$c];
            }
        }
    }
    printf "...%-7d t=%-7d per=%6.4f\n", $absb, (time()-$t0), (time()-$t0)/$absb if 0 == $absb % 500;
}

sub divisors {
    my($val) = @_;
    my $sqv = int sqrt $val;
    my @divisors = (1,$val);
    for my $div (2 .. $sqv) {
        push @divisors, ($div, $val/$div) if 0 == $val % $div;
    }
    \@divisors
}

__END__
(2, 1, 3) => 2
(-10, 6, 7) => -5/3
(13, 11, 42) => 13/11
(195, 168, 671) => 65/56
(-814, 517, 549) => -74/47
(214367, 6721, 217812) => 4561/143
(83804, 39900, 121871) => 2993/1425
