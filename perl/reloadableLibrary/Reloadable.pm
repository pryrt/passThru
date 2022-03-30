#!perl
package Reloadable;
# inspired by https://gitlab.com/jspielmann/shippid/

use 5.012; # strict, //
use warnings;

my $class2pm = sub {
    my $class = shift;
    my $path = ($class . '.pm') =~ s{::}{/}gr;    # append .pm and convert :: to /
};

sub _new
{
    my ($class, %state) = @_;
    # printf STDERR "%s::_new(%s), state has %d key=>value pairs\n", __PACKAGE__, $class//'<undef>', scalar %state;
    my $pm = $class2pm->($class);
    die sprintf "%s->_new() => cannot find INC{%s}", $class, $pm unless exists $INC{$pm} and defined $INC{$pm};
    #printf STDERR "\tINC{%s} = %s\n", $pm, $INC{$pm}//'<undef>';
    my $self = {
        _mod_name => $class,
        _mod_file => $INC{$pm},
        _mod_time => -M $INC{$pm},
        state => \%state,
    };
    return bless $self, $class;
}

sub get_state
{
    my ($self) = @_;
    %{$self->{state}};
}

sub state_variable : lvalue
{
    my ($self, $varname) = @_;
    die "self->state_variable(varname): must supply varname" unless defined $varname;
    $self->{state}{$varname};   # returns  LVALUE
}

sub reload
{
    my ($self) = @_;
    my $class = ref($self);
    my $pm = $class2pm->($class);
    my %state = $self->get_state();

    #printf STDERR "INSIDE reload(%s): class=%s, pm=%s\n", $self, $class, $pm;

    # check timestamp
    # since -M returns a bigger number the longer ago it was, the test in perl will be if -M is LESS than _mod_time
    my $new_mtime = -M $self->{_mod_file};
    # printf STDERR "\tstored mod time = %s\n", $self->{_mod_time};
    # printf STDERR "\trecent mod time = %s\n", $new_mtime;

    # don't need to reload if the timestamp hasn't updated
    return $self unless $new_mtime < $self->{_mod_time};

    # continue with reload logic

    # loop through stash for the class and delete all the entries (avoid redefine warning, I think)
    my $stash = $::{$class . '::'} // die "missing stash for class $class!";
    for my $k (sort { CORE::fc($a) cmp CORE::fc($b) } keys %{$stash}) {
        #printf STDERR "DELETE ::{%s}{%s} => %s\n", $class.'::', $k, scalar
        delete $stash->{$k};
    }

    # then delete the stash for that class
    delete $::{$class . '::'};

    # finally delete the %INC entry for the class, so it can be reloaded
    delete $INC{$pm};

    # ### DEBUG: main stash after deletion
    # for my $k (sort { CORE::fc($a) cmp CORE::fc($b) } grep /Reload/i, keys %::) {
    #     printf STDERR "DEBUG after deletion ::{%s} => %s\n", $k, scalar $::{$k};
    # }

    # reload the reloadable class
    require $pm;

    # ### DEBUG: main stash after deletion
    # for my $k (sort { CORE::fc($a) cmp CORE::fc($b) } grep /Reload/i, keys %::) {
    #     printf STDERR "DEBUG after require ::{%s} => %s\n", $k, scalar $::{$k};
    # }

    # create a new self
    return $class->_new(%state);
}

__PACKAGE__
