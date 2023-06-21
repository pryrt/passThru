#!perl
# Near-miss Magic Square of Squares
#   See notes in END section

use 5.014; # strict, //, s//r
use warnings;
use Algorithm::Permute;
use Data::Dump qw/dd/;
$| = 1;

my %mid2set;    # save it as the mapping of the middle-root $M to each set of L,M,H that go with it.
my %done;       # use the LMH as the key
for my $p ( 2 .. 101 ) {
    for my $q ( 1 .. $p-1 ) {   # p > q, without loss of generality
        my $X = $p**2 - $q**2;
        my $Y = 2*$p*$q;
        my $Z = $p**2 + $q**2;
        for my $k ( 1 .. 21 ) {
            my $M = $k*$Z;
            my $L = $k*abs($X-$Y);
            my $H = $k*($X+$Y);
            my $str = join ';', $L, $M, $H;
            unless($done{$str}) {   # make sure each triple only goes into the mid2set once
                push @{ $mid2set{$M} }, [$L, $M, $H];
                $done{$str} = 1;
            }
        }
    }
}

#dd \%mid2set;

for my $M (sort {scalar(@{$mid2set{$b}}) <=> scalar(@{$mid2set{$a}}) || $b <=> $a}  grep { scalar( @{ $mid2set{$_} } ) >= 4 } keys %mid2set) {
    printf "M = %s, # = %d\n", $M, scalar(@{$mid2set{$M}});
    my $P = $M*$M;
    my $SUM = 3*$P;
    my $obj = Algorithm::Permute::->new($mid2set{$M}, 4);
    while (my @perm = $obj->next) {
        local $" = ",";
        # print "[@$_] " for @perm;
        # print "\n";
        for my $bin (0..15) {
            my @s = (
                ($bin>>0)&1 ? [reverse @{$perm[0]}] : $perm[0],   # $orders{$perm[0]}[($bin>>0)&1],
                ($bin>>1)&1 ? [reverse @{$perm[1]}] : $perm[1],   # $orders{$perm[1]}[($bin>>1)&1],
                ($bin>>2)&1 ? [reverse @{$perm[2]}] : $perm[2],   # $orders{$perm[2]}[($bin>>2)&1],
                ($bin>>3)&1 ? [reverse @{$perm[3]}] : $perm[3],   # $orders{$perm[3]}[($bin>>3)&1],
            );
            local $" = '.';
            # print "\t\t@$s0\n";
            # print "\t\t@$s1\n";
            # print "\t\t@$s2\n";
            # print "\t\t@$s3\n";

            # s0 is diagonal \          s00 s30 s12
            # s1 is diagonal /          s20 $P  s22
            # s2 is horizontal -        s10 s32 s02
            # s3 is vertical |

            my $d0 = $s[0][0]**2 + $s[0][1]**2 + $s[0][2]**2;   # diagonal \
            my $d1 = $s[1][0]**2 + $s[1][1]**2 + $s[1][2]**2;   # diagonal /
            my $r0 = $s[0][0]**2 + $s[3][0]**2 + $s[1][2]**2;
            my $r1 = $s[2][0]**2 + $s[3][1]**2 + $s[2][2]**2;
            my $r2 = $s[1][0]**2 + $s[3][2]**2 + $s[0][2]**2;
            my $c0 = $s[0][0]**2 + $s[2][0]**2 + $s[1][0]**2;
            my $c1 = $s[3][0]**2 + $s[3][1]**2 + $s[3][2]**2;
            my $c2 = $s[1][2]**2 + $s[2][2]**2 + $s[0][2]**2;

            # are any of the non-primaries the right mag?
            my $any = "";
            for my $onesum ($r0, $r2, $c0, $c2) {
                next unless $onesum == $SUM;
                $any .= ";" if length($any);
                $any .= $r0;
            }
            #$any = "NONE" unless length($any);

            if($any) {
                # diagonal / sum
                print "\t \t\t \t \t \t \t \t", $d1, "\n";                                                                  # diagonal /
                print "\t\t", join("\t+\t", map({sprintf '%2.2s²', $_} $s[0][0], $s[3][0], $s[1][2])), "\t=\t", $r0, "\n";  # rows
                print "\t\t", join("\t+\t", map({sprintf '%2.2s²', $_} $s[2][0], $s[3][1], $s[2][2])), "\t=\t", $r1, "\n";  # rows
                print "\t\t", join("\t+\t", map({sprintf '%2.2s²', $_} $s[1][0], $s[3][2], $s[0][2])), "\t=\t", $r2, "\n";  # rows
                print "\t\t", join("\t \t", map({sprintf '%-5.5s' , $_} $c0, $c1, $c2, $d0)), "\n";                         # cols and diagonal \

                # results
                print "\t$any\n";

                # separator
                print "\n";
            }
        }

    }
}

__END__
For generating a Magic Square made only of squares, we need a set of multiple
triples of square numbers that all contain the same central square number,
which all add up to the same amount – we need sets that have at least 4 (for
up, down, diagonal-down and diagonal-up).

Algebra for the generic formula for a Magic Square (ignoring the requirement
for squares imposed here, and ignoring the requirement for the “normal”
condition of 1…N² for an N×N square) says that the center value must be 1/3 of
the sum.

For that to be the case, in each of the four center-crossing directions, there
must be a set of low+middle+high = 3*middle, which means that low = middle –
delta and high = middle + delta.

With the requirement that each entry is squared, that becomes L²+M²+H² = 3∙M²,
which says that L²+H² = 2∙M².  I wanted to see if that could parameterized,
much like Pythagorean Triples can be parameterized.   By doing brute-force
checks (going through a bunch of M²±Δ, then checking if M²-Δ and M²+Δ were both
squares), I found some simple sets.  But since I was thinking “Pythag” already,
I noticed that the M were all lining up with Pythagorean Z = p2+q2 which
results in X²+Y²=Z², or with an integer multiple of k∙Z.  If I then enumerated
the X=||p2-q2|| and Y=2pq along with those, I saw the pattern that M=Z,
L=||X-Y|| and H=X+Y  – or, on the k∙Z entries, then M=k∙Z, L=k∙||X-Y|| and
H=k∙(X+Y).  I don’t know how to prove whether that’s a complete
parameterization, but that would narrow down the search space significantly,
because the parameterization gives me one of the “sum” requirements.  Since
some pythag Z can be generated with multiple pairs of X and Y (equivalently:
multiple pairs of p,q), then if I search for Z’s that have at least four pairs,
then I can generate each of the four central sums.   Then it’s just a matter of
checking the four outer sums

Well, “just” is an understatement.  There are really 4!=24 permutations for
which group goes in each of the four central sums, and each set of three has
two possible directions, for 24=16 orders for each permutation.  Out of those
24∙16=384 combinations, some are just rotations and mirrors of each other, but
I don’t know which are which, and narrowing it down might be difficult.

Start coding above.  Get the p,q,k nested generator loop
