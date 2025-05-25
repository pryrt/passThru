#!perl
# [id://11165114]

use 5.014; # //, strict, say, s///r
use warnings;

my @c; # = (1..10000000);

sub mldvx4_foreach {
    my @d;
    foreach my $dd ( @c ) { push @d, $dd % 2; }
    my @e;
    foreach my $ee ( @d ) { if (!$ee) { push @e, $ee; } }
    return {d => \@d, e => \@e};
}

sub mldvx4_map {
    my @d = map( $_%2, @c );
    my @e = grep(/0/, @d );
    return {d => \@d, e => \@e};
}

sub corion_map {
    my @d = map( $_%2, @c );
    my @e = grep(!$_, @d );
    return {d => \@d, e => \@e};
}

sub ikegami_no_d_map {
    my @e = grep !$_, map $_ % 2, @c;
    return {e => \@e };
}

sub ikegami_no_grep_map {
    my @e = map $_ % 2 ? () : 0, @c;
    return {e => \@e };
}

sub ikegami_no_d_fe {
    my @e;
    for my $c ( @c ) {
        my $d = $c % 2;
        push @e, $d if !$d;
    }
    return {e => \@e };
}

sub ikegami_no_d_foreach {
    my @e;
    for my $c ( @c ) {
        my $d = $c % 2;
        push @e, $d if !$d;
    }
    return {e => \@e};
}

sub ikegami_no_grep_foreach {
    my @e;
    for my $c ( @c ) {
        push @e, 0 if !( $c % 2 );
    }
    return {e => \@e};
}

sub ikegami_xgrep {
    my @e = ( 0 ) x grep !( $_ % 2 ), @c;
    return {e => \@e};
}

sub ikegami_pushgrep {
    my @e;
    push @e, 0 for 1 .. grep !( $_ % 2 ), @c;
    return {e => \@e};
}



@c = ( 1 .. 100 );
if(1) {
    require Test::More;
    my $fe100 = mldvx4_foreach;
    my $mp100 = mldvx4_map;
    my $corion_100 = corion_map;
    my $ikegami_no_d_map_100 = ikegami_no_d_map;
    my $ikegami_no_grep_map_100 = ikegami_no_grep_map;
    my $ikegami_no_d_fe_100 = ikegami_no_d_foreach;
    my $ikegami_no_grep_fe_100 = ikegami_no_grep_foreach;
    my $ikegami_xgrep_100 = ikegami_xgrep;
    my $ikegami_pushgrep_100 = ikegami_pushgrep;
    Test::More::is_deeply($fe100, $mp100, "compare foreach vs map for 100 units");
    Test::More::is_deeply($mp100, $corion_100, "compare mldvx4_map vs corion_map for 100 units");
    Test::More::is_deeply($mp100->{e}, $ikegami_no_d_map_100->{e}, "compare mldvx4_map vs ikegami_no_d_map for 100 units");
    Test::More::is_deeply($mp100->{e}, $ikegami_no_grep_map_100->{e}, "compare mldvx4_map vs ikegami_no_grep_map for 100 units");
    Test::More::is_deeply($mp100->{e}, $ikegami_no_d_fe_100->{e}, "compare mldvx4_map vs ikegami_no_d_foreach for 100 units");
    Test::More::is_deeply($mp100->{e}, $ikegami_no_grep_fe_100->{e}, "compare mldvx4_map vs ikegami_no_grep_foreach for 100 units");
    Test::More::is_deeply($mp100->{e}, $ikegami_xgrep_100->{e}, "compare mldvx4_map vs ikegami_xgrep for 100 units");
    Test::More::is_deeply($mp100->{e}, $ikegami_pushgrep_100->{e}, "compare mldvx4_map vs ikegami_pushgrep for 100 units");
    #Test::More::diag("fe100 => ", Test::More::explain($fe100));
    #Test::More::diag("mp100 => ", Test::More::explain($mp100));
    #Test::More::diag("corion_100 => ", Test::More::explain($corion_100));
    Test::More::done_testing();
}

use Benchmark qw/cmpthese/;
cmpthese(-10, {
    fe100 => \&mldvx4_foreach,
    mp100 => \&mldvx4_map,
    corion_100 => \&corion_map,
    ikegami_no_d_map_100 => \&ikegami_no_d_map,
    ikegami_no_grep_map_100 => \&ikegami_no_grep_map,
    ikegami_no_d_fe_100 => \&ikegami_no_d_foreach,
    ikegami_no_grep_fe_100 => \&ikegami_no_grep_foreach,
    ikegami_xgrep_100 => \&ikegami_xgrep,
    ikegami_pushgrep_100 => \&ikegami_pushgrep,
});

