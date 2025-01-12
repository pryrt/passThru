#!/usr/bin/env perl

use strict;
use warnings;

package PrimeSieve {
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

    sub new {
        my ( $class, $sieve_size ) = @_;
        my $shift = 5;

        return bless {
            sieve_size => $sieve_size,
            bits       => [],
            shift      => $shift,       # number of shifts to be equivalent to divide-by-bpe
            bpe        => 1<<$shift,    # number of bits per element of the array (so the memory efficiency factor)
        }, $class;
    }

    sub run_sieve {
        my $self = shift;

        my $factor = 3;
        my $q      = sqrt $self->{sieve_size};
        my @bits   = ();
        my $ss     = $self->{sieve_size};
        $#bits     = $ss;
        my $shift  = $self->{shift};
        my $bpe    = $self->{bpe};

        while ( $factor <= $q ) {
            for ( my $num = $factor ; $num < $ss ; $num += 2 ) {
                my $e = ($num >> $shift);    # which element of the bit array
                my $b = $num % $bpe;            # which bit inside the array
                $bits[$e] |= 0;
                unless ( ($bits[$e]>>$b)&1 ) {  # test just the specific bit in the right element
                    $factor = $num;
                    last;
                }
            }

            my $num2 = $factor ** 2;
            my $twoF = $factor*2;
            while ( $num2 < $ss ) {
                my $e = ($num2 >> $shift);   # which element of the bit array
                my $b = $num2 % $bpe;           # which bit inside the array
                $bits[$e] |= (1 << $b);         # access the correct bit in the element
                $num2 += $factor*2;
            }

            $factor += 2;
        }

        $self->{bits} = \@bits; # return a reference to the local array, which avoids copying the array
    }

    sub print_results {
        my ( $self, $show_results, $duration, $passes ) = @_;
        my $shift  = $self->{shift};
        my $bpe    = $self->{bpe};

        print "2, " if ($show_results);

        my $count = ( $self->{sieve_size} >= 2 );
        for ( my $num = 3 ; $num <= $self->{sieve_size} ; $num += 2 ) {
            my $e = ($num >> $shift);    # which element of the bit array
            my $b = $num % $bpe;            # which bit inside the array
            unless ( ($self->{bits}[$e] >> $b) & 1 ) {
                printf( "%d, ", $num ) if ($show_results);
                $count++;
            }
        }

        print "" if ($show_results);

        printf "pryrt3;%d;%f;%d;algorithm=base,faithful=yes\n", $passes, $duration, 1;
        printf STDERR
          "Passes: %d, Time: %f, Avg: %f, Limit: %d, Count1: %d, Count2: %d, Valid: %d\n",
          $passes, $duration, $duration / $passes,
          $self->{sieve_size}, $count, $self->count_primes(),
          $self->validate_results();
    }

    sub count_primes {
        my $self = shift;
        my $shift  = $self->{shift};
        my $bpe    = $self->{bpe};

        my $count = ( $self->{sieve_size} >= 2 );
        for ( my $i = 3 ; $i < $self->{sieve_size} ; $i += 2 ) {
            my $e = ($i >> $shift);    # which element of the bit array
            my $b = $i % $bpe;            # which bit inside the array
            $count++ unless ( ($self->{bits}[$e] >> $b) & 1 );
        }

        return $count;
    }

    sub validate_results {
        my $self = shift;

        return ( $DICT{ $self->{sieve_size} } == $self->count_primes() );
    }
};

package main {
    use Time::HiRes qw(time);

    my $passes     = 0;
    my $start_time = time;

    while (1) {
        my $sieve = PrimeSieve->new(1000000);
        $sieve->run_sieve();
        $passes++;

        my $duration = time - $start_time;
        if ( $duration >= 5 ) {
            $sieve->print_results( 0, $duration, $passes );
            last;
        }
    }
};

__END__
