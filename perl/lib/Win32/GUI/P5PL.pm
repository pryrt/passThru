package Win32::GUI::P5PL;
use 5.014;
use warnings;
our $VERSION = 0.001000;
use Win32::GUI::P5PL::App();
use Exporter 5.57 qw/import/;
use Carp;

our @EXPORT = qw/createCanvas background/;



# the p5*js style functions get defined here

sub createCanvas
{
    my ($w, $h) = @_;
    #print STDERR "aw = $Win32::GUI::P5PL::App::appWin\n";
    $Win32::GUI::P5PL::App::appWin->p5plCANVAS->Resize($w,$h);
    my $wh = $Win32::GUI::P5PL::App::appWin->Height();
    my $ww = $Win32::GUI::P5PL::App::appWin->Width() ;

    my $sh = $Win32::GUI::P5PL::App::appWin->ScaleHeight();
    my $sw = $Win32::GUI::P5PL::App::appWin->ScaleWidth();

    my $GUI_h = $wh - $sh;
    my $GUI_w = $ww - $sw;

    my $need_h = $GUI_h + 10 + 50 + 10 + $h + 10;   # GUI_h(TITLE+borders) + gap before, button, gap between, $h, gap after
    my $need_w = $GUI_w + 10 + $w + 10;             # GUI_w(borders) + gap before, $w, gap after

    my $new_wh = ($need_h > $wh) ? $need_h : $wh;
    my $new_ww = ($need_w > $ww) ? $need_w : $ww;
    $Win32::GUI::P5PL::App::appWin->Resize($new_ww,$new_wh);
    #print STDERR "resize: canvas($w x $h), win($ww x $wh): scaled($sw x $sh) vs needed($need_w x $need_h) => new($new_ww x $new_wh)\n";

    return $Win32::GUI::P5PL::App::appWin->p5plCANVAS;
}

*resizeCanvas = \&createCanvas;

sub background
{
    my ($r,$g,$b) = @_;
    my $c;
    if($r =~ /^rgba?\x28\h*(\d+)\h*,\h*(\d+)\h*,\h*(\d+)\h*(?:,\h*(\d+)\h*)\x29/) { # rgb(r,g,b) or rgba(r,g,b,a)
        ($r,$g,$b,my $a) = ($1,$2,$3,$4);
    } elsif($r =~ /^rgba?\x28\h*(\d+)%\h*,\h*(\d+)%\h*,\h*(\d+)%\h*(?:,\h*(\d+)\h*)\x29/) { # rgb(r,g,b) or rgba(r,g,b,a) in percent
        ($r,$g,$b,my $a) = ($1,$2,$3,$4);
        ($r,$g,$b) = map {int($_/100*255)} $r,$g,$b;    # 100pct to 255
    } elsif ($r =~ /^#([a-z0-9]{6}|[a-z0-9]{3})$/i ) {
        $c = $r;
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
    print STDERR "background($c)\n";
}

# private functions

sub _awh { $Win32::GUI::P5PL::App::appWin->Height() }
sub _aww { $Win32::GUI::P5PL::App::appWin->Width() }
sub _aw { $Win32::GUI::P5PL::App::appWin }
sub _awCanvas { $Win32::GUI::P5PL::App::appWin->p5plCANVAS }

1;