@c = (1..10000000);
cmpthese(-10, {
    fe10m => \&mldvx4_foreach,
    mp10m => \&mldvx4_map,
    corion_10m => \&corion_map,
    ikegami_no_d_map_10m => \&ikegami_no_d_map,
    ikegami_no_grep_map_10m => \&ikegami_no_grep_map,
    ikegami_no_d_fe_10m => \&ikegami_no_d_foreach,
    ikegami_no_grep_fe_10m => \&ikegami_no_grep_foreach,
    ikegami_xgrep_10m => \&ikegami_xgrep,
    ikegami_pushgrep_10m => \&ikegami_pushgrep,
});

__END__
ok 1 - compare foreach vs map for 100 units
ok 2 - compare mldvx4_map vs corion_map for 100 units
ok 3 - compare mldvx4_map vs ikegami_no_d_map for 100 units
ok 4 - compare mldvx4_map vs ikegami_no_grep_map for 100 units
ok 5 - compare mldvx4_map vs ikegami_no_d_foreach for 100 units
ok 6 - compare mldvx4_map vs ikegami_no_grep_foreach for 100 units
ok 7 - compare mldvx4_map vs ikegami_xgrep for 100 units
ok 8 - compare mldvx4_map vs ikegami_pushgrep for 100 units
1..8
                            Rate mp100 fe100 ikegami_no_d_map_100 ikegami_pushgrep_100 corion_100 ikegami_no_grep_fe_100 ikegami_no_d_fe_100 ikegami_no_grep_map_100 ikegami_xgrep_100
mp100                    19136/s    --  -64%                 -75%                 -78%       -79%                   -81%                -83%                    -84%              -86%
fe100                    52928/s  177%    --                 -30%                 -39%       -43%                   -47%                -52%                    -56%              -62%
ikegami_no_d_map_100     75767/s  296%   43%                   --                 -12%       -19%                   -24%                -32%                    -37%              -46%
ikegami_pushgrep_100     86095/s  350%   63%                  14%                   --        -7%                   -14%                -22%                    -29%              -38%
corion_100               93045/s  386%   76%                  23%                   8%         --                    -7%                -16%                    -23%              -33%
ikegami_no_grep_fe_100   99569/s  420%   88%                  31%                  16%         7%                     --                -10%                    -17%              -29%
ikegami_no_d_fe_100     110936/s  480%  110%                  46%                  29%        19%                    11%                  --                     -8%              -20%
ikegami_no_grep_map_100 120485/s  530%  128%                  59%                  40%        29%                    21%                  9%                      --              -14%
ikegami_xgrep_100       139303/s  628%  163%                  84%                  62%        50%                    40%                 26%                     16%                --
                        s/iter mp10m corion_10m ikegami_no_d_map_10m fe10m ikegami_no_d_fe_10m ikegami_pushgrep_10m ikegami_no_grep_map_10m ikegami_no_grep_fe_10m ikegami_xgrep_10m
mp10m                     3.00    --       -54%                 -55%  -55%                -65%                 -71%                    -73%                   -76%              -87%
corion_10m                1.37  119%         --                  -2%   -2%                -23%                 -36%                    -41%                   -47%              -71%
ikegami_no_d_map_10m      1.34  124%         2%                   --   -0%                -21%                 -35%                    -40%                   -46%              -70%
fe10m                     1.33  125%         2%                   0%    --                -21%                 -35%                    -40%                   -46%              -70%
ikegami_no_d_fe_10m       1.06  184%        29%                  27%   26%                  --                 -18%                    -24%                   -32%              -63%
ikegami_pushgrep_10m     0.868  245%        57%                  54%   54%                 22%                   --                     -7%                   -17%              -54%
ikegami_no_grep_map_10m  0.807  271%        70%                  66%   65%                 31%                   8%                      --                   -11%              -51%
ikegami_no_grep_fe_10m   0.720  316%        90%                  86%   85%                 47%                  21%                     12%                     --              -45%
ikegami_xgrep_10m        0.396  656%       245%                 238%  237%                167%                 119%                    104%                    82%                --
<<< Process finished (PID=18148). (Exit code 0)
