#!perl
# try Algorithm::QuadTree

use 5.014; # strict, //, s//r
use warnings;

# after doing all the notes on how CodingTrain implemented it earlier,
# I decided to see if there already was a good implementation for Perl:
# Looking at Algorithm::QuadTree, I think it's very similar to CodingTrain:
# - it allows using rectangles or circles for the query range (getEnclosedObjects)
# - it allows using rectangles or circles for the objects added to the tree (whereas CodingTrain just did points with an associated UserData)
#       - the SYNOPSIS shows that a zero-width rectangle can be used if you just want a single point for the object
# - A::QT apparently puts the object at all levels of the tree that it fits in, rather than just storing 1 or nCAPACITY objects plus a tree...
# - A::QT defines the depth of the tree, so I am guessing that it will have a bunch of empty nodes.  But I think I'll want to add a few known points
#       and dump the internal structure, to be sure

use Algorithm::QuadTree;
my $qtree = Algorithm::QuadTree::->new(
    -xmin => 0,
    -xmax => 8,
    -ymin => 0,
    -ymax => 8,
    -depth => 4,
);

$qtree->add("4x4y", 4, 4, 0);  # circle with radius zero
$qtree->add("2x2y", 2, 2, 0);  # circle with radius zero
$qtree->add("6x2y", 6, 2, 0);  # circle with radius zero
$qtree->add("2x6y", 2, 6, 0);  # circle with radius zero
$qtree->add("6x6y", 6, 6, 0);  # circle with radius zero

use Data::Dump; dd {%$qtree};

dd $qtree->getEnclosedObjects(1,1,3,3);

__END__
-depth => 1 => do {
  my $a = {
    BACKREF => {
                 "2x2y" => [
                             {
                               AREA => [0, 0, 8, 8],
                               HAS_OBJECTS => 1,
                               OBJECTS => ["4x4y", "2x2y", "6x2y", "2x6y", "6x6y"],
                               PARENT => undef,
                             },
                           ],
                 "2x6y" => ['fix'],
                 "4x4y" => ['fix'],
                 "6x2y" => ['fix'],
                 "6x6y" => ['fix'],
               },
    DEPTH   => 1,
    ORIGIN  => [0, 0],
    ROOT    => 'fix',
    SCALE   => 1,
    XMAX    => 8,
    XMIN    => 0,
    YMAX    => 8,
    YMIN    => 0,
  };
  $a->{BACKREF}{"2x6y"}[0] = $a->{BACKREF}{"2x2y"}[0];
  $a->{BACKREF}{"4x4y"}[0] = $a->{BACKREF}{"2x2y"}[0];
  $a->{BACKREF}{"6x2y"}[0] = $a->{BACKREF}{"2x2y"}[0];
  $a->{BACKREF}{"6x6y"}[0] = $a->{BACKREF}{"2x2y"}[0];
  $a->{ROOT} = $a->{BACKREF}{"2x2y"}[0];
  $a;
}

-depth => 2 => do {
  my $a = {
    BACKREF => {
                 "2x2y" => [
                             {
                               AREA => [0, 0, 4, 4],
                               HAS_OBJECTS => 1,
                               OBJECTS => ["4x4y", "2x2y"],
                               PARENT => {
                                 AREA => [0, 0, 8, 8],
                                 CHILDREN => [
                                   {
                                     AREA => [0, 4, 4, 8],
                                     HAS_OBJECTS => 1,
                                     OBJECTS => ["4x4y", "2x6y"],
                                     PARENT => 'fix',
                                   },
                                   {
                                     AREA => [4, 4, 8, 8],
                                     HAS_OBJECTS => 1,
                                     OBJECTS => ["4x4y", "6x6y"],
                                     PARENT => 'fix',
                                   },
                                   'fix',
                                   {
                                     AREA => [4, 0, 8, 4],
                                     HAS_OBJECTS => 1,
                                     OBJECTS => ["4x4y", "6x2y"],
                                     PARENT => 'fix',
                                   },
                                 ],
                                 HAS_OBJECTS => 1,
                                 PARENT => undef,
                               },
                             },
                           ],
                 "2x6y" => ['fix'],
                 "4x4y" => ['fix', 'fix', 'fix', 'fix'],
                 "6x2y" => ['fix'],
                 "6x6y" => ['fix'],
               },
    DEPTH   => 2,
    ORIGIN  => [0, 0],
    ROOT    => 'fix',
    SCALE   => 1,
    XMAX    => 8,
    XMIN    => 0,
    YMAX    => 8,
    YMIN    => 0,
  };
  $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[0]{PARENT} = $a->{BACKREF}{"2x2y"}[0]{PARENT};
  $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[1]{PARENT} = $a->{BACKREF}{"2x2y"}[0]{PARENT};
  $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[2] = $a->{BACKREF}{"2x2y"}[0];
  $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[3]{PARENT} = $a->{BACKREF}{"2x2y"}[0]{PARENT};
  $a->{BACKREF}{"2x6y"}[0] = $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[0];
  $a->{BACKREF}{"4x4y"}[0] = $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[0];
  $a->{BACKREF}{"4x4y"}[1] = $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[1];
  $a->{BACKREF}{"4x4y"}[2] = $a->{BACKREF}{"2x2y"}[0];
  $a->{BACKREF}{"4x4y"}[3] = $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[3];
  $a->{BACKREF}{"6x2y"}[0] = $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[3];
  $a->{BACKREF}{"6x6y"}[0] = $a->{BACKREF}{"2x2y"}[0]{PARENT}{CHILDREN}[1];
  $a->{ROOT} = $a->{BACKREF}{"2x2y"}[0]{PARENT};
  $a;
}
