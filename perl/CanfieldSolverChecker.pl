#!perl
# solving my app's Canfield (draw by 1) rules
#   - Reserve gets pop'd onto first empty tableau at all times
#   - Stock is revealed one at a time (pop from list)
#   - Tableau's initially get populated from the last four cards of the initial Reserve, alternating color descending rank
#   - Foundations from A,2,...,Q,K of single suit

use 5.014; # //, strict, say, s///r
use warnings;
use Data::Dump qw/pp/;
$| = 1;
use Time::HiRes qw/time/;

my @init_reserve = ('?','?','?','?','?','?','?','?','8C','7D','9S','8H','AD','7H','JH','TD','5D','JD');
my @init_stock = ('TH','2H','9H','KC','5H','7S','7C','JC','4C','8S','TS','4H','KD','3H','AH','2C','9D','4D','AC','6C','3D','QD','3S','QC','6S','AS','5S','QH','2D','QS','8D','3C','9C','JS');

my @seeds = map {int 32768*rand()} 1 .. 10000;
my $best = 53;
my $best_save = {};
my $t0 = my $t00 = time;
for(0 .. $#seeds) {
    my $seed = $seeds[$_];
    my $ret = one_game($seed, \@init_reserve, \@init_stock, [[],[],[],[]], [[],[],[],[]]);
    my $reserve_remaining = scalar @{ $ret->{reserve} };
    if($reserve_remaining < $best) {
        $best_save = $ret;
        $best = $reserve_remaining;
        print pp $ret;
    }
    my $t1 = time;
    my $rate = ($t1 - $t0) * 1000; # ms/game
    printf "== END OF GAME #%5d:s%09d: reserve still has %d vs best=%d (%013.9fms/game at %9.1fs total) ==\n", $_, $seed, $reserve_remaining, $best, $rate, $t1-$t00;
    $t0 = time;
}
print "BEST => ", pp $best_save;


sub one_game {
    my ($seed, $rreserve, $rstock, $rfoundation, $rtableau) = @_;
    if(defined $seed) { srand $seed; } else { $seed = srand; } # in 5.14 and newer, the retval of srand will be the seed, so I can know what it is in the future
    my @reserve = @$rreserve;   # make a copy
    my @stock = @$rstock;      # make a copy
    my @foundation = @$rfoundation;
    my @tableau = @$rtableau;

    my @moves;
    my $count = 0;

    MAINLOOP: while(1) {
        # check for unknown reserve, and exit, because we've found a viable path to the next card
        if ($reserve[-1] eq '?') {
            print pp { seed => $seed, reserve => \@reserve, stock => \@stock, foundation => \@foundation, tableau => \@tableau, zz_moves => \@moves};
            die "found the next '?'";
        }

        # check if each tableau needs starting, and fill it immediately
        my $any = 0;
        for my $t ( 0 .. 3 ) {
            if(try_move_to_empty_tableau($tableau[$t], \@reserve, 1)) { # the 1 means no randomization
                push @moves, { "R->T[$t]" => $tableau[$t][-1] };
                $any = 1;
            }
        }
        if($any) { next MAINLOOP; }

        # if there's still an empty tableau, _may_ choose to fill it from stock
        for my $t ( 0 .. 3 ) {
            if(try_move_to_empty_tableau($tableau[$t], \@stock)) {
                push @moves, { "S->T[$t]" => $tableau[$t][-1] };
                next MAINLOOP;
            }
        }

        # check if next reserve can be moved onto that suit's foundation:
        if(defined (my $f = try_move_to_foundation_f(\@foundation, \@reserve))) {
            push @moves, { "R->F[$f]" => $foundation[$f][-1] };
            next MAINLOOP;
        }

        # check if next stock can be moved onto that suit's foundation:
        if(defined (my $f = try_move_to_foundation_f(\@foundation, \@stock))) {
            push @moves, { "S->F[$f]" => $foundation[$f][-1] };
            next MAINLOOP;
        }

        # check if any of the bottom tableau cards can be moved onto its foundation:
        for my $t ( 0 .. 3 ) {
            if(defined (my $f = try_move_to_foundation_f(\@foundation, $tableau[$t]))) {
                push @moves, { "T[$t]->F[$f]" => $foundation[$f][-1] };
                next MAINLOOP;
            }
        }

        # check if the next reserve can be moved onto each tableau
        for my $t (0 .. 3) {
            if(try_move_to_tableau_t($tableau[$t], \@reserve)) {
                push @moves, { "R->T[$t]" => $tableau[$t][-1] };
                next MAINLOOP;
            }
        }

        # check if the next stock can be moved onto each tableau
        for my $t (0 .. 3) {
            if(try_move_to_tableau_t($tableau[$t], \@stock)) {
                push @moves, { "S->T[$t]" => $tableau[$t][-1] };
                next MAINLOOP;
            }
        }

        # can the top of one tableau be moved to the bottom of another
        for my $st (0..3) {
            for my $dt (0..3) {
                next if $st eq $dt;
                if(try_move_tableau_across($tableau[$dt], $tableau[$st])) {
                    push @moves, { "T[$st]->T[$dt]" => $tableau[$dt][-1]};
                    next MAINLOOP;
                }
            }
        }

        # if you get here, it means that there are no obvious moves (or it didn't take that move), so will (probably) rotate the stock:
        #   though if there's nothing to rotate, it's game-over at this point
        if(!scalar @stock) { last MAINLOOP; }

        # don't rotate stock more than N times: 6000 is more than 200 times through the stock, so that's plenty
        if(++$count > 5999 ) { last MAINLOOP; }

        # now rotate
        unshift @stock, pop @stock; # move card from end to beginning, which puts new card at end
        #printf "ROTATED STOCK #%9d: prev=%-2s new=%-2s\n", $count, $stock[0], $stock[-1] unless $count % 1e3;

    }

    my $ret = { seed => $seed, reserve => \@reserve, stock => \@stock, foundation => \@foundation, tableau => \@tableau, zz_moves => \@moves};
    #print pp $ret;
    return $ret;
}

