#!perl

use 5.014; # strict, //, s//r
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Math::Vector::Real;
use Math::Vector::Real::Bezier::Cubic;
use utf8;
use open ':std', ':encoding(UTF-8)';

BEGIN { $| = 1; }

my $actual = CubicBezier(V(0,0), V(0,0.5), V(0.5,1), V(1,1));

srand(19750118);
my @samples = map { print "$_, "; $actual->B($_) } sort 0,1, map {rand()} 1..9; print "\n";
print "$_\n" for @samples;
print "End Slopes: ", $actual->dBdt(0), " ... ", $actual->dBdt(1), "\n";

my $guess = CubicBezier(V(0,0), V(0,0.3), V(0.7,1), V(1,1));
while(1) {
    print "Training Loop:\n";
    printf "\tguess{%s} = %s\n", $_, $guess->{$_} for qw/p0 p1 p2 p3/;

    my @ΔP = (V(0,0), V(0,0), V(0,0), V(0,0));
    my $Vpx = V(map { $guess->{$_}[0] } qw/p0 p1 p2 p3/); # used for dot product with the time-vector for easily calculating αi
    my $Vpy = V(map { $guess->{$_}[1] } qw/p0 p1 p2 p3/); # used for dot product with the time-vector for easily calculating βi
    my $TotalDsq = 0;

    for my $i ( 0 .. $#samples ) {
        my $samp = $samples[$i];
        my $ti = closestPoint($guess, $samp);
        my $gi = $guess->B($ti);
        printf "\tclosestPoint(#%2d: %-48.48s) => t=%014.12f, out=%-48.48s\n", $i, $samp, $ti, $gi;

        my ($sxi, $syi) = @$samp;
        my ($gxi, $gyi) = @$gi;
        my $Vti = V(
            1 - 3*$ti + 3*$ti*$ti - $ti*$ti*$ti,
            0 +   $ti - 2*$ti*$ti + $ti*$ti*$ti,
            0 +           $ti*$ti - $ti*$ti*$ti,
            0 +                     $ti*$ti*$ti
        );
        printf "\t\tVtᵢ = %s\n", $Vti;
        my $αi = $Vpx * $Vti - $sxi;
        my $βi = $Vpy * $Vti - $syi;
        my $Disq = $αi*$αi + $βi*$βi;
        $TotalDsq += $Disq;
        printf "\t\tDᵢ² = αᵢ² + βᵢ² = (%.6f)² + (%.6f)² = %.6f   => ∑ = %.6f\n", $αi, $βi, $Disq, $TotalDsq;

=begin
        ΔP₀ₓ += (Sₓᵢ-Gₓ(tᵢ)) / (2⋅αᵢ⋅(1-3tᵢ+3tᵢ²-tᵢ³))          ΔP₀ᵧ += (Sᵧᵢ-Gᵧ(tᵢ)) / (2⋅βᵢ⋅(1-3tᵢ+3tᵢ²-tᵢ³))
        ΔP₁ₓ += (Sₓᵢ-Gₓ(tᵢ)) / (6⋅αᵢ⋅(   tᵢ-2tᵢ²+tᵢ³))          ΔP₁ᵧ += (Sᵧᵢ-Gᵧ(tᵢ)) / (6⋅βᵢ⋅(   tᵢ-2tᵢ²+tᵢ³))
        ΔP₂ₓ += (Sₓᵢ-Gₓ(tᵢ)) / (6⋅αᵢ⋅(       tᵢ²-tᵢ³))          ΔP₂ᵧ += (Sᵧᵢ-Gᵧ(tᵢ)) / (6⋅βᵢ⋅(       tᵢ²-tᵢ³))
        ΔP₃ₓ += (Sₓᵢ-Gₓ(tᵢ)) / (2⋅αᵢ⋅(           tᵢ³))          ΔP₃ᵧ += (Sᵧᵢ-Gᵧ(tᵢ)) / (2⋅βᵢ⋅(           tᵢ³))
=cut

        $ΔP[0][0] += ($sxi-$gxi) / (2*$αi*($Vti->[0]));         $ΔP[0][1] += ($syi-$gyi) / (2*$βi*($Vti->[0]));
        $ΔP[1][0] += ($sxi-$gxi) / (6*$αi*($Vti->[1]));         $ΔP[1][1] += ($syi-$gyi) / (6*$βi*($Vti->[1]));
        $ΔP[2][0] += ($sxi-$gxi) / (6*$αi*($Vti->[2]));         $ΔP[2][1] += ($syi-$gyi) / (6*$βi*($Vti->[2]));
        $ΔP[3][0] += ($sxi-$gxi) / (2*$αi*($Vti->[3]));         $ΔP[3][1] += ($syi-$gyi) / (2*$βi*($Vti->[3]));
        printf "\t\t$i# ΔP[%d] = %s\n", $_, $ΔP[$_] for 0..3;
    }
    printf "\tFINAL ΔP[%d] = %s\n", $_, $ΔP[$_] for 0..3;

=begin
    Math says ΔPₖ = ERR / ({∂/∂Pₖ}{Dᵢ²}) = ERR / (m*αᵢ*Vtᵢₖ)
	* ΔP[0] = {1.76228029758438e+15, 2886452118.93534}
	* ΔP[1] = {-175038592044.703, -1105901.88349331}
	* ΔP[2] = {-1342177425517.63, -1342178099202.71}
	* ΔP[3] = {-6.59706593186477e+18, -6.59706976665054e+18}

    Way too big; need to figure out what's going wrong.
        - well, for example, ideally Vt_sample0 = (1,0,0,0), which means all but k=0 will have huge denominators,
        - and at Vt_sampleN = (0,0,0,1), which means all but k=3 will have huge denominators
    Next TODO: maybe I should try the mathematically less rigorous, but possibly more-effective
            param += error * mu * denom instead of error / denom,
        which would make the change in parameter larger for when the time is close to that control,
        and smaller when it's farther in time
        ... that seems to be more like the ANN backprop of error times slope instead of error divided by slope
=cut

    last;# if $TotalDsq < 1e-6;
}
exit;

