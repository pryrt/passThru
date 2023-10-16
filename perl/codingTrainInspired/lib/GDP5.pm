package GDP5;
# P5.js-inspired wrapper for GD::Image (it does not implement everything, or even most things; it's just inspired by)
use 5.014; # strict, //, s//r
use warnings;
use Exporter 5.57 'import';
use GD;     # if GD::VERSION_STRING eq '2.2.5', see https://libgd.github.io/manuals/2.2.5/files/preamble-txt.html
use Data::Dumper;

our @EXPORT = qw{gd createCanvas};

my ($callerPackage, $symTable);
my ($defaultCanvasGD, $gifdata);
my ($doLoop) = 1;
my ($fps) = 33;   # frames per second
our $AppName;
sub gd { $defaultCanvasGD } # gives direct access to GD object

sub Run {
    ($AppName) = @_;
    die "Need an AppName" unless defined $AppName;

    $callerPackage = (caller)[0];
    $symTable = do { no strict 'refs'; \%{"${callerPackage}::"}; };

    _preload();
    _setup();
    _drawLoop();
    _save();
}

sub _preload {
    return unless exists $symTable->{preload};
    print STDERR "will run ${callerPackage}::preload()...\n";
    $symTable->{preload}->();
}
sub _setup {
    return unless exists $symTable->{setup};
    print STDERR "will run ${callerPackage}::setup()...\n";
    $symTable->{setup}->();
}
sub _drawLoop {
    return unless exists $symTable->{draw};
    while(1) {
        $symTable->{draw}->();
        if($defaultCanvasGD) {
            $gifdata .= $defaultCanvasGD->gifanimadd(1,0,0,10); #(0,0,0,int(100/$fps));
            # print STDERR Dumper {drawLoop => $gifdata};
        }
        last unless $doLoop;
    }
    if($defaultCanvasGD) {
        $gifdata .= $defaultCanvasGD->gifanimend;
        # print STDERR Dumper {endDrawLoop => $gifdata};
    }
}
sub _save {
    if($defaultCanvasGD && $gifdata) {
        use autodie;
        my $filename = "${AppName}.gif";
        open my $fh, '>:raw', $filename;
        print {$fh} $gifdata;
        close $fh;
    }
}

sub noLoop {
    $doLoop = 0;
}

sub createCanvas {
    my ($w,$h) = @_;
    # TODO: if not void context, create a new one
    $defaultCanvasGD = GD::Image::->new($w,$h,0);
    $gifdata = $defaultCanvasGD->gifanimbegin(0,0);
    # print STDERR Dumper {createCanvas => $gifdata};
    return $defaultCanvasGD;
}

sub background {
    my ($r,$g,$b,$a) = @_;
    die "Must supply color for background!" unless defined $r;
    unless(defined $g) { $g = $r; $b = $r; $a = 0; }
    unless(defined $a) { $a = 0; }  # 0 means opaque, 127 means transparent
    my $bg = $defaultCanvasGD->colorResolveAlpha($r,$g,$b,$a);
    $defaultCanvasGD->filledRectangle(0,0, $defaultCanvasGD->width, $defaultCanvasGD->height, $bg);
}

1;
