#!perl

use 5.014; # strict, //, s//r
use warnings;
use Data::Dump;

# equivalent of use lib::relative -- ie, better than FindBin or use './lib'
{
    use Cwd ();
    use File::Basename ();
    use File::Spec ();
    use lib File::Spec->catdir(File::Basename::dirname(Cwd::abs_path __FILE__), 'lib');
}

use myQuadTree;

my $outer = myQuadTree::Rectangle(0,0,1,1); # step4
my $qtree = myQuadTree($outer, 4);          # step4
$qtree->addItemAtPoint(\"itm0", 0.5, 0.5);  # step5
$qtree->addItemAtPoint(\"itm$_", int(-10+rand 20)/10, int(-10 + rand 20)/10) for 1..4;  # step9 : trigger subdivide
dd $qtree;

my $range = myQuadTree::Rectangle(0.4, 0.4, 1, 1);
my $found = $qtree->query($range);
dd $found;

__END__

206: $found array is coming back empty, so need to debug

