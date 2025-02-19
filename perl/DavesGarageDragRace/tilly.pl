#! /usr/bin/perl -w
#
# derived from [tilly]'s sieve <https://perlmonks.org/?node_id=276112>,
#   which is implemented in a closure rather than in an "object",
#   but the spirit of the contest is a self-contained unit that gets recreated each try,
#   and a closure meets that definition as well as an "object"
use strict;

package PrimeSieve {
    sub build_sieve {
      my ($sieve_size) = @_;
      my $self = bless { sieve_size => $sieve_size, fn => undef, results => undef };
      my $n = 0;
      my @upcoming_factors = ();
      my ($next_small_p, $sub_iter);
      my $gives_next_square = 5;

      $self->{fn} = sub {
        LOOP: {
          if (not $n++) {
            return 2; # Special case
          }
          if (not defined $upcoming_factors[0]) {
            if ($n == $gives_next_square) {
              if (not defined ($sub_iter)) {
                # Be lazy to avoid an infinite loop...
                $sub_iter = PrimeSieve::build_sieve();
                $sub_iter->{fn}(); # Throw away 2
                $next_small_p = $sub_iter->{fn}();
              }

              push @{$upcoming_factors[$next_small_p]}, $next_small_p;
              $next_small_p = $sub_iter->{fn}();
              my $next_p2 = $next_small_p * $next_small_p;
              $gives_next_square = ($next_p2 + 1)/2;
              shift @upcoming_factors;
              redo LOOP;
            }
            else {
              shift @upcoming_factors;
              return 2*$n-1;
            }
          }
          else {
            foreach my $i (@{$upcoming_factors[0]}) {
              push @{$upcoming_factors[$i]}, $i;
            }
            shift @upcoming_factors;
            redo LOOP;
          }
        }
      };
      return $self;
    }

    sub run_sieve {
        my ($self) = @_;
        my @primes = ();
        my $p;
        while(($p = $self->{fn}()) < $self->{sieve_size}) { push @primes, $p }
        return $self->{results} = \@primes;
    }

    sub primes {
        my $self = shift;
        return @{$self->{results}};
    }

    sub count_primes {
        my $self = shift;
        0 + $self->primes();
    }

    my %DICT = (
        10          => 4,
        100         => 25,
        1000        => 168,
        10000       => 1229,
        100000      => 9592,
        1000000     => 78498,
        10000000    => 664579,
        100000000   => 5761455,
        1000000000  => 50847534,
        10000000000 => 455052511,
    );

    sub validate_results {
        my $self = shift;
        $DICT{ $self->{sieve_size} } == $self->count_primes();
    }

    sub print_results {
        my ( $self, $show_results, $duration, $passes ) = @_;
        my @primes = $self->primes();
        my $count = 0 + @primes;
        print join(", ", @primes),"\n" if $show_results;
        my $f = ($DICT{$self->{sieve_size}} == $count) ? 'yes' : 'no';
        printf "tilly;%d;%f;%d;algorithm=base,faithful=%s\n", $passes, $duration, 1, $f;
        #printf STDERR "Passes: %d, Time: %f, Avg: %f, Limit: %d, Count1: %d, Count2: %d, Valid: %d\n",
        #   $passes, $duration, $duration / $passes,
        #   $self->{sieve_size}, $count, $self->count_primes(),
        #   $self->validate_results();
    }
}

### Original ###
## Produce as many primes as are asked for, or 100.
#my $sieve = build_sieve();
#my $p;
#while (($p = $sieve->()) < 100) { print $p, "\n"; }

## Structured ###
package main {
    use Time::HiRes 'time';
    my $passes     = 0;
    my $start_time = time();
    my $sieve;
    sub duration { time() - $start_time }
    my $sieve_size = 1000000;

    while( duration() < 5 )
    {
        $sieve = PrimeSieve::build_sieve($sieve_size);
        $sieve->run_sieve();
        $passes++;
    }
    $sieve->print_results(0, duration(), $passes);
}
