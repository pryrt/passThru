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

__END__

do {
  my $a = bless({
    boundary  => bless({ cx => 0, cy => 0, rx => 1, ry => 1, type => "rectangle" }, "myQuadTree::Region"),
    capacity  => 4,
    divided   => 1,
    items     => [
                   bless({ cx => 0.5, cy => 0.5, myItem => \"dummyItem0", rx => 0, ry => 0, type => "point" }, "myQuadTree::Region"),
                   bless({ cx => -0.08, cy => -0.71, myItem => \"dummyItem1", rx => 0, ry => 0, type => "point", }, "myQuadTree::Region"),
                   bless({ cx => -0.99, cy => -0.02, myItem => \"dummyItem2", rx => 0, ry => 0, type => "point", }, "myQuadTree::Region"),
                   bless({ cx => 0.53, cy => -0.24, myItem => \"dummyItem3", rx => 0, ry => 0, type => "point" }, "myQuadTree::Region"),
                 ],
    northeast => bless({
                   boundary => bless({ cx => 0.5, cy => 0.5, rx => 0.5, ry => 0.5, type => "rectangle" }, "myQuadTree::Region"),
                   capacity => 4,
                   divided  => undef,
                   items    => [
                                 bless({ cx => 0.26, cy => 0.57, myItem => \"dummyItem4", rx => 0, ry => 0, type => "point" }, "myQuadTree::Region"),
                               ],
                 }, "myQuadTree"),
    northwest => bless({
                   boundary => bless({ cx => -0.5, cy => 0.5, rx => 0.5, ry => 0.5, type => "rectangle" }, "myQuadTree::Region"),
                   capacity => 4,
                   divided  => undef,
                   items    => [
                                 bless({ cx => 0.26, cy => 0.57, myItem => 'fix', rx => 0, ry => 0, type => "point" }, "myQuadTree::Region"),
                               ],
                 }, "myQuadTree"),
    southeast => bless({
                   boundary => bless({ cx => 0.5, cy => -0.5, rx => 0.5, ry => 0.5, type => "rectangle" }, "myQuadTree::Region"),
                   capacity => 4,
                   divided  => undef,
                   items    => [
                                 bless({ cx => 0.26, cy => 0.57, myItem => 'fix', rx => 0, ry => 0, type => "point" }, "myQuadTree::Region"),
                               ],
                 }, "myQuadTree"),
    southwest => bless({
                   boundary => bless({ cx => -0.5, cy => -0.5, rx => 0.5, ry => 0.5, type => "rectangle" }, "myQuadTree::Region"),
                   capacity => 4,
                   divided  => undef,
                   items    => [
                                 bless({ cx => 0.26, cy => 0.57, myItem => 'fix', rx => 0, ry => 0, type => "point" }, "myQuadTree::Region"),
                               ],
                 }, "myQuadTree"),
  }, "myQuadTree");
  $a->{northwest}{items}[0]{myItem} = \${$a->{northeast}{items}[0]{myItem}};
  $a->{southeast}{items}[0]{myItem} = \${$a->{northeast}{items}[0]{myItem}};
  $a->{southwest}{items}[0]{myItem} = \${$a->{northeast}{items}[0]{myItem}};
  $a;
}
