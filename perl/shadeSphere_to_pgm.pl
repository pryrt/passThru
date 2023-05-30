#!perl
# https://rosettacode.org/wiki/Draw_a_sphere#Perl

use 5.014; # strict, //, s//r
use warnings;
$| = 1;

my ($x,$y) = (255)x2;
$x |= 1;    # must be odd   -- obviously, 255 is odd, but if I change the number(s) above, this makes it odd again
my $depth = 255;
#my $light = Vector->new(1-rand 2,rand,rand)->normalized; print STDERR "# $light\n";
my $light = Vector->new(sqrt(.75),.300,.400)->normalized; print STDERR "# $light\n";

print "P2\n$x $y\n$depth\n";

my ($r, $ambient) = (($x-1)/2, 0.9);
my $r2 = $r**2;
{
    for my $y (-$r .. $r) {
        my $y2 = $y**2;
        for my $x ( -$r .. $r ) {
            my $x2 = $x**2;
            my $pixel = 0;
            if($x2+$y2 <= $r2) {
                my $v = Vector->new($x, $y, sqrt($r2-$x2-$y2))->normalized;
                my $I = $light . $v + $ambient; # ($light . $v)*(1-$ambient) + $ambient;    # orig: $light . $v + $ambient;
                $I = ($I < 0) ? 0 : ($I > 1) ? 1 : $I;
                $pixel = int($I * $depth);
            }
            if($x==$r-1 and $y==-$r+1) { $pixel = $depth-$pixel; }
            print $pixel, ($x==$r) ? "\n" : " ";
        }
    }
}

package Vector {
    sub new {
        my $class = shift;
        bless ref($_[0]) eq 'Array' ? $_[0] : [@_], $class;
    }
    sub normalized {
        my $this = shift;
        my $norm = sqrt($this . $this);
        ref($this)->new(map $_/$norm, @$this);
    }
    use overload
        '.' => sub {
            my ($left,$right,$swap) = @_;
            if(!ref($right)) { return $swap ? "$right" . "$left" : "$left" . "$right";}
            my $sum = 0;
            for( 0 .. $#$left) {
                $sum += $left->[$_] * $right->[$_];
            }
            return $sum;
        },
        '""' => sub {
            sprintf "Vector:[%s]", join ' ', @{shift()};
        };
}

=begin PeterNotes

So, it starts by doing a random unit vector as the light direction vector
It defines the center as 0,0
it goes from -r to +r in each dimension, calculates the pixel intensity (below), outputs it as the pixel value, and at the end of each row does a newline (that gives thes PGM format, which ImageMagick can read)
Intensity:
    - calculate z in (x,y,z) coords from x**2+y**+z**2 = r**2 with others known: z = sqrt(rr-xx-yy)
    - the dot product of <light> and unit(x,y,z) indicates what fraction of the light should be in the direction(x,y,z)
    - they did I = dot_product + ambient, which are both fractions, and clamped I from 0..1, then scaled by depth to give the pixel value
    - but I changed it to I = dot*(1-ambient) + ambient
        - this way, if ambient is 25%, then I scale the dot product by 75%, so that the total of the brightest point is always 100%
          and the total of the darkest point (no light) is the ambient value.
        - with theirs, ambient=50% has part of it completly lost in shadow; with mine, I can see the whole sphere
    - scale I * depth to give pixel color

To translate this to a full-color, I would want to know the color for the darkest (Cd) and the color for the brightest (Cb),
and I would interpolate to get the pixel color Cp = (Cb-Cd)*dot+Cd .
=cut
1;
