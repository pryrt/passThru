package Win32::Mechanize::NppCommunity;
use 5.014;              # strict, //, s//r
use warnings;
use JSON();
use Exporter 5.57 'import';
our $VERSION = '0.001'; # rrr.mmmsss : rrr is major revision; mmm is minor revision; sss is sub-revision (new feature path or bugfix); optionally use _sss instead, for alpha sub-releases
our @EXPORT = ();


# https://github.com/pryrt/nppStuff/blob/main/CommunityForum/API%20Access.md
# https://docs.nodebb.org/api/write
# https://docs.nodebb.org/api/read
=pod

=encoding utf8

=head1 NAME

Win32::Mechnize::NppCommunity - Automate Admin/Moderator tasks for the Notepad++ Community Forum

=head1 CONSTRUCTORS

=over

=item new

    my $community = Win32::Mechnize::NppCommunity::->new($tokenFile);

Creates the new NppCommunity object, and initializes the HTTP client for the REST API

=back

=cut

sub new
{
    my ( $class, $tokenFile ) = @_;
    $tokenFile //= './~$token';    # default
    my $self = bless {}, $class;

    my $token;
    if ( !-f $tokenFile ) {
        die "Could not find token in '$tokenFile'";
    } else {
        open my $fh, '<', $tokenFile;
        chomp($token = <$fh>);
    }

    $self->{_client} = HTTP::Tiny->new(
        default_headers => {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'Authorization' => "Bearer $token",
        },
    );

    return $self;
}

=head1 METHODS

=over

=item client

    $community->client()->get(...); # sends a GET request using the HTTP client

