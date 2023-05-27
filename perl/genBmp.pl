#!perl
use 5.012; # //, strict, say
use warnings;
use autodie;
use GD 2.7601;  # my patched GD with gdImageBmp support brought out

my $im = GD::Image::->new(8,8);
my $bg = $im->colorAllocate(192,192,192);
my $fg = $im->colorAllocate(0,255,0);
$im->fill(0,0,$bg);
$im->filledRectangle(2,2,5,5,$fg);
do { open my $fh, '>:raw', 'gen.png'; print {$fh} $im->png; };
do { open my $fh, '>:raw', 'gen.bmp'; print {$fh} $im->bmp(0); };   # verify that bmp works uncompressed
do { open my $fh, '>:raw', 'genc.bmp'; print {$fh} $im->bmp(1); };  # verify that compressed is smaller
