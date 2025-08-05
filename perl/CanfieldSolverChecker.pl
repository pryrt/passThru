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

        # check if any foundations need starting, and fill them immediately
        my $any = 0;
        for my $f ( 0 .. 3 ) {
            if( 0 == scalar @{ $foundation[$f] } ) {
                push @{ $foundation[$f] }, pop @reserve;
                $any = 1;
            }
        }
        if($any) { next MAINLOOP; }



        # probably never get here
        print "this next line should exit\n";
        last MAINLOOP;
    }

    dd { seed => $seed, reserve => \@reserve, stock => \@stock, foundation => \@foundation, tableau => \@tableau};
}

sub cardsort {
    my ($va,$sa) = split //, $a;
    my ($vb,$sb) = split //, $b;
    state %vals = ('A' => 1, 'T' => 10, 'J' => 11, 'Q' => 12, 'K' => 13); $vals{$_} = $_ for 1..13;
    state %sval = ('C'=>1, 'H'=>2, 'S'=>3, 'D'=>4);
    $_ = $vals{$_} for $va,$vb;
    $_ = $sval{$_} for $sa,$sb;
    return ($va <=> $vb) || ($sa <=> $sb);
}

__END__
,'5C','TC'
,'6H','KH'
,'2S','4S','KS'
,'6D'

