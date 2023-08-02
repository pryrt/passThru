#!perl

use 5.014; # strict, //, s//r
use warnings;
use Benchmark qw/cmpthese/;
use Data::Dump;
use Time::HiRes qw/time/;
$| = 1;

my @abc = (' ', '*', '-');

sub make_longstring($)
{
    my ($w) = @_;
    join '', @abc[ map { rand 2 } 1 .. $w*$w ]
}

print make_longstring(5), "\n";

sub make_arrofstr($)
{
    my ($w) = @_;
    my @a;
    push @a, join '', @abc[ map { rand 2 } 1 .. $w ] for 1 .. $w;
    return @a;
}

sub make_arrofarr($)
{
    my ($w) = @_;
    my @a;
    push @a, [@abc[ map { rand 2 } 1 .. $w ]] for 1 .. $w;
    return @a;
}

dd {
    longstring5 => make_longstring(5),
    arrofstr5 => [make_arrofstr(5)],
    arrofarr5 => [make_arrofarr(5)],
};

while(0) {
    my $t0 = scalar time;
    cmpthese(-10, {
        create_longstring   => sub { make_longstring(15) for 1 .. 1000 },
        create_arrofstr     => sub { make_arrofstr(15)   for 1 .. 1000 },
        create_arrofarr     => sub { make_arrofarr(15)   for 1 .. 1000 },
    });
    my $t1 = scalar time;
    printf "%s\n", $t1 - $t0;
    # verdict: longstring is fastest for creating.
}

# now look at accessing them
my $w = 15;
my $strofstr = make_longstring($w);
my @arrofstr = make_arrofstr($w);
my @arrofarr = make_arrofarr($w);
dd {
    strofstr => [ $strofstr ],
    arrofstr => [ @arrofstr ],
    arrofarr => [ @arrofarr ],
};
while(0) {
    my $t0 = scalar time;
    cmpthese(-10, {
        access_longstring   => sub { $_ = substr($strofstr, (int(rand $w)*$w+int(rand $w)), 1) for 1 .. 1000 },
        access_arrofstr     => sub { $_ = substr($arrofstr[int rand $w], int rand $w, 1)       for 1 .. 1000 },
        access_arrofarr     => sub { $_ = $arrofarr[int rand $w][int rand $w]                  for 1 .. 1000 },
    });
    my $t1 = scalar time;
    printf "%s\n", $t1 - $t0;
    # access_arrofstr is consistently the fastest; access_arrofarr is usually faster than access_longstring, but not always
}

# based on these experiments, I think that array-of-strings will be the best to implement, with reasonably-fast computation times
