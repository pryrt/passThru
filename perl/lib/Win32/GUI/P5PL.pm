package Win32::GUI::P5PL;
use 5.014;
use warnings;
our $VERSION = 0.001000;
use Win32::GUI::P5PL::App();
use Exporter 5.57 qw/import/;
use Carp;
use MIME::Base64();
use GD 2.77;

our @EXPORT = qw/createCanvas background/;

my $img;
sub _pushImg { Win32::GUI::P5PL::App::updateBitmap(MIME::Base64::encode($img->bmp())) }

# the p5*js style functions get defined here

# TODO:
#   I want all the GD::Image stuff in P5PL, but the Win32::GUI stuff in App
#   - ::App needs a way to requestResize(w,h), and I would call that App::requestResize from createCanvas()
#   - ::App needs an setBmpFromB64, which takes as its input MIME::Base64::encode( $img->bmp() ), where $img = GD::Image
#   - these P5PL functions will be what changes pixels in the GD::Image, and then they'll push the bmp to the ::App::setBmpFromB64()

sub createCanvas
{
    my ($w, $h) = @_;
    Win32::GUI::P5PL::App::requestCanvasSize($w,$h);

    $img = GD::Image->new($w,$h,1);
    _pushImg();
}

*resizeCanvas = \&createCanvas;

sub background
{
    my ($r,$g,$b,$a) = @_;
    my $c;
    if($r =~ /^rgba?\x28\h*(\d+)\h*,\h*(\d+)\h*,\h*(\d+)\h*(?:,\h*(\d+)\h*)?\x29/) { # rgb(r,g,b) or rgba(r,g,b,a)
        ($r,$g,$b,$a) = ($1,$2,$3,$4);
    } elsif($r =~ /^rgba?\x28\h*(\d+)%\h*,\h*(\d+)%\h*,\h*(\d+)%\h*(?:,\h*(\d+)\h*)?\x29/) { # rgb(r,g,b) or rgba(r,g,b,a) in percent
        ($r,$g,$b,my $a) = ($1,$2,$3,$4);
        ($r,$g,$b) = map {int($_/100*255)} $r,$g,$b;    # 100pct to 255
    } elsif ($r =~ /^#([a-z0-9]{6}|[a-z0-9]{3})$/i ) {
        $c = $r;    # TODO: fix this version
    } elsif (ref($r)) {
        ($r,$g,$b) = @$r;
    } elsif ($r =~ /^[0-9a-z]+$/i && !defined($g) && !defined($b)) {    # one color value means greyscale
        ($g,$b) = ($r,$r);
    } elsif ($r =~ /^[0-9a-z]+$/i && $g =~ /^[0-9a-z]+$/i && $b =~ /^[0-9a-z]+$/i) {
        # no conversion
    } else {
        local $" = ", ";
        croak "don't know background(@_)";
    }
    $c = sprintf("#%02X%02X%02X", $r, $g, $b);  # skip alpha for now
    printf STDERR "background($r,$g,$b)\n";

    $img->fill(0,0, $img->colorResolve($r,$g,$b));  # TODO: incorporate alpha if available
    _pushImg();
}

1;
