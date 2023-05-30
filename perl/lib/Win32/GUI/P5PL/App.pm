package Win32::GUI::P5PL::App;
our $VERSION = 0.001000;
use Win32::GUI();
use Win32::GUI::Constants qw{/^MB_/};
use Win32::GUI::BitmapInline();

our $appWin;
my $awTitleBase = "p5*pl v$VERSION";
my $awSource = '';
my $awTitle = $awTitleBase;
my ($bmpPlay, $bmpPlaying, $bmpStop, $bmpStopped) = _play_icons();
my $bmpCanvas;

sub launch
{
    $awSource = (caller(0))[1];
    $awTitle = "$awSource - $awTitleBase";
    $appWin = Win32::GUI::Window->new(
        -name => 'p5pl',
        -text => $awTitle,
        -width  => 320,
        -height => 240,
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
        -bitmap     => $bmpPlay,
    );
    $appWin->AddButton(
        -name   => 'p5plSTOP',
        -text   => 'stop',
        -cancel => 1,
        -size   => [50,50],
        -pos    => [70,10],
        -onClick    => \&push_stop,
        -bitmap     => $bmpStopped,
    );
    $appWin->AddLabel(
        -name   => 'p5plCANVAS',
        -pos    => [10,70],
        -size   => [50,50],
        -sunken => 1,
    );

    $appWin->Show();
    Win32::GUI::Dialog();
}

my $playing = 0;
sub push_play
{
    if($playing) {return 0;} # don't restart
    $appWin->p5plPLAY->Change(-bitmap => $bmpPlaying);
    $appWin->p5plSTOP->Change(-bitmap => $bmpStop);
    $playing = 1;
    do $awSource;
    setup();
}

sub push_stop
{
    if(!$playing) {return 0;} # don't need to stop twice
    $appWin->p5plPLAY->Change(-bitmap => $bmpPlay);
    $appWin->p5plSTOP->Change(-bitmap => $bmpStopped);
    $playing = 0;
}

