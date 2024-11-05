#!perl
# this is a copy of the original example, but it's going to use the library, instead
#
# https://github.com/pryrt/nppStuff/blob/main/CommunityForum/API%20Access.md
# https://docs.nodebb.org/api/write
# https://docs.nodebb.org/api/read

use 5.014; # strict, //, s//r
use warnings;
use HTTP::Tiny;
use Data::Dump;
use JSON;
use open ':std', ':encoding(UTF-8)';
use lib './lib';
use Win32::Mechanize::NppCommunity;
$| = 1;

my $comm = Win32::Mechanize::NppCommunity::->new('~$token');
my $client = $comm->client();

$comm->forAllUsersDo(sub {
    my ($user) = @_;
    state $counter = 0;
    return 0 if $user->{postcount};
    my $activity = abs($user->{lastonline} - $user->{joindate});
    return 0 if $activity > 86400;
    printf "- %-8d %-30.30s: %-32.32s %-15.15s => %d\n", $user->{uid}, $user->{username}, $user->{lastonlineISO}, $activity, $user->{postcount};
    return 1 if ++$counter < 7;
    return undef;
});

$comm->forAllTopicsDo(sub {
    my ($topic) = @_;
    state $counter = 0;
    printf "- %-8d %-30.30s: %-32.32s %-32.32s => %d | %s\n",
        $topic->{tid}, $topic->{title},
        $topic->{timestampISO},
        $topic->{lastposttimeISO},
        $topic->{postcount},
        $topic->{deleted},
        ;
    return undef if $topic->{deleted};
    return 1;
});
