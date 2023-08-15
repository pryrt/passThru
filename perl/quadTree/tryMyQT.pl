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
$qtree->addItemAtPoint(\"dummyItem1", sqrt(.5), sqrt(.5));  # step5
dd $qtree;
