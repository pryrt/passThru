use FindBin;
use local::lib "$FindBin::Bin/tmplib";

use warnings;
use strict;
use feature ':5.10';
my @accel = ([-0.7437,0.1118,-0.5367],
             [-0.5471,0.0062,-0.6338],
             [-0.6437,0.1216,-0.5255],
             [-0.4437,0.3216,-0.3255],
);  # note: I changed from an array whose only element is an arrayref of arrayrefs to an array who has n arrayrefs, to be a simple 2D array

use Math::Spline;
if(0) { # verify it works based on the Math::Spline EXAMPLE and SYNOPSIS
    my @x = (1,3,8,10);
    my @y = (1,2,3,4);
    my $spline = Math::Spline->new(\@x,\@y);
    my $y_interp = $spline->evaluate(my $x = 5);
    printf "evaluate(x=%s) => y=%s\n", $x, $y_interp;

    require Math::Derivative;
    my @y2 = Math::Derivative::Derivative2(\@x, \@y);
    my $index_b =  Math::Spline::binsearch(\@x, $x);
    my $index_l =  Math::Spline::linsearch(\@x, $x, $index_b);
    $y_interp =  Math::Spline::spline(\@x, \@y, \@y2, $index_l, $x);
    printf "spline(\\\@x, \\\@y, \\\@y2, index_l=%s, x=%s) {index_b=%s} =>  y=%s\n", $index_l, $x, $index_b, $y_interp;
    # I don't see a good reason for that form, unless you want to manually do the derivatives;
    #   the ->new and ->evaluate already handle taking the derivatives
}

if(0) { # I will try to implement what I believe your goal is:
    my (@x,@y,@z);
    my ($xmin, $xmax) = (9.99e99,-9.99e99); # for tracking min and max x values
    # generate x, y, and z arrays
    for my $xyz (@accel) {
        push @x, $xyz->[0];
        push @y, $xyz->[1];
        push @z, $xyz->[2];

        if($x[-1] < $xmin) { $xmin = $x[-1]; }
        if($x[-1] > $xmax) { $xmax = $x[-1]; }
    }
    # create spline calculators for x&y and x&z
    my $spline_xy = eval { Math::Spline::->new(\@x, \@y) } or do { die "xy: $@" };
    my $spline_xz = eval { Math::Spline::->new(\@x, \@z) } or do { die "yz: $@" };

    my @interp_accel = ();
    my $NSTEPS = 200;
    my $dx = ($xmax-$xmin)/$NSTEPS; # $NSTEPS+1 values from xmin to xmax, inclusive
    for my $i (0..$NSTEPS) {
        my $x = $xmin + $dx * $i;
        my $y = defined($spline_xy) ? $spline_xy->evaluate($x) : undef;
        my $z = defined($spline_xz) ? $spline_xz->evaluate($x) : undef;
        push @interp_accel, [$x,$y,$z]; # store for later
        printf "interpolate # %d => [%s,%s,%s]\n", $i, map {$_//'<undef>'} $x, $y, $z;  # debug print
    }
}

if(0) { # modified by id://11152081 interpretation
    my (@x,@y,@z,@t);
    # generate x, y, and z arrays, and a t array
    my $pt = 0;
    for my $xyz (@accel) {
        push @t, $pt++;
        push @x, $xyz->[0];
        push @y, $xyz->[1];
        push @z, $xyz->[2];
    }
    # create spline calculators for x&y and x&z
    my $spline_tx = eval { Math::Spline::->new(\@t, \@x) } or do { die "ty: $@" };
    my $spline_ty = eval { Math::Spline::->new(\@t, \@y) } or do { die "ty: $@" };
    my $spline_tz = eval { Math::Spline::->new(\@t, \@z) } or do { die "tz: $@" };

    my @interp_accel = ();
    my $NSTEPS = 200;
    my $dt = $pt/$NSTEPS; # $NSTEPS+1 values from xmin to xmax, inclusive
    for my $i (0..$NSTEPS) {
        my $t = $i * $dt;
        my $x = $spline_tx->evaluate($t);
        my $y = $spline_ty->evaluate($t);
        my $z = $spline_tz->evaluate($t);
        push @interp_accel, [$x,$y,$z]; # store for later
        printf "interpolate # %d => t=%.2f => [%s,%s,%s]\n", $i, map {$_//'<undef>'} $t, $x, $y, $z;  # debug print
    }
}

if(1) { # [id://11152085] requested Bezier version
    # add three more observations, to show it works with more than 4 points
    push @accel, [-0.2718,0.3142,-0.1618];
    push @accel, [-0.4567,0.1234,+0.1618];
    push @accel, [-0.9876,0.5432,+0.3162];


    die "requires 3N+1 points, supplied ".scalar(@accel)." points" unless 1 == scalar(@accel) % 3;
    my $first = 0;
    my @interp_accel = ();
    my $NSTEPS = 100;
    my $dt = 1/$NSTEPS;
    my $grp = 0;
    while($first+3 < @accel) {
        my (@idx) = map {$first+$_} 0..3;
        my $t = @interp_accel ? $dt : 0;
        while($t < 1+$dt) {
            my @m = (   (1-$t)**3,
                        (1-$t)**2 * ($t)**1 * 3,
                        (1-$t)**1 * ($t)**2 * 3,
                                    ($t)**3
                    );
            my $x = 0; $x += $m[$_] * $accel[$idx[$_]][0] for 0..3;
            my $y = 0; $y += $m[$_] * $accel[$idx[$_]][1] for 0..3;
            my $z = 0; $z += $m[$_] * $accel[$idx[$_]][2] for 0..3;

            printf "interpolate t=%.3f => [%+-7.4f,%+-7.4f,%+-7.4f]\n", $grp+$t, $x, $y, $z if $t<=2*$dt or $t>=$dt*($NSTEPS-2);  # debug print
            print "...\n" if $t==3*$dt;
            push @interp_accel, [$x,$y,$z];

            $t += $dt;
        }
        ++$grp;
        $first += 3;
    }
}
