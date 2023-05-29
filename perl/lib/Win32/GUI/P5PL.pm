package Win32::GUI::P5PL;
use 5.014;
use warnings;
our $VERSION = 0.001000;
use Win32::GUI::P5PL::App();
use Exporter 5.57 qw/import/;

our @EXPORT = qw/createCanvas/;



# the p5*js style functions get defined here

sub createCanvas
{
    my ($w, $h) = @_;
    print STDERR "aw = $Win32::GUI::P5PL::App::appWin\n";
    $Win32::GUI::P5PL::App::appWin->p5plCANVAS->Resize($w,$h);
    if(80 + $h > $Win32::GUI::P5PL::App::appWin->Height()) {
        $Win32::GUI::P5PL::App::appWin->Height(80 + $h);
    }
    if(20 + $w > $Win32::GUI::P5PL::App::appWin->Width()) {
        $Win32::GUI::P5PL::App::appWin->Width(20 + $w);
    }
}

*resizeCanvas = \&createCanvas;

# private functions

sub _awh { $Win32::GUI::P5PL::App::appWin->Height() }
sub _aww { $Win32::GUI::P5PL::App::appWin->Width() }
sub _aw { $Win32::GUI::P5PL::App::appWin }
sub _awCanvas { $Win32::GUI::P5PL::App::appWin->p5plCANVAS }

1;
