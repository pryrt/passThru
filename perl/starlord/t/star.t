use 5.014; # strict, //, s//r
use warnings;
use Test2::Bundle::More;
use Test2::Tools::Exception qw(dies lives);
use App::StarLord::Star;

$| = 1;

my $star_random = CreateStar();
isa_ok $star_random, 'App::StarLord::Star';
can_ok $star_random, qw/position name/ or BAIL_OUT("doesnt have needed methods to continue testing");
isa_ok $star_random->position, 'Math::Vector::Real';
my $pos = $star_random->position;
cmp_ok $pos->[0], '==', int $pos->[0], 'star created at random must have integer x';
cmp_ok $pos->[1], '==', int $pos->[1], 'star created at random must have integer y';
cmp_ok $pos->[2], '==', int $pos->[2], 'star created at random must have integer z';
note "\$star_random->position = ", $star_random->position;
ok !defined $star_random->name(), 'star created at random has no name';
$star_random->name('AssignedName');
is $star_random->name(), 'AssignedName', 'star created at random has been assigned new name';

my $star_xyz = CreateStar(1,2,3, name => 'Xyzzy');
isa_ok $star_xyz, 'App::StarLord::Star';
is_deeply [@{$star_xyz->position}], [1,2,3], "star created from coordinates(1,2,3)";
is $star_xyz->name(), 'Xyzzy', "coordinate-star name";

my $star_aref = CreateStar([5,6,7], name => 'aref');
isa_ok $star_aref, 'App::StarLord::Star';
is_deeply [@{$star_aref->position}], [5,6,7], "star created from arrayref [5,6,7]";
is $star_aref->name(), 'aref', "arrayref-star name";

use Math::Vector::Real;
my $star_vec = CreateStar(V(8,9,0), name => 'Victor');
isa_ok $star_vec, 'App::StarLord::Star';
is_deeply [@{$star_vec->position}], [8,9,0], "star created from vector {8,9,0}";
is $star_vec->name(), 'Victor', "vector-star name";

like(
    dies { CreateStar({})},
    qr/\Qmust be given\E/,
    "->new() dies when given inappropriate reference"
);

like(
    dies { CreateStar(V(1,2))},
    qr/\Qinitial position must be three-dimensional\E/,
    "->new() dies when given too few dimensions"
);

like(
    dies { CreateStar(V(1,2,3,4))},
    qr/\Qinitial position must be three-dimensional\E/,
    "->new() dies when given too many dimensions"
);

like(
    dies { CreateStar(V(0,0,0), fakeAttribute => 0)},
    qr/\Qunknown attribute\E/,
    "->new() dies when given an unknown attribute"
);

done_testing;
