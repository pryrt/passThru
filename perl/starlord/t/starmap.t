use 5.014; # strict, //, s//r
use warnings;
use Test2::Bundle::More;
use Test2::Tools::Exception qw(dies lives);
use App::StarLord::StarMap;

$| = 1;

my $map_default = CreateDefaultStarMap();
isa_ok $map_default, 'App::StarLord::StarMap';
can_ok $map_default, qw/count append_star/ or BAIL_OUT("doesnt have needed methods to continue testing");
cmp_ok $map_default->count(), '==', 25, 'DefaultStarMap: creates 25 stars';
is substr($map_default->{_stars}[0]->name(), 0, 1), 'A', 'DefaultStarMap: first auto-name ok';
is substr($map_default->{_stars}[1]->name(), 0, 1), 'B', 'DefaultStarMap: second auto-name ok';
is $map_default->{_stars}[-1]->name(), 'Ylem', 'DefaultStarMap: last auto-name ok';
# TODO: do I want to test coordinates or actual names, or just leave it as-is?

my $star = $map_default->get_star_named('Ylem');
is $star->name, 'Ylem', 'DefaultStarMap: get_star_named(Ylem)';
is_deeply [@{$star->position}], [0,0,0], 'DefaultStarMap: Ylem at origin';

like(
    dies { $map_default->get_star_named('Ziggy') },
    qr/\QNo star named 'Ziggy'\E/,
    "->get_star_name() dies when given non-existent star"
);


done_testing;
