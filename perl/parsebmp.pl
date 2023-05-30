#!perl -l

use 5.014; # strict, //, s//r
use warnings;
use GD 2.77;
use MIME::Base64;

my %clr;
my $img = GD::Image->newFromBmp('playing.bmp');
for my $y (0 .. $img->height-1) {
    for my $x (0 .. $img->width-1) {
        my $c = $img->getPixel($x,$y);
        next if $c =~ 0xFFFFFF;
        my ($r,$g,$b) = $img->rgb($c);
        #printf "%02d,%02d:#0x%06X:%03d,%03d,%03d\n", $x, $y, $c, $r, $g, $b;
        $clr{$c} = [ $r, $g, $b ];
        ($r,$g,$b) = ($g,255-3*(255-$r),$b);                # try just swapping red and green: ($g,$r,$b)
        $g = $g<0 ? 0 : $g>255 ? 255 : $g;
        my $nc = $img->colorResolve($r,$g,$b);
        $img->setPixel($x,$y,$nc);
    }
}
use autodie;
open my $fh, '>:raw', 'playing_green.bmp';
print {$fh} $img->bmp(0);

## #use Data::Dump; dd \%clr;
## for my $c ( sort { $clr{$b}[0]**2 + $clr{$b}[1]**2 + $clr{$b}[2]**2 <=> $clr{$a}[0]**2 + $clr{$a}[1]**2 + $clr{$a}[2]**2 or $b cmp $a} keys %clr ) {
##     printf "0x%06X: %3d, %3d, %3d\n", $c, @{$clr{$c}};
## }
__END__
0xFAF2F5: 250, 242, 245
0xF9D6E0: 249, 214, 224
0xFAC2D3: 250, 194, 211
0xF7B8CB: 247, 184, 203
0xF6AEC3: 246, 174, 195
0xF5A5BC: 245, 165, 188
0xF487A7: 244, 135, 167
0xF27D9F: 242, 125, 159
0xF26A91: 242, 106, 145
0xF25F89: 242,  95, 137
0xF15F8A: 241,  95, 138
0xF04C7B: 240,  76, 123
0xEF4174: 239,  65, 116
0xEE2D65: 238,  45, 101
0xED235D: 237,  35,  93
0xED225D: 237,  34,  93
