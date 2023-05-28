#!perl

use 5.012; # //, strict, say
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
my $source; BEGIN { $source = $FindBin::Script; unless($source =~ m{/}) { $source = './' . $FindBin::Script; }; };
BEGIN { printf STDERR "script: before use tryLiveSubReloadLib: INC has(%s)\n", join '; ', map {"$_ => $INC{$_}"} grep {/tryLiveSubReload/} sort keys (%INC); }
use tryLiveSubReloadLib($source);
BEGIN { printf STDERR "script: after  use tryLiveSubReloadLib: INC has(%s)\n", join '; ', map {"$_ => $INC{$_}"} grep {/tryLiveSubReload/} sort keys (%INC); }

=begin debug#1

print STDERR "script: before caller(n) check\n";
my $c = 0;
while(my @c = caller($c)) {
    printf STDERR "script: #%d => (%s)\n", $c, join ",", map { $_//"<undef>"} @c;
    ++$c;
}
print STDERR "script: after caller(n) check\n";

if(caller(0)) {
    print STDERR "script: prevent infinte recursion when this script is read again\n";
    #exit; # cannot use exit, because that exits the top-level script
} else {
    print STDERR "script: before tryLiveSubReloadLib::recurse()\n";
    my $source = $FindBin::Script;
    unless($source =~ m{/}) { $source = './' . $FindBin::Script; }
    tryLiveSubReloadLib::recurse($source);
    print STDERR "script: after  tryLiveSubReloadLib::recurse()\n";
}

=cut

{
    no warnings 'redefine';
    sub setup { print STDERR "this is the setup function\n" }
    sub loopy { print STDERR "this is the loopy function\n" }
}

1;
