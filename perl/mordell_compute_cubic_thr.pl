#!perl

# https://hhr-m.de/mordell/
# https://hhr-m.de/mordell/big_table.txt
#   (X**3 + K) = Y**2

use 5.014; # //, strict, say, s///r
use warnings;
use Math::BigInt;
use Time::HiRes qw/time/;
use threads;
use Thread::Queue;

my $T0 = time;

sub is_perfect_square
{
    my $rtsq = $_[0]->copy()->bsqrt->bpow(2);   # floor(sqrt(arg))**2
    $rtsq == $_[0];
}

sub compute_cubic_mordell
{
    my $t0 = time;
    my $q = Math::BigInt->new(''.$_[0]);
    my $id = $_[1] // -1;
    my $k = $q ** 3;
    my $x = -($q->copy);
    #printf "for k=%s, start at x=%s and work your way up\n", $k, $x;
    my @answers=();
    while ($x <= 10000) {
        my $m = $x**3 + $k;
        if(is_perfect_square($m)) {
            my $y = $m->copy->bsqrt;
            #printf "%s**3 + %s = %s = %s**2\n", $x, $k, $m, $y;
            push @answers, [$x,$y];
        }
        ++$x;
    }
    my $dt = time - $t0;
    my $DT = time - $T0;
    if(1 && @answers) {
        printf "[%d][%12.6fs][%12.6fs] q=%s k=%s", $q, $k;
        printf "(%s,%s)", $_->[0], $_->[1] for @answers;
        print "\n";
    }
    #printf STDERR "[%d][%12.6fs][%12.6fs] compute_cubic_mordell(%s)\n", $id, $DT, $dt, $q;
}

if(0) {
    # sequential version
    for(1..30) {
        my $arg = Math::BigInt->new($_);
        #printf "%d %s perfect square\n", $arg, is_perfect_square($arg) ? 'is' : 'is not';
        compute_cubic_mordell($arg);
        compute_cubic_mordell(-$arg);
    }
} else {
    # threaded version
    my $Q = Thread::Queue->new();
    #$Q->limit(10);  # should only allow 10 active items in the queue at once...

    sub worker_task {
        while( defined (my $arg = $Q->dequeue)) {
            compute_cubic_mordell($arg, threads->tid());
        }
    }

    # make five workers
    my @workers = map { threads->create(\&worker_task) } 1..5;

    # enqueue everything
    for(1..30) {
        $Q->enqueue($_);
    }

    # done
    $Q->end();
    $_->join() for @workers;

}
