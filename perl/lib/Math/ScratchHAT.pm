package Math::ScratchHAT;
use 5.014; # strict, //, s//r
use warnings;

use Math::ScratchHAT::Qubit;
our $VERSION = $Math::ScratchHAT::Qubit::VERSION;

=head1 DESCRIPTION

The B<ScratchHAT> object is essentially a hash that holds zero or more named B<Qubits>.

You can think of it as a "Quantum System".

=head1 METHODS

=head2 new

Creates a new B<ScratchHAT> quantum system.

=cut

sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

=head2 addQubit

Adds a new qubit to the system.

=cut

sub addQubit
{
    my ($self, $name) = @_;
    if(exists $self->{$name}) {
        warn "cannot create a second '$name' qubit, sorry; I'll assume you've just forgotten, and will continue running without creating anything new";
        return;
    }
    $self->{$name} = undef; # Math::ScratchHAT::Qubit::->new();
}

1;