sub _play_icons
{
    my $play = Win32::GUI::BitmapInline->new( q(
    Qk3mHQAAAAAAADYAAAAoAAAAMgAAADIAAAABABgAAAAAALAdAAAAAAAAAAAAAAAAAAAAAAAA////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+fn58fHx
    6enp4+Pj3t7e29vb2dnZ2dnZ29vb3t7e4+Pj6enp8fHx+fn5+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/vx8fHl5eXZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnl5eXx8fH7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    ++/v7+Dg4NnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2eDg4O/v7/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v79vb24+Pj2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ4+Pj9vb2+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/vt7e3Z2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnt7e37+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7++np6dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v75+fn2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ5+fn+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/vp6enZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnp6en7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7++3t7dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e3t7fv7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v79vb22dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ9vb2+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/vj4+PZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnj4+P7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7++/v79nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e/v7/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v74ODg2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ4ODg+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/vx8fHZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnx
    8fH7+/v7+/v7+/v///8AAP////v7+/v7+/v7++Xl5dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2WFhYaurq9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2eXl5fv7+/v7+/v7+////wAA////
    +/v7+/v7+fn52dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMz
    MzMzYWFhq6ur2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ+fn5+/v7+/v7////AAD////7+/v7+/vx8fHZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzNhYWGrq6vZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnx8fH7+/v7+/v///8AAP////v7+/v7++np6dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzM2FhYaurq9nZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+////wAA////
    +/v7+/v74+Pj2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzYWFhq6ur2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ4+Pj+/v7+/v7////AAD////7+/v7+/ve3t7Z2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzMzMzMzMzNhYWGrq6vZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dne3t77+/v7+/v///8AAP////v7+/v7+9vb29nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzM2FhYaur
    q9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dvb2/v7+/v7+////wAA////
    +/v7+/v72dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzYWFhq6ur2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ+/v7+/v7////AAD////7+/v7+/vZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzNhYWGrq6vZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dn7+/v7+/v///8AAP////v7+/v7+9vb29nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzM2FhYaur
    q9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dvb2/v7+/v7+////wAA////
    +/v7+/v73t7e2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzYWFhq6ur2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ3t7e+/v7+/v7////AAD////7+/v7+/vj4+PZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzNhYWGrq6vZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnj4+P7+/v7+/v///8AAP////v7+/v7++np6dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzM2FhYaurq9nZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+////wAA////
    +/v7+/v78fHx2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMz
    MzMzMzMzMzMzYWFhq6ur2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ8fHx+/v7+/v7////AAD////7+/v7+/v5+fnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzNhYWGrq6vZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dn5+fn7+/v7+/v///8AAP////v7+/v7+/v7++Xl5dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2WFhYaurq9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2eXl5fv7+/v7+/v7+////wAA////
    +/v7+/v7+/v78fHx2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ8fHx+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/vg4ODZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dng4OD7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7++/v79nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e/v7/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v74+Pj2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ4+Pj+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v29vbZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dn29vb7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7++3t7dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e3t7fv7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v76enp2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ6enp+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/vn5+fZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnn5+f7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7++np6dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v77e3t2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ7e3t
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v29vbj4+PZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnj4+P29vb7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    ++/v7+Dg4NnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2eDg4O/v7/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v78fHx5eXl2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ5eXl8fHx+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v5+fnx8fHp6enj4+Pe3t7b29vZ2dnZ2dnb
    29ve3t7j4+Pp6enx8fH5+fn7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD/////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    //////////////////8AAA==
    ) );
    my $playing = Win32::GUI::BitmapInline->new( q(
    Qk2CHQAAAAAAADYAAAAoAAAAMgAAADIAAAABABgAAAAAAEwdAAAAAAAAAAAAAAAAAAAAAAAA////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////AAD/////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    //////////////////8AAP//////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////wAA////
    ////////////////////////////////////////////////////////////////////9fDyy+e4
    p96HitVfdM9BZcwtXckjXckjZcwtdM9BitVfp96Hy+e49fDy////////////////////////////
    ////////////////////////////////////////////AAD/////////////////////////////
    ///////////////////////////////////L57iR2GpdySNdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySOR2GrL57j/////////////////////////////////////////////
    //////////////////8AAP//////////////////////////////////////////////////////
    /8PkrnvSTF3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JInvSTMPkrv///////////////////////////////////////////////////////wAA////
    ////////////////////////////////////////////4O3WitVfXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiitVf4O3W////
    ////////////////////////////////////////////AAD/////////////////////////////
    //////////////+84aVdySNdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySO84aX/////////////////////////
    //////////////////8AAP///////////////////////////////////////6feh13JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIqfeh////////////////////////////////////////wAA////
    ////////////////////////////////n9h9XckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    Xckin9h9////////////////////////////////////AAD/////////////////////////////
    //+n3oddySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySKn3of/////////////
    //////////////////8AAP///////////////////////////7zhpV3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIrzhpf///////////////////////////wAA////
    ////////////////////4O3WXckjXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckj4O3W////////////////////////AAD///////////////////////+K1V9d
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySKK1V//////
    //////////////////8AAP///////////////////8Pkrl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIsPkrv///////////////////wAA////
    ////////////////e9JMXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckie9JM////////////////////AAD////////////////L57hdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySLL
    57j///////////////8AAP///////////////5HYal3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JItPwwonYX13JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIpHYav///////////////wAA////
    ////////9fDyXckjXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki////
    ////0/DCidhfXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckj9fDy////////////AAD////////////L57hdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySL////////////////T8MKJ2F9dySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySLL57j///////////8AAP///////////6feh13JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIv///////////////////////9PwwonYX13JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIqfeh////////////wAA////
    ////////itVfXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki////
    ////////////////////////////0/DCidhfXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiitVf////////////AAD///////////90z0FdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySL/////////////////////////////
    ///////////T8MKJ2F9dySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJ0z0H///////////8AAP///////////2XMLV3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIv///////////////////////////////////////////////9PwwonY
    X13JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JImXMLf///////////wAA////
    ////////XckjXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki////
    ////////////////////////////////////////////////////0/DCidhfXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckj////////////AAD///////////9dySNdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySL/////////////////////////////
    ///////////////////////////T8MKJ2F9dySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySP///////////8AAP///////////2XMLV3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIv///////////////////////////////////////////////9PwwonY
    X13JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JImXMLf///////////wAA////
    ////////dM9BXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki////
    ////////////////////////////////////0/DCidhfXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckidM9B////////////AAD///////////+K1V9dySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySL/////////////////////////////
    ///T8MKJ2F9dySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySKK1V////////////8AAP///////////6feh13JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIv///////////////////////9PwwonYX13JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIqfeh////////////wAA////
    ////////y+e4XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki////
    ////////////0/DCidhfXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiy+e4////////////AAD////////////18PJdySNdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySL////////T8MKJ2F9dySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySP18PL///////////8AAP///////////////5HYal3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JItPwwonYX13JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIpHYav///////////////wAA////
    ////////////y+e4XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiy+e4////////////////AAD///////////////////970kxdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJ70kz/
    //////////////////8AAP///////////////////8Pkrl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIsPkrv///////////////////wAA////
    ////////////////////itVfXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiitVf////////////////////////AAD////////////////////////g7dZd
    ySNdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySPg7db/////
    //////////////////8AAP///////////////////////////7zhpV3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIrzhpf///////////////////////////wAA////
    ////////////////////////////p96HXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXcki
    XckiXckip96H////////////////////////////////AAD/////////////////////////////
    //////+f2H1dySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySKf2H3/////////////////
    //////////////////8AAP///////////////////////////////////////6feh13JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JIl3JIl3JIl3JIl3JIl3JIqfeh////////////////////////////////////////wAA////
    ////////////////////////////////////////vOGlXckjXckiXckiXckiXckiXckiXckiXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckjvOGl
    ////////////////////////////////////////////AAD/////////////////////////////
    ///////////////////g7daK1V9dySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJdySJd
    ySJdySJdySJdySJdySJdySJdySJdySJdySJdySKK1V/g7db/////////////////////////////
    //////////////////8AAP//////////////////////////////////////////////////////
    /8PkrnvSTF3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3JIl3J
    Il3JInvSTMPkrv///////////////////////////////////////////////////////wAA////
    ////////////////////////////////////////////////////////////y+e4kdhqXckjXcki
    XckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckiXckjkdhqy+e4////////////////////
    ////////////////////////////////////////////AAD/////////////////////////////
    ///////////////////////////////////////////18PLL57in3oeK1V90z0FlzC1dySNdySNl
    zC10z0GK1V+n3ofL57j18PL/////////////////////////////////////////////////////
    //////////////////8AAP//////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////wAA////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////AAD/////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    //////////////////8AAAo=
    ) );
    my $stop = Win32::GUI::BitmapInline->new( q(
    Qk3mHQAAAAAAADYAAAAoAAAAMgAAADIAAAABABgAAAAAALAdAAAAAAAAAAAAAAAAAAAAAAAA////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+fn58fHx
    6enp4+Pj3t7e29vb2dnZ2dnZ29vb3t7e4+Pj6enp8fHx+fn5+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/vx8fHl5eXZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnl5eXx8fH7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    ++/v7+Dg4NnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2eDg4O/v7/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v79vb24+Pj2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ4+Pj9vb2+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/vt7e3Z2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnt7e37+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7++np6dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v75+fn2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ5+fn+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/vp6enZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnp6en7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7++3t7dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e3t7fv7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v79vb22dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ9vb2+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/vj4+PZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnj4+P7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7++/v79nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e/v7/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v74ODg2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ4ODg+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/vx8fHZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnx
    8fH7+/v7+/v7+/v///8AAP////v7+/v7+/v7++Xl5dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    M9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2eXl5fv7+/v7+/v7+////wAA////
    +/v7+/v7+fn52dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ+fn5+/v7+/v7////AAD////7+/v7+/vx8fHZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzPZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnx8fH7+/v7+/v///8AAP////v7+/v7++np6dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    M9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+////wAA////
    +/v7+/v74+Pj2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ4+Pj+/v7+/v7////AAD////7+/v7+/ve3t7Z2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzPZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dne3t77+/v7+/v///8AAP////v7+/v7+9vb29nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    M9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dvb2/v7+/v7+////wAA////
    +/v7+/v72dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ+/v7+/v7////AAD////7+/v7+/vZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzPZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dn7+/v7+/v///8AAP////v7+/v7+9vb29nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    M9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dvb2/v7+/v7+////wAA////
    +/v7+/v73t7e2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ3t7e+/v7+/v7////AAD////7+/v7+/vj4+PZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzPZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnj4+P7+/v7+/v///8AAP////v7+/v7++np6dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    M9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+////wAA////
    +/v7+/v78fHx2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ8fHx+/v7+/v7////AAD////7+/v7+/v5+fnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    MzMzMzMzMzMzMzMzMzMzMzMzMzPZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dn5+fn7+/v7+/v///8AAP////v7+/v7+/v7++Xl5dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2TMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
    M9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2eXl5fv7+/v7+/v7+////wAA////
    +/v7+/v7+/v78fHx2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ8fHx+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/vg4ODZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dng4OD7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7++/v79nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e/v7/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v74+Pj2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ4+Pj+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v29vbZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dn29vb7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7++3t7dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2e3t7fv7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v76enp2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ6enp+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/vn5+fZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnn5+f7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7++np6dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2enp6fv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v77e3t2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ7e3t
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v29vbj4+PZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnj4+P29vb7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    ++/v7+Dg4NnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ
    2dnZ2eDg4O/v7/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v78fHx5eXl2dnZ2dnZ
    2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ5eXl8fHx+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v5+fnx8fHp6enj4+Pe3t7b29vZ2dnZ2dnb
    29ve3t7j4+Pp6enx8fH5+fn7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD/////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    //////////////////8AAA==
    ) );
    my $stopped = Win32::GUI::BitmapInline->new( q(
    Qk3mHQAAAAAAADYAAAAoAAAAMgAAADIAAAABABgAAAAAALAdAAAAAAAAAAAAAAAAAAAAAAAA////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v79fL6y7j3
    p4f0il/xdEHvZS3uXSPtXSPtZS3udEHvil/xp4f0y7j39fL6+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/vLuPeRavJdI+1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dI+2RavLLuPf7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +8Ou9ntM8F0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7XtM8MOu9vv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v74Nb5il/xXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtil/x4Nb5+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/u8pfVdI+1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dI+28pfX7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+6eH9F0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7aeH9Pv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7n33yXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtn33y+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/unh/RdIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu2nh/T7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+7yl9V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7byl9fv7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v74Nb5XSPtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSPt4Nb5+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/uKX/Fd
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu2KX/H7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+8Ou9l0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7cOu9vv7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7e0zwXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLte0zw+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/vLuPddIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu3L
    uPf7+/v7+/v7+/v///8AAP////v7+/v7+/v7+5Fq8l0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7f//////////////////////////////////////////////////////////////
    /10i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7ZFq8vv7+/v7+/v7+////wAA////
    +/v7+/v79fL6XSPtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt////////////
    ////////////////////////////////////////////////////XSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSPt9fL6+/v7+/v7////AAD////7+/v7+/vLuPddIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu3/////////////////////////////////////
    //////////////////////////9dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu3LuPf7+/v7+/v///8AAP////v7+/v7+6eH9F0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7f//////////////////////////////////////////////////////////////
    /10i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7aeH9Pv7+/v7+////wAA////
    +/v7+/v7il/xXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt////////////
    ////////////////////////////////////////////////////XSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtil/x+/v7+/v7////AAD////7+/v7+/t0Qe9dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu3/////////////////////////////////////
    //////////////////////////9dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu10Qe/7+/v7+/v///8AAP////v7+/v7+2Ut7l0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7f//////////////////////////////////////////////////////////////
    /10i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7WUt7vv7+/v7+////wAA////
    +/v7+/v7XSPtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt////////////
    ////////////////////////////////////////////////////XSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSPt+/v7+/v7////AAD////7+/v7+/tdI+1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu3/////////////////////////////////////
    //////////////////////////9dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dI+37+/v7+/v///8AAP////v7+/v7+2Ut7l0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7f//////////////////////////////////////////////////////////////
    /10i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7WUt7vv7+/v7+////wAA////
    +/v7+/v7dEHvXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt////////////
    ////////////////////////////////////////////////////XSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtdEHv+/v7+/v7////AAD////7+/v7+/uKX/FdIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu3/////////////////////////////////////
    //////////////////////////9dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu2KX/H7+/v7+/v///8AAP////v7+/v7+6eH9F0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7f//////////////////////////////////////////////////////////////
    /10i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7aeH9Pv7+/v7+////wAA////
    +/v7+/v7y7j3XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt////////////
    ////////////////////////////////////////////////////XSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLty7j3+/v7+/v7////AAD////7+/v7+/v18vpdI+1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu3/////////////////////////////////////
    //////////////////////////9dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    I+318vr7+/v7+/v///8AAP////v7+/v7+/v7+5Fq8l0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7f//////////////////////////////////////////////////////////////
    /10i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7ZFq8vv7+/v7+/v7+////wAA////
    +/v7+/v7+/v7y7j3XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLty7j3+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/t7TPBdIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu17TPD7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+8Ou9l0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7cOu9vv7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7il/xXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtil/x+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/vg1vld
    I+1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dI+3g1vn7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+7yl9V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7byl9fv7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7p4f0XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtp4f0+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/ufffJdIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu2fffL7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+6eH9F0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7V0i7V0i7V0i7V0i7V0i7aeH9Pv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7vKX1XSPtXSLtXSLtXSLtXSLtXSLtXSLtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSPtvKX1
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/vg1vmKX/FdIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1d
    Iu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu1dIu2KX/Hg1vn7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +8Ou9ntM8F0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i7V0i
    7V0i7XtM8MOu9vv7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7y7j3kWryXSPtXSLt
    XSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSLtXSPtkWryy7j3+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD////7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v18vrLuPenh/SKX/F0Qe9lLe5dI+1dI+1l
    Le50Qe+KX/Gnh/TLuPf18vr7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v///8AAP////v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+////wAA////
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7
    +/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7////AAD/////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    //////////////////8AAA==
    ) );
    return ($play, $playing, $stop, $stopped);
}

sub updateBitmap
{
    my ($base64) = @_;
    $appWin->p5plCANVAS->Change(-bitmap => Win32::GUI::BitmapInline->new($base64));
}

sub requestCanvasSize
{
    my ($w,$h) = @_;

    $appWin->p5plCANVAS->Resize($w,$h);
    my $wh = $appWin->Height();
    my $ww = $appWin->Width() ;

    my $sh = $appWin->ScaleHeight();
    my $sw = $appWin->ScaleWidth();

    my $GUI_h = $wh - $sh;
    my $GUI_w = $ww - $sw;

    my $need_h = $GUI_h + 10 + 50 + 10 + $h + 10;   # GUI_h(TITLE+borders) + gap before, button, gap between, $h, gap after
    my $need_w = $GUI_w + 10 + $w + 10;             # GUI_w(borders) + gap before, $w, gap after

    my $new_wh = ($need_h > $wh) ? $need_h : $wh;
    my $new_ww = ($need_w > $ww) ? $need_w : $ww;
    $appWin->Resize($new_ww,$new_wh);
    #print STDERR "resize: canvas($w x $h), win($ww x $wh): scaled($sw x $sh) vs needed($need_w x $need_h) => new($new_ww x $new_wh)\n";
}

1;
