package Win32::Mechanize::NppCommunity;
use 5.014;              # strict, //, s//r
use warnings;
use Exporter 5.57 'import';
our $VERSION = '0.001'; # rrr.mmmsss : rrr is major revision; mmm is minor revision; sss is sub-revision (new feature path or bugfix); optionally use _sss instead, for alpha sub-releases

=pod

=encoding utf8

=head1 NAME

Win32::Mechnize::NppCommunity - Automate Admin/Moderator tasks for the Notepad++ Community Forum

=cut

our @EXPORT = ();

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

sub client { $_[0]->{_client} }

1;
