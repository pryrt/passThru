#!perl

use 5.014; # //, strict, say, s///r
use warnings;
use POSIX qw/M_PI M_PI_2 M_PI_4/;
use Audio::Wav;
my $wav = Audio::Wav->new();
my $sample_rate = 11025;
my $bits_sample = 8;
my $channels = 3;
my $details = {
    'bits_sample'   => $bits_sample,
    'sample_rate'   => $sample_rate,
    'channels'      => $channels,
};

my $writer = $wav->write('./out.wav', $details);
my $f = 110;
my $L = $sample_rate * 5;   # 5 seconds of A
for my $x ( 0 .. $L-1 ) {
    my $t = $x / $sample_rate;
    #my $y = 128 + 2 * sin(2*M_PI*$f*$t);
    #$y = ($y<0) ? 0 : ($y>255) ? 255 : $y;

    # despite what I thought I figured out before,
    # even 8bit mono does appear to be 2s complement,
    # because volume adjustments work right here,
    # whereas they weren't if I used 128+A*sin
    my @ys;
    for my $p ( 3, 6, 10) {
        my $freq = $f * (2 ** ($p/12));
        my $y = 100 * sin(2*M_PI*$freq*$t);
        $y = ($y<-128) ? -128 : ($y>127) ? 127 : $y;
        push @ys, $y;
    }
    $writer->write(map { $_/$channels} @ys); # need to write a value for every channel (only one in this example)
}

