#!perl

use 5.014; # strict, //, s//r
use warnings;

BEGIN { $| = 1; }

=begin TextBackground

in one of the #SOME3 video submissions, there was a guy who made "quantum computing" in the Scratch programming language,
by implementing a storage unit that stored the amplitudes for True and False for a given qubit, using a Hadamard Transformation
to provide the quantumness -- he called the block "Hadamard All the Things", or "HAT" (hence "scratchHat.pl")

https://www.youtube.com/watch?v=VuWklQM_3q8

But I'm a bit confused about what state he uses behind the scenes for what he used to call "add 1", but then renamed...
because he was getting random output, but I thought it just swapped amplitude from true to false.  Maybe re-watching the video
and noting some of the behaviors will allow me to replicate it better.

Blocks:
    MakeAThingNamed STR
    Toggle STR
    IF (x) then Toggle STR
    PrintAllTheThings

First program (0:41)
    MakeAThingNamed myQubit
    HAT
    PrintAllTheThings
    => outputs |F> or |T> with 50/50 probability (so I might already have it wrong)
    His explanation
        myQubit can take on
            |F>
            or
            |T>
        at creation, all "1" of the amplitude is on false
            |F> = 1
            |T> = 0
            and observing it here would always see false... okay, so I was right
        Hadamard Transformation
            new |F> = |F> + |T>
            new |T> = |F> - |T>
            example:
                start at {1,0}
                sum 1+0
                diff 1-0
                end at {1,1}
        Print:
            probability is proportional to the square of the amplitude

Okay, now I should be able to implement such that mine will get the same results.

Before continuing with the video, make an attempt at the toggleQubit

