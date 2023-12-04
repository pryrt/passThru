#!perl

use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real;
use Math::Vector::Real::Bezier::Cubic;

my $actual = CubicBezier(V(0,0), V(0,0.5), V(0.5,1), V(1,1));

srand(19750118);
my @samples = map { $actual->B($_) } sort 0,1, map {rand()} 1..9;
print "$_\n" for @samples;
print "End Slopes: ", $actual->dBdt(0), " ... ", $actual->dBdt(1), "\n";

my $guess = CubicBezier(V(0,0), V(0,0.3), V(0.7,1), V(1,1));
printf "guess{%s} = %s\n", $_, $guess->{$_} for qw/p0 p1 p2 p3/;
for(1..100) {
    slide('p1', 1);
    slide('p2', 0);
}
printf "final guess{%s} = %s\n", $_, $guess->{$_} for qw/p0 p1 p2 p3/;
printf "vs   actual{%s} = %s\n", $_, $actual->{$_} for qw/p0 p1 p2 p3/;

sub slide {
    my ($ctrl, $dim) = @_;
    printf "slide($ctrl,$dim): initial d**2 = %.6f\n", my $d2 = dist2guess();
    my $div = 2;
    while($div <= 1024) {
        my $param = $guess->{$ctrl}[$dim];
        printf "param(%s[%d]): %+12.6f => %.6f\n", $ctrl, $dim, $param, $d2;
        my @tries = !$param ? (0.25,0.75) : ( $param*(1-1/$div), $param*(1+1/$div) );
        for my $try (@tries) {
            $guess->{$ctrl}[$dim] = $try;
            my $dsq = dist2guess();
            printf "tried:        %+12.6f => %.6f\n", $try, $dsq;
            if($dsq < $d2) {
                $param = $try;
                $d2 = $dsq;
            }
        }
        $guess->{$ctrl}[$dim] = $param;
        printf "chose(%s[%d]): %+12.6f => %.6f\n\n", $ctrl, $dim, $param, $d2;
        $div *= 2;
    }
}

sub dist2guess {
    my $total_d2 = 0;
    for my $sample ( @samples[ 1 .. $#samples-1 ] ) {
        my $dt = 0.5;
        my $t = 0.5;
        my $guess_t = $guess->B($t);
        my $dist2 = $guess_t->dist2($sample);
        #printf "sample(%-42.42s): initial:     guess(t:%+6.3f)=%-42.42s => dsq=%.6f\n", $sample, $t, $guess_t, $dist2;
        for (0..9) {
            my $tm = $t - $dt;
            my $gm = $guess->B($tm);
            my $dm = $gm->dist2($sample);
            #printf "sample(%-42.42s): step%d-minus: guess(t:%+6.3f)=%-42.42s => dsq=%.6f\n", $sample, $_, $tm, $gm, $dm;

            my $tp = $t + $dt;
            my $gp = $guess->B($tp);
            my $dp = $gp->dist2($sample);
            #printf "sample(%-42.42s): step%d-plus:  guess(t:%+6.3f)=%-42.42s => dsq=%.6f\n", $sample, $_, $tp, $gp, $dp;

            if($dm < $dist2) {
                $t = $tm;
                $guess_t = $gm;
                $dist2 = $dm;
            }
            if($dp < $dist2) {
                $t = $tp;
                $guess_t = $gp;
                $dist2 = $dp;
            }
            $dt /= 2;
        }
        $total_d2 += $dist2;
        #printf "sample(%-42.42s): final:       guess(t:%+6.3f)=%-42.42s => dsq=%.6f, sum(dsq)=%.6f\n", $sample, $t, $guess_t, $dist2, $total_d2;
    }
    return $total_d2;
}
