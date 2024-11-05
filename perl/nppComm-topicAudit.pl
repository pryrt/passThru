#!perl
# topicAudit:
#   check topics:
#       if topic is deleted, check to see if any of its posts need to be deleted [TODO: then delete them]
#       if topic undeleted, check if all its posts already deleted [TODO: then delete it]
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

# ugh: unfortunately, the /api/recent or /api/top or /api/popular all limit to 10 pages (200 topics),
#   so I am not sure how to actually loop through all.
# Still, this is enough to find a couple deleted topics that have undeleted posts
$comm->forAllTopicsDo(sub {
    my ($topic) = @_;
    state $counter = 0;
    my $str = sprintf "- %-8d %-30.30s: %-32.32s %-32.32s => %d | %s\n",
        $topic->{tid},
        $topic->{title},
        $topic->{timestampISO},
        $topic->{lastposttimeISO},
        $topic->{postcount},
        $topic->{deleted},
        ;
    if($topic->{deleted}) {
        my $posts = $comm->getTopicDetails($topic->{tid})->{posts};
        my $postsToDelete = [];
        for my $post (@$posts) {
            if(! $post->{deleted}) {
                die "why was string empty" unless length($str);
                print STDERR "len(str) = ", length($str), "(before), ";
                $str .= sprintf "    - %-8d by %-8d: %-32.32s | TO DELETE\n",
                    $post->{pid},
                    $post->{uid},
                    $post->{timestampISO},
                    ;
                print STDERR length($str), "(after)\n";

                push @$postsToDelete, $post->{pid};

                # TODO: ... and delete it
            }
        }
        if(@$postsToDelete) {
            print STDERR $str;
            ++$counter;
        }
    }
    return 1 if $counter < 5;
    return undef;
});
