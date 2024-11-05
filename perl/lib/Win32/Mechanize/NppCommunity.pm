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
