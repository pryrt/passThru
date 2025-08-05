#!perl
# solving my app's Canfield (draw by 1) rules
#   - Reserve gets pop'd onto first empty tableau at all times
#   - Stock is revealed one at a time (pop from list)
#   - Tableau's initially get populated from the last four cards of the initial Reserve, alternating color descending rank
#   - Foundations from A,2,...,Q,K of single suit

use 5.014; # //, strict, say, s///r
use warnings;
use Data::Dump;
$| = 1;

my @init_reserve = ('?','?','?','?','?','?','?','?','8C','7D','9S','8H','AD','7H','JH','TD','5D','JD');
my @init_stock = ('TH','2H','9H','KC','5H','7S','7C','JC','4C','8S','TS','4H','KD','3H','AH','2C','9D','4D','AC','6C','3D','QD','3S','QC','6S','AS','5S','QH','2D','QS','8D','3C','9C','JS');

one_game(undef, \@init_reserve, \@init_stock, [[],[],[],[]], [[],[],[],[]]);

sub one_game {
    my ($seed, $rreserve, $rstock, $rfoundation, $rtableau) = @_;
    if(defined $seed) { srand $seed; } else { $seed = srand; } # in 5.14 and newer, the retval of srand will be the seed, so I can know what it is in the future
    my @reserve = @$rreserve;   # make a copy
    my @stock = @$rstock;      # make a copy
    my @foundation = @$rfoundation;
    my @tableau = @$rtableau;

    MAINLOOP: while(1) {
        # check for unknown reserve, and exit, because we've found a viable path to the next card
        if ($reserve[-1] eq '?') {
            last MAINLOOP;
        }

        # check if any tableaus need starting, and fill them immediately
        my $any = 0;
        for my $t ( 0 .. 3 ) {
            if( 0 == scalar @{ $tableau[$t] } ) {
                # can only do the auto-fill if there is something left in the reserve
                if(scalar @reserve) {
                    push @{ $tableau[$t] }, pop @reserve;
                    $any = 1;
                }
            }
        }
        if($any) { next MAINLOOP; }

        # if there's still an empty tableau, _may_ choose to fill it from stock
        for my $t ( 0 .. 3 ) {
            if( 0 == scalar @{ $tableau[$t] } ) {
                if(scalar(@stock) and rand() < 0.5) {
                    push @{ $tableau[$t] }, pop @stock;
                    next MAINLOOP;
                }
            }
        }

        # check if next reserve can be moved onto its foundation:
        if(scalar @reserve) {
            my $card = $reserve[-1];
            my $v = cardval($card);
            my $f = suitval($card);    # foundation number is suit value
            if($v == 1 + scalar @{ $foundation[$f] }) {     # if the foundation has 1 card (A) and the value is 1+1=2, then the 2 of that suit can be added to the foundation
                if(rand() < 0.5) {
                    push @{ $foundation[$f] }, pop @reserve;
                    next MAINLOOP;
                }
            }
        }

        # check if next stock can be moved onto its foundation:
        if(scalar @stock) {
            # TODO: this is duplicated from above, need to separate it out into a function to follow DRY
            my $card = $stock[-1];
            my $v = cardval($card);
            my $f = suitval($card);    # foundation number is suit value
            if($v == 1 + scalar @{ $foundation[$f] }) {     # if the foundation has 1 card (A) and the value is 1+1=2, then the 2 of that suit can be added to the foundation
                if(rand() < 0.5) {
                    push @{ $foundation[$f] }, pop @reserve;
                    next MAINLOOP;
                }
            }
        }

        # TODO: here
        # look for fillable foundations
        for my $f ( 0 .. 3 ) {
            1;
        }

        # probably never get here
        last MAINLOOP;
    }

    dd { seed => $seed, reserve => \@reserve, stock => \@stock, foundation => \@foundation, tableau => \@tableau};
}

sub cardval {
    my($card) = @_;
    state %vals = ('?' => 0, 'A' => 1, 'T' => 10, 'J' => 11, 'Q' => 12, 'K' => 13); $vals{$_} = $_ for 0..13;
    return $vals{ substr($card,0,1) };
}

sub suitval {
    my ($card) = @_;
    state %sval = ('C'=>0, 'H'=>1, 'S'=>2, 'D'=>3); $sval{$_} = $_ for 0..3;
    return $sval{ substr($card,1,1) };
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

