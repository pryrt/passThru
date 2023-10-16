#!perl
use 5.014; # strict, //, s//r
use warnings;
use GD;
use autodie;

my $img = GD::Image->new(100,100);
$img->colorResolve(63,63,63);

if(0) {
open my $fh, '>:raw', 'out.png';
print {$fh} $img->png();
close($fh);
}

if(0) {
    open my $fh, '>:raw', 'out.gif';
    print {$fh} $img->gif();
    close($fh);
}

if(1) {
    # with global palette, https://pryrt.com/cgi-bin/radial works, so try to mimic that here
    #for(1..200) { $img->colorResolve(rand 255, rand 255, rand 255); }
    #   okay, with preResolve, begin(1,0), add(0,0,0,time); => it works
    #   with no preResolve, begin(0,0), add(1,0,0,time); => it works
    my $gifdata = $img->gifanimbegin(0,0);
    my $fg = $img->colorResolve(0,0,255);  print STDERR "resolved to $fg\n";
    $gifdata .= $img->gifanimadd(1,0,0,20);
    $img->filledRectangle(10,10,90,90,$fg);
    $gifdata .= $img->gifanimadd(1,0,0,20);
    $gifdata .= $img->gifanimend();
    open my $fh, '>:raw', 'anim.gif';
    print {$fh} $gifdata;
    close($fh);
}
