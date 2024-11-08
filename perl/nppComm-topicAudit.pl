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
sub auditThisTopic {
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
        if(@$postsToDelete) {
            #++$counter;
            for my $pid ( reverse @$postsToDelete )  {      # cannot purge first post in topic unless all others deleted, so go in reverse order
                # now permanently delete each post
                $comm->purgePost($pid);
            }
        }
        $str .= "        - PURGING TOPIC\n";
        print STDERR $str;
        # ... and purge the topic
        $comm->purgeTopic($topic->{tid});
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

            # ... and purge the empty topic
            $comm->purgeTopic($topic->{tid});
        }
    }

    return 1;# if $counter < 5;
}

#$comm->forAllTopicsInCategoryDo(3,\&auditThisTopic);

$comm->forAllCategoriesDo(sub {
    my ($category) = @_;
    printf STDERR "Category %2d: \"%s\": topic_count:%d vs totalTopicCount:%d, with post_count:%d\n",
        $category->{cid},
        $category->{name},
        $category->{topic_count},
        $category->{totalTopicCount},
        $category->{post_count},
        ;
    return 0 if $category->{post_count} > 1000;
    $comm->forAllTopicsInCategoryDo($category->{cid},\&auditThisTopic);
    return 1;
});
