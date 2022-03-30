#!perl

use 5.012; # strict, //
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use SineCalculatorReloadable;

$| = 1;

#printf STDERR "INC{%s} = %s\n", $_, $INC{$_}//'<undef>' for map { $_ . '.pm' } qw/Reloadable SineCalculatorReloadable/;

my $sinecalc = SineCalculatorReloadable->SineCalculator(); # no state at initial creation
#print STDERR "DEBUG: sinecalc = $sinecalc\n";

my $i = 0;
while(1) { # infinite loop calling sinecalc function, with reload (as necessary)
    sleep(1);
    $sinecalc = $sinecalc->reload();
    eval {
        printf STDERR "sinecalc->calculate(%f) = %s\n", $i/5, $sinecalc->calculate($i/5);
        1;
    } or do {
        printf STDERR "ERROR: sinecalc->calculate(%f) says:\n\t%s", $i/5, $@//'<undef>';
    };
    $i = ($i+1) % 50;
}
