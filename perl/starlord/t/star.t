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

# homing
ok !$star_vec->discovered, 'Victor not yet discovered';
ok !defined $star_vec->controlled_by, 'Victor not yet controlled by anyone';
ok !defined $star_vec->is_ic, 'Victor does not define industrial center yet';
ok !defined $star_vec->has_planets, 'Victor does not define number of planets yet';
$star_vec->make_home('user');
ok $star_vec->discovered, 'Victor now discovered';
is $star_vec->controlled_by, 'user', 'Victor controlled by user';
ok $star_vec->is_ic, 'Victor has an industrial center, because it is the user\'s home system';
is $star_vec->has_planets, 5, 'Victor has 5 planets, because it is the user\'s home system';
is $star_vec->capacity, 10, 'Victor has capacity of 10 minerals, because it is the user\'s home system';
is $star_vec->stockpile, 0, 'Victor has 0 stored minerals';

# discovering
$star_xyz->discover('u2');
ok $star_xyz->discovered, 'Xyzzy now discovered';
is $star_xyz->controlled_by, 'u2', 'Xyzzy controlled by user';
like $star_xyz->is_ic, qr/^[01]$/, 'Xyzzy has random industrial center initialization: ' . $star_xyz->is_ic//'<undef>';
like $star_xyz->has_planets, qr/^[1-5]$/, 'Xyzzy randomly has 1-5 planets: ' . $star_xyz->has_planets//'<undef>';
is $star_xyz->capacity, 2*$star_xyz->has_planets, 'Xyzzy has a mineral capacity of twice its planets: ' . $star_xyz->capacity//'<undef>';
is $star_xyz->stockpile, 0, 'Xyzzy has 0 stored minerals';

# discovered without owner
$star_aref->discover();
ok $star_aref->discovered, 'aref now discovered';
ok !defined $star_aref->controlled_by, 'aref not controlled';

# add minerals
$star_vec->add_minerals(3);
is $star_vec->stockpile, 3, 'Victor has 3 stored minerals after adding 3';

# remove minerals
$star_vec->remove_minerals(1);
is $star_vec->stockpile, 2, 'Victor has 2 stored minerals after removing 1';

# error coverage

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

like (
    dies { $star_vec->make_home('someone new') },
    qr/\QAlready discovered\E/,
    "->make_home() reports error if already discovered"
);

like (
    dies { $star_xyz->discover('someone new') },
    qr/\QAlready discovered\E/,
    "->discover() reports error if already discovered"
);

like (
    dies { $star_vec->add_minerals(20) },
    qr/\Qwhich is more than capacity of 10 minerals in the system\E/,
    "->add_minerals(20) exceeds capacity of 10 minerals"
);

like (
    dies { $star_vec->add_minerals(-1) },
    qr/\QCannot add negative minerals\E/,
    "->add_minerals(-1) reports error for being negative"
);

like (
    dies { $star_vec->remove_minerals(20) },
    qr/\QThere are only 2 minerals to remove in the system\E/,
    "->remove_minerals(20) exceeds stockpile of 2 minerals"
);

like (
    dies { $star_vec->remove_minerals(-1) },
    qr/\QCannot remove negative minerals\E/,
    "->remove_minerals(-1) reports error for being negative"
);

done_testing;