sub try_move_to_empty_tableau {
    my ($dst, $src, $doMove) = @_;
    $doMove ||= (rand() < 0.5);        # if doMove was already set true, it will already move; otherwise, it has a 50% chance of moving.

    if( 0 == scalar @$dst) {
        if(scalar(@$src) and $doMove) {
            push @$dst, pop @$src;
            return 1;
        }
    }
    return 0;
}

sub try_move_to_foundation_f {
    my ($dst, $src, $doMove) = @_;
    $doMove ||= (rand() < 0.5);        # if doMove was already set true, it will already move; otherwise, it has a 50% chance of moving.

    if(!scalar @$src) { return 0; } # don't try with an empty source

    my $card = $src->[-1];
    my $v = cardval($card);
    my $f = suitval($card);    # foundation number is suit value
    #printf "TMTF: %s = v:%-2s f:%s, 1+d:%s", $card, $v, $f, 1 + scalar(@{$dst->[$f]});
    if($v == 1 + scalar @{ $dst->[$f] }) {     # if the foundation has 1 card (A) and the value is 1+1=2, then the 2 of that suit can be added to the foundation
        if($doMove) {
            push @{ $dst->[$f] }, pop @$src;
            #print " => $f\n";
            return $f;
        }
    }
    #print "\n";
    return undef;
}

sub try_move_to_tableau_t {
    my ($dst, $src, $doMove) = @_;
    $doMove ||= (rand() < 0.5);        # if doMove was already set true, it will already move; otherwise, it has a 50% chance of moving.

    if(!scalar @$src) { return 0; } # don't try with an empty source

    my $srccard = $src->[-1];
    my $srcv = cardval($srccard);
    my $srcf = suitval($srccard);    # foundation number is suit value
    my $srcc = cardclr($srccard);

    my $dstcard = $dst->[-1];
    my $dstv = cardval($dstcard);
    my $dstf = suitval($dstcard);
    my $dstc = cardclr($dstcard);

    #printf "TMTTT src(%s = v:%-2s f:%s c:%s) vs dst(%s = v:%-2s f:%s c:%s)", $srccard, $srcv, $srcf, $srcc, $dstcard, $dstv, $dstf, $dstc;
    my $isLower = ($srcv == $dstv - 1) || (($srcv==13) && ($dstv==1));  # src is one lower than dst, or src is King and dst is Ace (allows wraparound)
    if($doMove and $srcc != $dstc and $isLower) { # if they have different colors, and the source is one lower than the destination, may do the move
        push @$dst, pop @$src;
        #print " => 1\n";
        return 1;
    }
    #print "\n";
    return undef;
}

sub try_move_tableau_across { # ($tableau[$dt], $tableau[$st])
    my ($dst, $src, $doMove) = @_;
    $doMove ||= (rand() < 0.5);     # if doMove was already set true, it will already move; otherwise, it has a 50% chance of moving.

    if(!scalar @$src) { return 0; } # don't try with an empty source

    # need to check the TOP of the src
    my $srccard = $src->[0];
    my $srcv = cardval($srccard);
    my $srcf = suitval($srccard);
    my $srcc = cardclr($srccard);

    # need to check the BOTTOM of the dst
    my $dstcard = $dst->[-1];
    my $dstv = cardval($dstcard);
    my $dstf = suitval($dstcard);
    my $dstc = cardclr($dstcard);

    #printf "TMTA src_top(%s = v:%-2s f:%s c:%s) vs dst_bot(%s = v:%-2s f:%s c:%s) do?%d", $srccard, $srcv, $srcf, $srcc, $dstcard, $dstv, $dstf, $dstc, $doMove//0;
    my $isLower = ($srcv == $dstv - 1) || (($srcv==13) && ($dstv==1));  # src is one lower than dst, or src is King and dst is Ace (allows wraparound)
    if($doMove and $srcc != $dstc and $isLower) { # if they have different colors, isLower
        #print " => 1\n";
        #print pp { orig_src => $src, orig_dst => $dst }; print "\n";
        push @$dst, @$src;  # push ALL of SRC onto DST
        @$src = (); # empty SRC, since it was all moved
        #print pp { src => $src, dst => $dst }; print "\n";
        return 1;
    }
    #print "\n";
    return undef;
}

sub cardval {
    my($card) = @_;
    state %vals = ('?' => 0, 'A' => 1, 'T' => 10, 'J' => 11, 'Q' => 12, 'K' => 13); $vals{$_} = $_ for 2..9;
    return $vals{ substr($card,0,1) };
}

sub suitval {
    my ($card) = @_;
    state %sval = ('C'=>0, 'H'=>1, 'S'=>2, 'D'=>3);
    return $sval{ substr($card,1,1) };
}

sub cardclr { # 0 is black (C/S), 1 is red (H/D)
    my ($card) = @_;
    state %sclr = ('C'=>0, 'H'=>1, 'S'=>0, 'D'=>1);
    return $sclr{ substr($card,1,1) };
}

sub cardsort {
    my ($va,$sa) = split //, $a;
    my ($vb,$sb) = split //, $b;
    $_ = cardval($_) for $va,$vb;
    $_ = suitval{$_} for $sa,$sb;
    return ($va <=> $vb) || ($sa <=> $sb);
}

__END__
,'5C','TC'
,'6H','KH'
,'2S','4S','KS'
,'6D'

