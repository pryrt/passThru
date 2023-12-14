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

=head2 conditionalToggle

Conditionally toggles the qubit named C<$thenName> if the qubit named C<$ifName> is true

    $system->conditionalToggle( ifValue => $ifName, thenToggle => $thenName );

=cut

sub conditionalToggle
{
    my ($self, %conditions) = @_;

    # get the names (error checking)
    my $ifName = $conditions{ifValue} // die "conditionalToggle(%conditions) requires ifValue => 'name'";
    my $thenName = $conditions{thenToggle} // die "conditionalToggle(%conditions) requires thenToggle => 'name'";
    print STDERR "debug conditionalToggle: names = $ifName, $thenName\n";

    # make sure those named qubits exist (error checking) and grab a reference to the input $qi and output $qo
    my $qi = $self->{q}{$ifName} // die "conditionalToggle(%conditions) requires $ifName to be in the system";
    my $qo = $self->{q}{$thenName} // die "conditionalToggle(%conditions) requires $thenName to be in the system";
    print STDERR "debug conditionalToggle: qi = $qi, qo = $qo\n";

    # figure out the probability q (false) and p (true) for the conditional
    my $p = $qi->_p_true;
    my $q = 1 - $p;
    printf STDERR "debug conditionalToggle: prob:q(%s,false) = %s, prob:p(%s,true) = %s\n", $ifName, $q, $ifName, $p;

    # now compute the new amplitudes
    printf STDERR "debug conditionalToggle: old ampf(%s) = %s, ampt(%s) = %s\n", $thenName, $qo->{falseAmp}, $thenName, $qo->{trueAmp};
    my $new_amp_f = $q * $qo->{falseAmp} + $p * $qo->{trueAmp};     # probability q of staying false, p of toggling to true
    my $new_amp_t = $p * $qo->{falseAmp} + $q * $qo->{trueAmp};     # probability p of toggling false, q of staying true
    printf STDERR "debug conditionalToggle: new ampf(%s) = %s, ampt(%s) = %s\n", $thenName, $new_amp_f, $thenName, $new_amp_t;

    # and propagate them to the output qubit
    $qo->{falseAmp} = $new_amp_f;
    $qo->{trueAmp} = $new_amp_t;
    printf STDERR "debug conditionalToggle: final ampf(%s) = %s, ampt(%s) = %s\n", $ifName, $qi->{falseAmp}, $ifName, $qi->{trueAmp};
    printf STDERR "debug conditionalToggle: final ampf(%s) = %s, ampt(%s) = %s\n", $thenName, $qo->{falseAmp}, $thenName, $qo->{trueAmp};

    return $self;
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
    local $| = 1;

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
