#!perl
use 5.012; # strict, //
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Intersect;
use POSIX 'M_PI';
$| = 1;

my $A = 1;
my $B = 1;
my $nPointsPerQuarter = 2;
my @quarter = (undef) x ($nPointsPerQuarter + 1);
my @tangent = @quarter;

my $inner_len = 0;
my $outer_len = 0;
for my $i ( 0 .. $nPointsPerQuarter ) {
    my $t = $i / $nPointsPerQuarter * (M_PI/2);
    $quarter[$i] = my $pt = V( +$A*cos($t), $B*sin($t) );
    $tangent[$i] = my $tn = V( -$A*sin($t), $B*cos($t) );

    # no distances calculated on the first point (nothing to have a distance from)
    if(0==$i) {
        printf "%-3d %5.3f => %-40.40s tan:%-40.40s => in:%-9.3f, out:%-9.3f\n", $i, $t, $pt,$tn, $inner_len, $outer_len;
        next;
    }

    # inner distance is just distance from previous to current point
    my $inner_dist = $quarter[$i-1]->dist($pt);
    $inner_len += $inner_dist;

    # outer distance requires an intermediate, at the intersection of <prev> + r * <prev.tan> == <this> - s * <this.tan>
    my $itc = intersect_lines($quarter[$i-1],$tangent[$i-1], $pt,-$tn);
    my $odist_prev = $quarter[$i-1]->dist($itc);
    my $odist_this = $quarter[$i]->dist($itc);
    $outer_len += $odist_prev + $odist_this;

    # summary
    printf "%-3d %5.3f => %-40.40s tan:%-40.40s => in:%-9.3f, out:%-9.3f | inner_dist:%-9.3f | itc=%s, dp=%-9.3f, dt=%-9.3f\n", $i, $t, $pt, $tn, $inner_len, $outer_len, $inner_dist, $itc, $odist_prev, $odist_this;
}

=begin output
2   1.571 => {6.12303176911189e-17, 1}                => in:1.531    , out:2.402     | inner_dist:0.765     | itc={1, 0.414213562373095}, dp=0.414    , dt=1.159

4   1.571 => {6.12303176911189e-17, 1}                => in:1.561    , out:2.856     | inner_dist:0.390     | itc={0.707106781186548, 0.789498981478941}, dp=0.351    , dt=0.738

8   1.571 => {6.12303176911189e-17, 1}                => in:1.568    , out:4.198     | inner_dist:0.196     | itc={0.38268343236509, 0.943470690719605}, dp=0.191    , dt=0.387

16  1.571 => {6.12303176911189e-17, 1}                => in:1.570    , out:5.570     | inner_dist:0.098     | itc={0.195090322016129, 0.985623852779542}, dp=0.098    , dt=0.196

Something is wrong... the out should be approaching pi/2=1.571, but it seems to be increasing.

=cut