#  Calculate a point along a Bézier segment for a given parameter.
#   * curve  : now: a CubicBezier object        was: Array of vectors representing control points for a Bézier curve
#   * t      : Parameter [0,1] for how far along the curve the point should be
#   * tmps   : Array of temporary vectors (reduces memory allocations)
#   * returns: A vector representing the point on the curve at t
#
sub bézierPoint {
    my ($curve, $t) = @_;
    return $curve->B($t);
}

#  Find a minimum point for a bounded function. May be a local minimum.
#   * minX   : the smallest input value
#   * maxX   : the largest input value
#   * ƒ      : a function that returns a value `y` given an `x`
#   * ε      : how close in `x` the bounds must be before returning
#   * returns: the `x` value that produces the smallest `y`
#
sub localMinimum {
    my ($minX, $maxX, $ƒ, $ε) = @_;
    $ε //= 1e-10;
    my $minT=$minX;
    my $maxT=$maxX;
    my $k;
    while (($maxT-$minT)>$ε) {
        $k = ($maxT+$minT)/2;
        #printf STDERR "localMinimum(%5.3f,%5.3f,fn,%9.3e): maxT=%12.10f, minT=%12.10f, k=%12.10f\n", $minX, $maxX, $ε, $maxT, $minT, $k;
        if ($ƒ->($k-$ε) < $ƒ->($k+$ε)) {
            $maxT=$k;
        } else {
            $minT=$k;
        }
    }
    return $k;
}

#  Find the ~closest point on a Bézier curve to a point you supply.
#   * curve  : now: a CubicBezier object        was: Array of vectors representing control points for a Bézier curve
#   * pt     : The point (vector) you want to find out to be near
#   * returns: The parameter t representing the location of `out`
sub closestPoint {
    my ($curve, $pt) = @_;
    my $scans=25; # More scans -> better chance of being correct
    my $min = 'Inf';
    my $mindex;
    for my $i ( 0 .. $scans ) {
        my $out = bézierPoint($curve, $i/$scans);
        my $d2 = $pt->dist2($out);
        #printf STDERR "closestPoint bigLoop i=%02d, t=%.3f, out=%-32.32s, d2=%-8.6f, old min=%-8.6f \@ %d\n", $i, $i/$scans, $out, $d2, $min, $mindex//-1;
        if ($d2<$min) {
            $min=$d2;
            $mindex=$i;
        }
    }
    my $t0 = ((($mindex-1)/$scans)>0) ? (($mindex-1)/$scans) : 0;   # max
    my $t1 = ((($mindex+1)/$scans)<1) ? (($mindex+1)/$scans) : 1;   # min
    my $d2ForT = sub {
        my ($t) = @_;
        my $out = bézierPoint($curve,$t);
        return $pt->dist2($out);
    };
    return localMinimum($t0, $t1, $d2ForT, 1e-6);
}


