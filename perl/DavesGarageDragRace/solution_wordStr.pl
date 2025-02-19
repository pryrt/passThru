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
        my $sieve_bytes = ($sieve_size + 1) / 8;
        bless {
            sieve_size => $sieve_size,
            #bits      => '0' x ($sieve_size+1),
            ##bits     => '000' . '01' x (($sieve_size-1)/2),
            vec        => "\0" x ($sieve_bytes+1),
        }, $class;
    }

    sub run_sieve {
        my $self    = shift;
        my $size    = $self->{sieve_size};
        ##my $bits   = \$self->{bits};
        my $rvec    = \$self->{vec};
        my $q       = sqrt $size;
        my $factor  = 1;
        my $offs    = 0;
        my $step    = 0;
#printf "\t%s\n", join'',(0..9)x($self->{sieve_size}/10);
#printf "BEFORE\t%s\n", unpack 'b*', $$rvec;
         while ( $factor <= $q ) {
            $factor += 2;
            $factor += 2 while $factor < $size and vec($$rvec,$factor,1);
            $offs = $factor**2;
            $step = 2*$factor;
#printf "f: %d, o:%d\n", $factor, $offs;
            while ($offs < $size) {
                vec($$rvec, $offs, 1) = 1;
                $offs += $step;
            }
#printf "AFTER\t%s\n", unpack 'b*', $$rvec;
         }
#printf "\t%s\n", join'',(0..9)x($self->{sieve_size}/10);
    }

    sub primes {
        my $self = shift;
        my $rvec = \$self->{vec};
        grep!vec($$rvec,$_,1),2,grep$_%2,3..$self->{sieve_size};
    }

    sub print_results {
        my ( $self, $show_results, $duration, $passes ) = @_;
        my @primes = $self->primes();
        my $count = 0 + @primes;
        print join(", ", @primes),"\n" if $show_results;
        my $f = $DICT{$self->{sieve_size}} == $count ? 'yes' : 'no';
        printf "kjetillll_pryrt;%d;%f;%d;algorithm=base,faithful=%s\n", $passes, $duration, 1, $f;
        printf STDERR "Passes: %d, Time: %f, Avg: %f, Limit: %d, Count1: %d, Count2: %d, Valid: %d\n",
           $passes, $duration, $duration / $passes,
           $self->{sieve_size}, $count, $self->count_primes(),
           $self->validate_results();
    }

    sub count_primes {
        my $self = shift;
        0 + $self->primes();
    }

    sub validate_results {
        my $self = shift;
        $DICT{ $self->{sieve_size} } == $self->count_primes();
    }
};

package main {
    use Time::HiRes 'time';
    my $passes     = 0;
    my $start_time = time();
    my $sieve;
    sub duration { time() - $start_time }

    while ( duration() < 5 )
    {
        $sieve = PrimeSieve->new(1000000);
        $sieve->run_sieve();
        $passes++;
    }
    $sieve->print_results( 0, duration(), $passes );
};

__END__
