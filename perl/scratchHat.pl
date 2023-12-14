#!perl

use 5.014; # strict, //, s//r
use warnings;

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
program619() for 1..10;

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