__END__
My bestFitBezier.pl seems to not handle ... something ... correctly.
I think whether I alternated between parameters or did multiple adjustments
on one parameter before moving to the next, it would overoptimize to one
which then messed up the other.

<https://stackoverflow.com/questions/2742610/closest-point-on-a-cubic-bezier-curve>

Grabbing the javascript from the answer:<https://stackoverflow.com/a/44993719> (below),
I want to see if I can mimic that.  (And note: I really like the simplicity of the
demonstration implementation here:<http://phrogz.net/svg/closest-point-on-bezier.html>)

Keep my CubicBezier object and my random samples, but let's see if I can replicate the
implementation below, assuming those.

__TODO__
Now that I've got the closest point on my guess to each of the samples,
I think I can use the a,b,c,d formulas from <https://stackoverflow.com/a/57315396>
and then compute the partials { d(DSQ)/da, d(DSQ)/db, d(DSQ)/dc, d(DSQ)/dd } for
each of the points.  Then I would do the partials w/r/t param-n { da/dpₙ, db/dpₙ, dc/dpₙ, dd/dpₙ }
and appropriately sum together the contributions
    dD/dpₙ = sum { d(DSQ)/da * da/dpₙ, d(DSQ)/db * db/dpₙ, d(DSQ)/dc * dc/dpₙ, d(DSQ)/dd * dd/dpₙ }
(or alternatively, recompute from DSQ = (Bx(t))^2 + (By(t))^2, and do d(DSQ)/dpₙ directly,
which should give equivalent formula).

Then I would do Δpₙₓ = (Sₓ-Gₓ) / [ d(DSQ)/dpₙₓ ]
    where S=sample, G=guess
Add up all the Δpₙₓᵢ for each of the Sᵢ
Iterate.


__JAVASCRIPT__

/** Find the ~closest point on a Bézier curve to a point you supply.
 * out    : A vector to modify to be the point on the curve
 * curve  : Array of vectors representing control points for a Bézier curve
 * pt     : The point (vector) you want to find out to be near
 * tmps   : Array of temporary vectors (reduces memory allocations)
 * returns: The parameter t representing the location of `out`
 */
function closestPoint(out, curve, pt, tmps) {
    let mindex, scans=25; // More scans -> better chance of being correct
    const vec=vmath['w' in curve[0]?'vec4':'z' in curve[0]?'vec3':'vec2'];
    for (let min=Infinity, i=scans+1;i--;) {
        let d2 = vec.squaredDistance(pt, bézierPoint(out, curve, i/scans, tmps));
        if (d2<min) { min=d2; mindex=i }
    }
    let t0 = Math.max((mindex-1)/scans,0);
    let t1 = Math.min((mindex+1)/scans,1);
    let d2ForT = t => vec.squaredDistance(pt, bézierPoint(out,curve,t,tmps));
    return localMinimum(t0, t1, d2ForT, 1e-4);
}

/** Find a minimum point for a bounded function. May be a local minimum.
 * minX   : the smallest input value
 * maxX   : the largest input value
 * ƒ      : a function that returns a value `y` given an `x`
 * ε      : how close in `x` the bounds must be before returning
 * returns: the `x` value that produces the smallest `y`
 */
function localMinimum(minX, maxX, ƒ, ε) {
    if (ε===undefined) ε=1e-10;
    let m=minX, n=maxX, k;
    while ((n-m)>ε) {
        k = (n+m)/2;
        if (ƒ(k-ε)<ƒ(k+ε)) n=k;
        else               m=k;
    }
    return k;
}

/** Calculate a point along a Bézier segment for a given parameter.
 * out    : A vector to modify to be the point on the curve
 * curve  : Array of vectors representing control points for a Bézier curve
 * t      : Parameter [0,1] for how far along the curve the point should be
 * tmps   : Array of temporary vectors (reduces memory allocations)
 * returns: out (the vector that was modified)
 */
function bézierPoint(out, curve, t, tmps) {
    if (curve.length<2) console.error('At least 2 control points are required');
    const vec=vmath['w' in curve[0]?'vec4':'z' in curve[0]?'vec3':'vec2'];
    if (!tmps) tmps = curve.map( pt=>vec.clone(pt) );
    else tmps.forEach( (pt,i)=>{ vec.copy(pt,curve[i]) } );
    for (var degree=curve.length-1;degree--;) {
        for (var i=0;i<=degree;++i) vec.lerp(tmps[i],tmps[i],tmps[i+1],t);
    }
    return vec.copy(out,tmps[0]);
}
