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
use Data::Dump();
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
$comm->forAllTopicsInCategoryDo(3, sub {
    my ($topic) = @_;
    state $counter = 0;
    my $str = sprintf "    - %-8d %-30.30s: %-32.32s %-32.32s => %d | %s\n",
        $topic->{tid},
        $topic->{title},
        $topic->{timestampISO},
        $topic->{lastposttimeISO},
        $topic->{postcount},
        $topic->{deleted},
        ;
    my $posts = $comm->getTopicDetails($topic->{tid})->{posts};
    if($topic->{deleted}) {
        my $postsToDelete = [];
        for my $post (@$posts) {
            if(! $post->{deleted}) {
                die "why was string empty" unless length($str);
                $str .= sprintf "        - %-8d by %-8d: %-32.32s | TO DELETE POST\n",
                    $post->{pid},
                    $post->{uid},
                    $post->{timestampISO},
                    ;

                push @$postsToDelete, $post->{pid};
            }
        }
        if(@$postsToDelete or $topic->{tid}==26038) {
            print STDERR $str;
            #++$counter;
            for my $pid ( reverse @$postsToDelete )  {      # cannot purge first post in topic unless all others deleted, so go in reverse order
                # now permanently delete each post
                $comm->purgePost($pid);
            }
        } else {
            $str .= "        - PURGE TOPIC NEXT?\n";
            print STDERR $str;
        }
        # TODO: ... and delete the topic
    } else {
        my $undeletedCount = 0;
        for my $post (@$posts) {
            $undeletedCount++ if !$post->{deleted};
        }
        $str .= sprintf "        - postcount: %d, array size: %d, undeleted: %d\t\t | TO DELETE TOPIC\n",
            $topic->{postcount},
            scalar @$posts,
            $undeletedCount;
        if(!$undeletedCount) {
            print STDERR $str;
            ++$counter;

            # TODO: ... and delete the topic
        }
    }

    return 1;# if $counter < 5;
});

##### my $known = $comm->getTopicDetails(20942);  # 26243=deleted with 2 deleted; 20942=undeleted topic with 1 deleted post and N undeleted
#####
##### #print $known->{postcount}, scalar( @{$known->{posts}});
##### printf "%-30.30s => %s\n", $_//'<undef>', $known->{$_}//'<undef>' for sort keys %$known;
##### my $undeletedCount = 0;
##### for my $post ( @{ $known->{posts} } ) {
#####     $undeletedCount++ if !$post->{deleted};
##### }
##### print "undeleted = $undeletedCount\n";
#####

# Data::Dump::dd($comm->deletePost(18509)); # confirmed working
# Data::Dump::dd($comm->purgePost(18509));  # confirmed working, whether post is already soft-deleted or not
