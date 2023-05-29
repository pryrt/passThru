package Win32::GUI::P5PL::App;
our $VERSION = 0.001000;
use Win32::GUI();
use Win32::GUI::Constants qw{/^MB_/};

our $appWin;
my $awTitleBase = "p5*pl v$VERSION";
my $awTitle = $awTitleBase;

sub launch
{
    $awTitle = (caller(0))[1] . " - $awTitleBase";
    $appWin = Win32::GUI::Window->new(
        -name => 'p5pl',
        -text => $awTitle,
        -width  => 640,
        -height => 480,
        -eventmodel => 'byref',
        -dialogui => 1, # accept ENTER/ESC
    );
    $appWin->AddButton(
        -name       => 'p5plPLAY',
        -text       => 'run',
        -ok         => 1,
        -size       => [50,50],
        -pos        => [10,10],
        -onClick    => \&push_play,
        #-background => '#00FF00',
    );
    $appWin->AddButton(
        -name   => 'p5plSTOP',
        -text   => 'stop',
        -cancel => 1,
        -size   => [50,50],
        -pos    => [70,10],
        -onClick    => \&push_stop,
        #-background => '#0000FF',
    );
    $appWin->Show();
    Win32::GUI::Dialog();
}

my $playing = 0;
sub push_play
{
    if($playing) {return 0;} # don't restart
    $playing = 1;
    $appWin->MessageBox("PLAY", $awTitle, MB_OK);
}

sub push_stop
{
    if(!$playing) {return 0;} # don't need to stop twice
    $playing = 0;
    $appWin->MessageBox("STOP", $awTitle, MB_OK);
}

1;
