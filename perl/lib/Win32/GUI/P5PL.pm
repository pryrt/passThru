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

=pod

=encoding utf8

=head1 NAME

Win32::GUI::P5PL - GUI application inspired by p5*js

=head1 SYNOPSIS

    # sketch.p5.pl
    #!perl
    use 5.014; # //, strict, say, s//r
    use warnings;   no warnings 'redefine';
    use lib './lib';
    use Win32::GUI::P5PL;
    if(!caller){Win32::GUI::P5PL::App->launch();}

    sub setup() {
      createCanvas(800, 400);
    }

    sub draw() {
      background(220);
    }

=head1 DESCRIPTION

Provides an environment similar to the L<p5*js editor|https://editor.p5js.org/> ,
but currently focuses on just the CANVAS-related aspects: the setup and draw loop
for the image, and the ability to react to live changes in the script.

It does not implement the rest of the DOM features of p5*js, nor the actual editor
panel (though the latter may eventually be implemented).

The SYNOPSIS gives the basic structure that your script will use: you define
a C<setup()> and C<draw()> function, and when you hit PLAY, the app will run
C<setup()> and then loop on C<draw()> (as appropriate).

=head2 Live Changes

It seems, while watching Coding Train videos, that if you edit the script while
it's running, the next draw loop will immediately incorporate the changes saved
in the file.  I wanted to replicate that, so essentially every loop, I am re-running
the script, in case <setup()> and C<draw()> were re-defined since the last save.
Because of that, those functions are redefined every loop, so we need to turn off
those warnings in the script.

As a result of this philosophy, your script is rerun frequently, so it should not
"do" anything (have any code not in functions) other than the initial C<use>
statements, and the C<if(!caller){Win32::GUI::P5PL::App->launch();}> boilerplate.

Improvements I want to make in order for the Live Changes to be more seamless:

=over

=item * ☐ Only re-run the script when the file has changed since the last loop.

I<idea: See L<-X>'s C<-M> modification time check.>

=item * ☐ Figure out how to temporarily inject the C<no warnings 'redefine';>
so that it doesn't have to be in the script.

I<idea: look at how L<Modern::Perl> injects warnings/strict/features into the calling script>.

=item * ☐ Automatically do the equivalent of the C<if(!caller)...> call,
so that it doesn't have to be in the script.

My initial experiments tried to implement that: while the C<use> statement will
only run the C<P5PL.pm> itself once when the sketch is first run, the
C<P5PL::import()> appears to run every time.  That was originally my downfall,
but might also end up being what I can use to track whether it's the first load
or not.  (Do a import-counting state variable, and only run the GUI on the first time)

=back


=head1 REFERENCE

=cut

=head2 Rendering

=over

=item createCavas

=item resizeCanvas

    createCanvas($w,$h);

Either function initializes the canvas width and height, and starts a new underlying image object.

(I couldn't see an effective difference in terms of features I'm implementing, so they are implemented
with the same underlying code in my library.  I do not claim this is true of the original p5*js.)

=cut

my $img;
sub _pushImg { Win32::GUI::P5PL::App::updateBitmap(MIME::Base64::encode($img->bmp())) }
sub createCanvas
{
    my ($w, $h) = @_;
    Win32::GUI::P5PL::App::requestCanvasSize($w,$h);

    $img = GD::Image->new($w,$h,1);
    _pushImg();
}

*resizeCanvas = \&createCanvas;

=item background

C<background()> will set the background color and fill the whole image with that color.
When used in C<setup()>, it initializes it once.  When used in C<draw()>, it's basically
a clear-screen command.

=cut

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

=back

=head2 Structure

=over

=item noLoop()

=item loop()

=item isLooping()

TBD: Control the draw-loop mechanism.  By default, C<isLooping()> is true,
and C<draw()> will be called repeatedly.  Running C<noLoop()> will stop
the C<draw()> loop, and C<loop()> will re-start it.

B<TODO>: ☐ need to figure out how to propagate this to the actual ::App-based loop mechanism.

=cut

my $_is_looping;
sub isLooping { $_is_looping }
sub noLoop { $_is_looping = 0 }
sub loop { $_is_looping = 1 }

=item push()

=item pop()

TBD: There is apparently a stack of transform/color/stroke settings which can
be pushed and popped, to be able to easily handle sets of drawing conditions.

=back

=head1 AUTHOR

Copyright (C) Peter C. Jones, 2023

=cut

1;
