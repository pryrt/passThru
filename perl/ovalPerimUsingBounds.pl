#!perl
use 5.012; # strict, //
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real::Intersect;
use POSIX 'M_PI';
$| = 1;

my $A = 4;
my $B = 1;
my $nPointsPerQuarter = 512;    # 128 is enough to match for A=B=10 (5digits); 512 matches 6 digits (A=B=100), 2048 for 7 digits, 4096 for 8 digits, 16k for 9 digits
my @quarter = (undef) x ($nPointsPerQuarter + 1);
my @tangent = @quarter;

my $DEBUG = 0;
$Math::Vector::Real::Intersect::DEBUG = ($DEBUG>1);

my $inner_len = 0;
my $outer_len = 0;
for my $i ( 0 .. $nPointsPerQuarter ) {
    my $t = $i / $nPointsPerQuarter * (M_PI/2);
    $quarter[$i] = my $pt = V( +$A*cos($t), $B*sin($t) );
    $tangent[$i] = my $tn = V( -$A*sin($t), $B*cos($t) );

    # no distances calculated on the first point (nothing to have a distance from)
    if(0==$i) {
        next;
    }

    # inner distance is just distance from previous to current point
    my $inner_dist = $quarter[$i-1]->dist($pt);
    $inner_len += $inner_dist;

    # outer distance requires an intermediate, at the intersection of <prev> + r * <prev.tan> == <this> - s * <this.tan>
    my $itc = intersect_lines($quarter[$i-1],$tangent[$i-1], $pt,-$tn);
    my $odist_prev = $quarter[$i-1]->dist($itc);
    my $odist_this = $itc->dist($pt);
    $outer_len += $odist_prev + $odist_this;

    # summary
    if($DEBUG) {
        printf "%-6d %5.3f => %-40.40s tan:%-40.40s => in:%-9.3f, out:%-9.3f | in_d:%-9.3f | itc=%-40.40s => dp=%-9.3f + dt=%-9.3f = out_d=%-9.3f\n", $i, $t, $pt, $tn, $inner_len, $outer_len, $inner_dist, $itc, $odist_prev, $odist_this, $odist_prev + $odist_this;
    }
}
printf "Final: A=%s B=%s => in:%.6f out:%.6f\n", $A, $B, $inner_len, $outer_len;

=begin output
n:2      1.571 => {6.12303176911189e-17, 1}                tan:{-1, 6.12303176911189e-17}               => in:1.531    , out:1.657     | in_d:0.765     | itc={0.414213562373095, 1}                   => dp=0.414     + dt=0.414     = out_d=0.828
n:4      1.571 => {6.12303176911189e-17, 1}                tan:{-1, 6.12303176911189e-17}               => in:1.561    , out:1.591     | in_d:0.390     | itc={0.198912367379658, 1}                   => dp=0.199     + dt=0.199     = out_d=0.398
n:8      1.571 => {6.12303176911189e-17, 1}                tan:{-1, 6.12303176911189e-17}               => in:1.568    , out:1.576     | in_d:0.196     | itc={0.0984914033571643, 1}                  => dp=0.098     + dt=0.098     = out_d=0.197
n:16     1.571 => {6.12303176911189e-17, 1}                tan:{-1, 6.12303176911189e-17}               => in:1.570    , out:1.572     | in_d:0.098     | itc={0.0491268497694668, 1}                  => dp=0.049     + dt=0.049     = out_d=0.098
n:128    1.571 => {6.12303176911189e-17, 1}                tan:{-1, 6.12303176911189e-17}               => in:1.571    , out:1.571     | in_d:0.012     | itc={0.00613600015762037, 1}                 => dp=0.006     + dt=0.006     = out_d=0.012
n:1024   1.571 => {6.12303176911189e-17, 1}                tan:{-1, 6.12303176911189e-17}               => in:1.571    , out:1.571     | in_d:0.002     | itc={0.000766990544323125, 1}                => dp=0.001     + dt=0.001     = out_d=0.002

=cut
