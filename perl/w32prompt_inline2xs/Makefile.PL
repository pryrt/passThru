use strict;
use warnings;
use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Win32::Mechanize::NotepadPlusPlus::Prompt',
    VERSION_FROM    => 'lib/Win32/Mechanize/NotepadPlusPlus/Prompt.pm',
    PREREQ_PM       => {
        'XSLoader'  => 0,
    },
    #ABSTRACT_FROM   => 'lib/Win32/Mechanize/NotepadPlusPlus/Prompt.pm',
    AUTHOR          => 'me',
    LICENSE         => 'perl',

    # XS & C Compilation Configurations
    #LIBS              => ['-lm'],          # External libraries to link (e.g., math library '-lm')
    #DEFINE            => '-DHAVE_SOMETHING', # Preprocessor compiler flags
    INC               => '-I.',            # Path to include directories containing C headers
    OBJECT            => '$(O_FILES)',     # Tells MakeMaker to compile and link all .c/.xs files
    OPTIMIZE          => '-O3',            # Optimizes C code compilation speed

);