Gives direct access to the HTTP client.  (Allows extending for when there isn't a method defined for a given action)

=cut

sub client { $_[0]->{_client}; }

=item forAllUsersDo

    $community->forAllUsersDo(sub {
        my ($user) = @_;
        return 0 if ...; # return 0 if you want to skip the action on this user
        return 1 if ...; # return 1 if you performed the action on this user
        return undef;    # return undef if you want to stop processing any more users
    });


Runs a subroutine for each user.  The subroutine needs to take in the L<$user> object
as the first argument.  It should return a true value if the action was performed for the user;
it should return 0 or "" if the action was skipped for the user; it should return L<undef>
if the loop needs to stop (don't process the remaining users).

=for HTML <img src="NppCommunity-User.png" class="uml">

=begin comment

    <Command name="PlantUML to PNG" Ctrl="yes" Alt="yes" Shift="yes" Key="80">&quot;c:\usr\local\apps\PlantUML\PngAllActive.bat&quot; &quot;$(FULL_CURRENT_PATH)&quot;</Command>

        @echo off
        echo generate PlantUML from "%1"
        "C:\Cadence\SPB_17.4\tools\pcbdw\java11\bin\java.exe" -D:file.encoding=UTF-8 -jar "%~dp0\plantuml-1.2023.0.jar" -charset UTF-8 %1
        echo created "%~dpn1*.png"
        dir "%~dpn1*.png"
        pause

        https://plantuml.com/download

    <Command name="POD To .pod.html" Ctrl="yes" Alt="yes" Shift="no" Key="80">cmd /c c:\usr\local\scripts\pod2html_clean.bat --css=c:\usr\local\scripts\pod2html.css &quot;$(FULL_CURRENT_PATH)&quot; &gt; &quot;$(CURRENT_DIRECTORY)/~$$(NAME_PART).pod.html&quot;</Command>

=end comment

=begin PlantUML

@startuml NppCommunity-User

skinparam caption {
    FontName monospaced
    FontSize 16
}
Title User Object
Legend left
**Key:**
| <&info> | structures defined elsewhere |
| ... | same structure as the entry above |
| $var | variable value rather than exact text |
| # | comment |

More description down here
endlegend
Caption $data
label EncapsulateYaml [
{{yaml
userCount: ""$n"" 
users:
    -
        uid: 0
        username: "string"
        displayname: "string"
        userslug: "string"
        picture: "string"
        status: "string"
        postcount: 0
        reputation: 0
        email&#58;confirmed: 0
        lastonline: 0
        flags: null
        banned: 0
        banned&#58;expire: 0
        joindate: 0
        icon&#58;text: "string"
        icon&#58;bgColor: "#f44336"
        joindateISO: "string"
        lastonlineISO: "string"
        banned_until: 0
        banned_until_readable: "string"
    - ...
    - $userN
pagination:
    page: 0,
    currentPage: 0,
    pageCount: 0,
    first: ""{...}"" 
    last: ""{...}"" 
...: ...
}}
]

@enduml

=end PlantUML

=cut

sub forAllUsersDo
{
    my ($self, $cref) = @_;
    my $page = 1;
    while(defined $page) {
        my $response = $self->client()->get('https://community.notepad-plus-plus.org/api/users?section=joindate&page='.$page);
        die "$response->{status} $response->{reason}" unless $response->{success};
        my $data = JSON::decode_json($response->{content});
        my $lastpage = $data->{pagination}{last}{page};
        printf "pg %4d/%-4d:\t%d users\n", $page, $lastpage, scalar @{$data->{users}};
        for my $user ( @{$data->{users}} ) {
            return unless defined $cref->($user);
        }
        if(++$page > $lastpage) { undef $page; }
    }
}

=item forAllTopicsDo

    $community->forAllTopicsDo(sub {
        my ($user) = @_;
        return 0 if ...; # return 0 if you want to skip the action on this topic
        return 1 if ...; # return 1 if you performed the action on this topic
        return undef;    # return undef if you want to stop processing any more topics
    });


Runs a subroutine for each topic.  The subroutine needs to take in the L<$topic> object
as the first argument.  It should return a true value if the action was performed for the topic;
it should return 0 or "" if the action was skipped for the topic; it should return L<undef>
if the loop needs to stop (don't process the remaining topics).

=for HTML <img src="NppCommunity-User.png" class="uml">

=begin comment

    <Command name="PlantUML to PNG" Ctrl="yes" Alt="yes" Shift="yes" Key="80">&quot;c:\usr\local\apps\PlantUML\PngAllActive.bat&quot; &quot;$(FULL_CURRENT_PATH)&quot;</Command>

        @echo off
        echo generate PlantUML from "%1"
        "C:\Cadence\SPB_17.4\tools\pcbdw\java11\bin\java.exe" -D:file.encoding=UTF-8 -jar "%~dp0\plantuml-1.2023.0.jar" -charset UTF-8 %1
        echo created "%~dpn1*.png"
        dir "%~dpn1*.png"
        pause

        https://plantuml.com/download

    <Command name="POD To .pod.html" Ctrl="yes" Alt="yes" Shift="no" Key="80">cmd /c c:\usr\local\scripts\pod2html_clean.bat --css=c:\usr\local\scripts\pod2html.css &quot;$(FULL_CURRENT_PATH)&quot; &gt; &quot;$(CURRENT_DIRECTORY)/~$$(NAME_PART).pod.html&quot;</Command>

=end comment

=begin PlantUML

@startuml NppCommunity-Topic

skinparam caption {
    FontName monospaced
    FontSize 16
}
Title Topic Object
Legend left
**Key:**
| <&info> | structures defined elsewhere |
| ... | same structure as the entry above |
| $var | variable value rather than exact text |
| # | comment |

More description down here
endlegend
Caption $data
label EncapsulateYaml [
{{yaml
topicCount: ""$n"" 
topics:
    -
        tid: 0
        uid: 0
        cid: 0
        title: "string"
        slug: "string"
        mainPid: 0
        postcount: 0
        viewcount: 0
        postercount: 0
        scheduled: 0
        deleted: 0
        deleterUid: 0
        titleRaw: "string"
        locked: 0
        pinned: 0
        timestamp: 0
        timestampISO: "string"
        lastposttime: 0
        lastposttimeISO: "string"
        pinExpiry: 0
        pinExpiryISO: "string"
        upvotes: 0
        downvotes: 0
        votes: 0
        teaserPid: 0
        thumbs: ""[]"" 
        numThumbs: 0
        category: ""{}"" 
        user: ""{}"" 
        teaser: ""{}"" 
        tags: ""[]"" 
        isOwner: true
        ignored: true
        followed: true
        unread: true
        bookmark: 0
        unreplied: true
        icons: ""[]"" 
        thumb: "string"
        index: 0
    - ...
    - $topicN
pagination:
    page: 0,
    currentPage: 0,
    pageCount: 0,
    first: ""{...}"" 
    last: ""{...}"" 
...: ...
}}
]

@enduml

=end PlantUML


=cut

sub forAllTopicsDo
{
    my ($self, $cref) = @_;
    my $page = 1;
    while(defined $page) {
        # originally /api/recent, but that only gives 10 pages (200 topics)
        # /api/top also limited to 10 pages
        my $response = $self->client()->get('https://community.notepad-plus-plus.org/api/recent?page='.$page);
        die "$response->{status} $response->{reason}" unless $response->{success};
        my $data = JSON::decode_json($response->{content});
        my $lastpage = $data->{pagination}{last}{page};
        printf "pg %4d/%-4d:\t%d topics\n", $page, $lastpage, scalar @{$data->{topics}};
        for my $topic ( @{$data->{topics}} ) {
            return unless defined $cref->($topic);
        }
        if(++$page > $lastpage) { undef $page; }
    }
}

=item getTopicDetails

    $community->getTopicDetails($topicID);

C<forAllTopicsDo>'s loop only gets the simplified topic details from the C</api/recent> endpoint.
This method gets the more detailed results, which includes the information about each post inside the topic.

=cut

sub getTopicDetails
{
    my ($self, $topicID) = @_;
    my $response = $self->client()->get('https://community.notepad-plus-plus.org/api/topic/'.$topicID);
    die "$response->{status} $response->{reason}" unless $response->{success};
    return my $data = JSON::decode_json($response->{content});
}

=back

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

=head1 COPYRIGHT

Copyright (C) 2024 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
