#!perl

use 5.012; # strict, //
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib/lib/perl5";

use App::Search::BackPAN;

package App::Search::BackPAN;
use Data::Dump (); # qw/pp/;

sub search_for_dist
{
    my ($self, $dist_substr, $show_progress) = @_;

    $self->_check_dist_substr($dist_substr);

    $self->{matching_dists} = [];

    for my $letters ( 'AA' .. 'ZZ' ) {
        # $self->{pause_id}           = $letters;
        $self->{first_letter}       = substr($letters, 0, 1);
        $self->{first_two_letters}  = substr($letters, 0, 2);
        next unless eval {
            $self->_validate_first_letter;
            $self->_validate_first_two_letters;
            1;
        };
        my $authors = $self->_fetch_authors;
        next unless keys %$authors;
        warn "$letters => {\n"  if $show_progress;
        for my $auth (keys %$authors) {
            $self->{pause_id} = $auth;
            $self->_fetch_distributions;
            for my $i ( reverse 0 .. $#{ $self->{distributions} }) {
                splice( @{$self->{distributions}}, $i, 1 ) if 0 > index($self->{distributions}[$i], $dist_substr)
            }
            my @local_matches = @{$self->_format_distributions};
            my $pp = (Data::Dump::pp([@local_matches]) =~ s/^/  /rgsm);
            warn sprintf "  %-20s => %s\n", $auth, $pp if $show_progress;
            push @{$self->{matching_dists}}, @local_matches if @local_matches;
        }
        warn "}\n" if $show_progress;
    }
    return $self->{matching_dists};
}

sub _check_dist_substr
{
    my ($self, $dist_substr) = @_;

    die "ERROR: Missing DISTRIBUTION substring" unless defined $dist_substr;
    #die "ERROR: DISTRIBUTION substring should be 3 or more characters long." unless (length($dist_substr) >= 3);
    return 1;
}

package main;
my $backpan = App::Search::BackPAN::->new();
die "usage $0 ModuleSubString\n\n" unless @ARGV;
for(@ARGV) {
    my $result = $backpan->search_for_dist($_, 1);
    print join "\n", @$result, "\n";
}
1;

__END__
This takes forever, because it's searching every author for it... 
I don't know of a faster way to search the BackPAN
