#!perl
use 5.014; # //, strict, say, s///r
use warnings;
use utf8;
use Math::Vector::Real qw/V/;
use POSIX qw/M_PI floor ceil/;

# want a Spherical Earth of Volume = (4π/3)⋅R³
# then transform it into a torus of equal volume, with primary radius equal,
#   V = (π⋅r²)⋅(2⋅π⋅R) = 2⋅π²⋅r²⋅R      = (4π/3)⋅R³
#   r = R⋅√(2/(3⋅π))
sub π { M_PI }
my $V = 5000;       # want a big enough volume to fill about 1000 voxels to make up the torus
my $R = ($V/4*3/π)**(1/3);
my $r = $R*sqrt(2/(3*π));

sub pointInsideTorus {
    my ($pt, $R, $r) = @_;
    my $psq = $pt->norm2;
    return 0 if $psq < $r*$r;
    return 0 if $psq > ($R+$r)**2;
    my $vc = ($pt->[0] || $pt->[1]) ? V( $pt->[0], $pt->[1], 0 )->versor() * $R : V(0,0,0);
    my $dsq = $vc->dist2($pt);
    return 0 if $dsq > $r;
    return 1;
}

# verification
my $p0 = V(0,0,0);          # printf "%-64.64s => %d\n", $p0, pointInsideTorus($p0, $R, $r);
my $p3 = V($R,$R,$r);       # printf "%-64.64s => %d\n", $p3, pointInsideTorus($p3, $R, $r);
my $p1 = V($R,0,0);         # printf "%-64.64s => %d\n", $p1, pointInsideTorus($p1, $R, $r);
my $p2 = V($R,0,$r*1.1);    # printf "%-64.64s => %d\n", $p2, pointInsideTorus($p2, $R, $r);

# load the torus with any voxels that are inside the torus
sub DBG_LAYERS { 0 }
my @torus = ();
my $maxR = ceil($R) + 1;
my $maxr = ceil($r) + 1;
for my $y ( -$maxR .. +$maxR ) {
    for my $z ( -$maxr .. +$maxr  ) {
        for my $x ( -$maxR .. +$maxR  ) {
            my $pt = V($x,$y,$z);
            my $in = pointInsideTorus($pt, $R, $r);
            print +$in ? $in : " "  if DBG_LAYERS;
            push @torus, $pt if $in;
        }
        print "\n"  if DBG_LAYERS;
    }
    print "\n"  if DBG_LAYERS;
}

# calculate the total directional acceleration (|1/r**2|*dir()) on any given point
# only need one slice at y==0, because of symmetry
$| = 1;
my $maxa = 0;
for my $y ( 0 .. 0 ) {
    for my $z ( -$maxr .. +$maxr  ) {
        for my $x ( -$maxR .. +$maxR  ) {
            my $pt = V($x,$y,$z);
            my $in = pointInsideTorus($pt, $R, $r);
            my $acc = V(0,0,0);
            for my $voxel ( @torus ) {
                my $del = $voxel - $pt;
                my $rsq = $del->norm2();
                my $dir = $rsq ? $del->versor() : V(0,0,0);
                if($rsq) {
                    $acc += $dir / $rsq;
                }
            }
            my $upt = abs($pt) ? -$pt->versor() : V(0,0,0);
            my $aa = abs($acc);
            my $ua = $aa ? $acc->versor() : V(0,0,0);
            if($aa > $maxa) { $maxa = $aa; }
            print "$pt => acc:$acc:$aa\t$maxa\n" if DBG_LAYERS;
        }
    }
}

# so with my example $V=5000, looks like I could use a sliced voxel size of 30x30 pixels
#   and be able to show the acceleration vector