Next (4:10 = https://youtu.be/VuWklQM_3q8?t=250)

=cut

use Data::Dump;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Math::ScratchHAT;

sub program1
{
    my $system = Math::ScratchHAT::->new();
    $system->addQubit('m1');
    $system->HAT();
    $system->print();
}
#program1() for 1..5;

sub program410
{
    my $system = Math::ScratchHAT::->new('toggleTest');
    $system->addQubit('m1');
    $system->toggleQubit('m1');
    #dd {beforeHAT => $system};
    $system->HAT();
    #dd {afterHAT => $system};
    $system->print();
}
# program410() for 1..10;

=begin TextBackground

Mine worked the same as his, and now we'll analyze (4:54)

    addQubit:
            |F> = 1
            |T> = 0
    toggleQubit: "has the effect of switching false and true", which is what I think I coded
            |F> = 0
            |T> = 1
    Hadamard Transformation
            new |F> = |F> + |T> = 0 + 1 = 1
            new |T> = |F> - |T> = 0 - 1 = -1
    I verified with dd on before/afterHAT that those were the states that were there

Next is 6:19

=cut

sub program619
{
    my $system = Math::ScratchHAT::->new('6:19 double HAT');
    $system->addQubit('myQubit');
    #dd {beforeHAT1 => $system};
    $system->HAT();
    #dd {afterHAT1 => $system};
    $system->HAT();
    #dd {afterHAT2 => $system};
    $system->print();
}
#program619() for 1..10;

=begin TextBackground

619 prints false every time.

    addQubit:
            |F> = 1
            |T> = 0
    Hadamard Transformation #1
            new |F> = |F> + |T> = 1 + 0 = 1
            new |T> = |F> - |T> = 1 - 0 = 1
    Hadamard Transformation #2
            new |F> = |F> + |T> = 1 + 1 = 2
            new |T> = |F> - |T> = 1 - 1 = 0     # interference
    => 100% probability of myQubit == false


next at 9:20 is the huge finale from the "demo" video

=cut

sub program920
{
    my $system = Math::ScratchHAT::->new('9:20 mysteryToggles');
    $system->addQubit('m1');
    $system->addQubit('m2');
    $system->addQubit('m3');
    $system->addQubit('m4');
    $system->addQubit('m5');
    $system->addQubit('m6');
    $system->addQubit('ans');

    # pretend I don't know what's inside $mystery
    my $mystery = sub {
        $system->conditionalToggle( ifValue => 'm1', thenToggle => 'ans');
        #$system->conditionalToggle( ifValue => 'm3', thenToggle => 'ans');
        #$system->conditionalToggle( ifValue => 'm4', thenToggle => 'ans');
        #$system->conditionalToggle( ifValue => 'm5', thenToggle => 'ans');
    };

    # when you run togglesDetective, you "magically" get it to tell you which toggles are in mystery!
    my $togglesDetective = sub {
        $system->toggleQubit('ans');
        dd { detectiveToggledAns => $system };
        $system->HAT();
        dd { detectiveHAT1 => $system };
        $mystery->();
        dd { detectiveAfterMystery => $system };
        $system->HAT();
        dd { detectiveHAT2 => $system };
        $system->print();
    };
    $togglesDetective->();

}
program920 for 1;#..10

=begin TextBackground

    So mystery toggles (as defined above) has 64 (2**6) possibilities for what it _might_ contain

    10:04 When you run, it tells you what's inside the mystery. <https://youtu.be/VuWklQM_3q8?t=604>

ASIDE

    Unfortunately, I'm not confident I know how ifValue-thenToggle works on the quantum system.
    I don't think he explains it, but I'll try to implement what I think it's doing before I continue
    with the video explanation

    My guess: if there is probability q that ifValue is false, and p that it's true, then
    answer would be the sum of q * original-answer-amplitudes (don't toggle on false),
    plus p * swapped-answer-amplitudes (do toggle/swap on true)

    Unfortunately, my first implementation gives a divide-by-zero, so I've got to figure that out.
    With nothing in mystery(), it works correctly.
    If mystery just has if(m1)then(ans), I get divide-by-zero:
    - somehow, running mystery is setting 'ans' to (0,0)
        - need to single-step through to figure out why
        - After toggle(ans) and HAT1, ans = {Famp=1, Tamp=-1}
          and p=q=0.5, so
            newF: {q*Famp+p*Tamp} = {0.5*1+0.5*-1} = {0}
            newT: {p*Famp+q*Tamp} = {0.5*1+0.5*-1} = {0}
          and when you try to calculate probabilities when the amplitudes are both 0, you get divide-by-zero
    - unfortunately, I don't know how to fix that.

    Try watching more of video, and see if he explains the math of the toggle-if block
    - so the first thing I notice is that for his trio example M1,M2,ANS, after the toggle and HAT1 (15:20), he's in
            |FFF> +1                        |FFT> -1
            |FTF> +1                        |FTT> -1
            |TFF> +1                        |TFT> -1
            |TTF> +1                        |TTT> -1
      But he's only showing the combined amplitudes, _not_ the amplitudes of the individual qubits...
      And I'm not sure how to go from the individual amplitudes to the full amplitudes
    - At 16:02, he starts talking about the "if m2 then toggle ans" in the combined state... so
      I will go through that process, and then later, if I can figure out how to convert amplitudes
      from individual->to->system (and hopefully system->to->individual), then I might see what the
      individual qubits are supposed to do
        * look at m2's value in each of the kets (|M1,M2,ANS>)
                      m2                                m2
            |FFF> +1  FALSE                 |FFT> -1    FALSE
            |FTF> +1  TRUE                  |FTT> -1    TRUE
            |TFF> +1  FALSE                 |TFT> -1    FALSE
            |TTF> +1  TRUE                  |TTT> -1    TRUE
        * on those, swap the T and F amplitudes for ANS, which in my nomenclature means swapping amplitudes
          from the left column to the right column for the same row
            |FFF> +1  NO CHANGE             |FFT> -1    NO CHANGE
            |FTF> -1  SWAP FROM RIGHT       |FTT> +1    SWAP FROM LEFT
            |TFF> +1  NO CHANGE             |TFT> -1    NO CHANGE
            |TTF> -1  SWAP FROM RIGHT       |TTT> +1    SWAP FROM LEFT
        * 16:56 ends the mystery-toggles subroutine description
    _ TODO: figure out how to do the mappings, so I can see how the SYSTEM amps shown above
      correspond to individual amplitudes for each qubit in the system
=cut
