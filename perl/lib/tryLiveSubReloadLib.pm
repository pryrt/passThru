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

=cut

my $c = 0;
while(my @c = caller($c)) {
    printf STDERR "tLSRL:  #%d => (%s)\n", $c, join ",", map { $_//"<undef>"} @c;
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
    run_control_loop(@_);
}

sub run_control_loop
{
    printf STDERR "tLSRL:  0 start control loop (@_)\n";
    printf STDERR "tLSRL:  0 sub setup = %s\n", \&setup // '<undef>';
    sleep(1);
    do
    printf STDERR "tLSRL:  1 control loop 1\n";
    printf STDERR "tLSRL:  1 sub setup = %s\n", \&setup // '<undef>';

    sleep(1);
    printf STDERR "tLSRL:  control loop 2\n";

}

1;
