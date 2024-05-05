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
is $map_default->{_stars}[0]->name(), 'A', 'DefaultStarMap: first auto-name ok';
is $map_default->{_stars}[1]->name(), 'B', 'DefaultStarMap: second auto-name ok';
is $map_default->{_stars}[-1]->name(), 'Ylem', 'DefaultStarMap: last auto-name ok';

done_testing;
