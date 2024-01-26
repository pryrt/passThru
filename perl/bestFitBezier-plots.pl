#!perl

use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real;
use Math::Vector::Real::Bezier::Cubic;
use utf8;
use autodie;
use GD;

BEGIN { $| = 1; }

my $im = GD::Image::->new(200,100,1);
my $c_bg = $im->colorAllocate(51,51,51);
my $c_plot = $im->colorAllocate(191,191,191);
my $c_samp = $im->colorAllocate(255,0,0);

END {
    open my $fh, '>:raw', 'out.png';
    print {$fh} $im->png();
    close $fh;
    #system(1,'out.png');
}

sub v2px {
    my ($v) = @_;
    return @{V(100*$v->[0], 100-100*$v->[1])};
}

my $actual = CubicBezier(V(0,0), V(0,0.5), V(0.5,1), V(1,1));

srand(19750118);
my @samples = map { print "$_, "; $actual->B($_) } sort 0,1, map {rand()} 1..9; print "\n";
print "$_\n" for @samples;
print "End Slopes: ", $actual->dBdt(0), " ... ", $actual->dBdt(1), "\n";

my $guess = CubicBezier(V(0,0), V(0,1), V(0,1), V(1,1));

for (1 .. 10) {
    my $t = $_/10;
    my $prev = ($_-1)/10;
    my $v = $guess->B($t);
    my $p = $guess->B($prev);
    $im->line(v2px($p), v2px($v), $c_plot);
}
for my $s (@samples) {
    $im->filledEllipse(v2px($s), 8,8, $c_samp);
    my ($t, $d, $v) = $guess->closestToPoint($s);
    printf "s:[%+6.3f,%+6.3f] -> B(t:%+6.3f) = [%+6.3f,%+6.3f] => dsq:%.3f\n", @$s, $t, @$v, $d;
}

