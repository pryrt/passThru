use 5.014; # strict, //, s//r
use warnings;
use Test2::Bundle::More;
use Test2::Tools::Exception qw(dies lives);
use App::StarLord::Star;

$| = 1;

my $star_random = CreateStar();
isa_ok $star_random, 'App::StarLord::Star';
can_ok $star_random, qw/position/ or BAIL_OUT("doesnt have needed methods to continue testing");
note "\$star_random->position = ", $star_random->position;
isa_ok $star_random->position, 'Math::Vector::Real';

my $star_xyz = CreateStar(1,2,3);
isa_ok $star_xyz, 'App::StarLord::Star';
is_deeply [@{$star_xyz->position}], [1,2,3], "star created from coordinates(1,2,3)";

my $star_aref = CreateStar([5,6,7]);
isa_ok $star_aref, 'App::StarLord::Star';
is_deeply [@{$star_aref->position}], [5,6,7], "star created from arrayref [5,6,7]";

like(
    dies { App::StarLord::Star->new({})},
    qr/\Qmust be given\E/,
    "->new() dies when given inappropriate reference"
);

use Math::Vector::Real;
my $star_vec = CreateStar(V(8,9,0));
isa_ok $star_vec, 'App::StarLord::Star';
is_deeply [@{$star_vec->position}], [8,9,0], "star created from vector {8,9,0}";

done_testing;
