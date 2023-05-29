package tryLiveSubReloadLib;
use 5.012; # //, strict, say
use warnings;

=begin ideas

There are two challenges that I want to get working:

1. If script uses this from the get-go, do some initialization...
   but if this then runs `do` on the script, it won't re-run/re-initialize
   - since %INC will have been updated to have this module, this module will _not_ reload, so that means it's safe
   - however, if the script does anythig other than define subroutines, it will need to be protected by an unless(caller(0)) condition
     (and `if(caller(0)){exit;}` will actually exit the top-level script, not just the `do`.)
2. if the calling-script defines a sub, will the module see the update to that sub
   _after_ the `do` is run?
   - need the `no warnings 'redefine` to go in the script, _not_ in the library; annoying

2023-05-29 11:15 = That almost kindof worked when I uncomment the #caller(3) or run_control_loop($_[1]);,
    but I think I'm trying to make it too complicated.  I think I should really have a launch_p5pl script, which runs the GUI,
    then use the GUI to load my actual script, then have the library run the loop which calls "do" on the p5pl.
    Organization:
        launch_p5pl.pl = `use Win32::GUI::P5PL; Win32::GUI::P5PL->run();`
        lib\Win32::GUI::P5PL        => this is the "app" that sets up the window and commands
        lib\Win32::GUI::P5PL::API   => this has the clones of all the p5.js
        sketch.p5pl = `use Win32::GUI::P5PL::API; sub setup {...}; sub loopy {...}`

    Or, simpler, just do the `use Win32::GUI::P5PL; if(!caller) { Win32::GUI::P5PL->launch_gui() }` as part of the
        boilerplate at the top of sketch_p5.pl, and be done with it.

=cut

my $c = 0;
while(my @c = caller($c)) {
    printf STDERR "tLSRL:  ONLOAD caller(#%d) => (%s)\n", $c, join ",", map { $_//"<undef>"} @c;
    ++$c;
}

sub recurse
{
    my ($scriptPath) = @_;
    no warnings qw(redefine);
    printf STDERR "tLSRL:  before first do('%s')\n", $scriptPath;
    eval { do $scriptPath; 1; } or do { print "tLSRL:  eval says \$@ = $@\n"; };
    printf STDERR "tLSRL:  after  first do('%s')\n", $scriptPath;
    eval { do $scriptPath; 1; } or do { print "tLSRL:  eval says \$@ = $@\n"; };
    printf STDERR "tLSRL:  after  second do('%s')\n", $scriptPath;
}

sub import
{
    printf STDERR "tLSRL:  import(@_)\n";

    my $c = 0;
    while(my @c = caller($c)) {
        printf STDERR "tLSRL:  IMPORT caller(#%d) => (%s)\n", $c, join ",", map { $_//"<undef>"} @c;
        ++$c;
    }

    #caller(3) or run_control_loop($_[1]);
}

use Data::Dumper;

sub run_control_loop
{
$Data::Dumper::Deparse = 1;
    for my $loop (0..15) {
        printf STDERR "tLSRL:  %d start control loop (@_)\n", $loop;
        printf STDERR "tLSRL:  %d sub setup = %s\n", $loop, \&setup // '<undef>';
        print STDERR "tLSRL:  ", Data::Dumper->Dump([\&setup,\&loopy,$loop],[qw/setup loopy loop/]);
        if($loop) {
            printf STDERR "tLSRL:  before do('%s') # %d\n", $_[0], $loop;
            do $_[0];
            printf STDERR "tLSRL:  after  do('%s') # %d\n", $_[0], $loop;
            setup();
            loopy();
            printf STDERR "tLSRL:  after  run setup and loopy : %s # %d\n", $_[0], $loop;
            sleep(1);
        }
    }
}

1;
