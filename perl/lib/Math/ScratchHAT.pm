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

    my $system = Math::ScratchHAT::->new('myQuantumSystem');
    my $sys2 = Math::ScratchHAT::->new();   # name defaults to 'system' if not given

=cut

sub new
{
    my ($class, $sysname) = @_;
    return bless { name => $sysname // 'system', q => {}, order => [] }, $class;
}

=head2 addQubit

Adds a new qubit to the system.

=cut

sub addQubit
{
    my ($self, $name) = @_;
    if(exists $self->{q}{$name}) {
        warn "cannot create a second '$name' qubit, sorry; I'll assume you've just forgotten, and will continue running without creating anything new";
        return;
    }
    push @{$self->{order}}, $name;
    $self->{q}{$name} = Math::ScratchHAT::Qubit::->new();
}

=head2 toggleQubit

Toggles the specified qubit

    $system->toggleQubit('m1');

=cut

sub toggleQubit
{
    my ($self, $name) = @_;
    if(!exists $self->{q}{$name}) {
        die "cannot toggle non-existing '$name' qubit";
    }
    $self->{q}{$name}->toggle;
}

=head2 print

Print all the qubits in ket notation, like:

    => system: |TTF>

If the optional argument is true, also print the individual qubit values with their name

    .. qubit(m1) = T
    .. qubit(m2) = T
    .. qubit(ans) = F
    => system: |TTF>

=cut

sub print
{
    my ($self, $individual) = @_;

    my $ket = '|';
    for my $name ( @{ $self->{order} }) {
        my $val = $self->{q}{$name}->observe();
        my $str = (qw/F T/)[$val];
        $ket .= $str;
        print ".. qubit($name) = $str\n" if $individual;
    }
    $ket .= '>';
    printf "=> %s: %s\n", $self->{name}, $ket;
}

=head2 HAT

"Hadamard All the Things" => Runs the Hadamard transformation on each qubit in the system

=cut

sub HAT
{
    my ($self) = @_;

    for my $name ( @{ $self->{order} }) {
        $self->{q}{$name}->hadamardMe();
    }

    return $self;
}


1;
