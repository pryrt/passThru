#!perl
use Win32::Mechanize::NotepadPlusPlus::Prompt;

use 5.014; # //, strict, say, s///r
use warnings;
use Test::More tests => 2;

my $r = Win32::Mechanize::NotepadPlusPlus::Prompt::myPrompt("multiple\nline\nprompt", "this is my title", "this is the default value", 1);
isnt $r, undef, "myPrompt|multiline => didn't cancel"; diag explain $r;

$r = Win32::Mechanize::NotepadPlusPlus::Prompt::myPrompt("single line prompt", "short title", "default value");
isnt $r, undef, "myPrompt|singleline => didn't cancel"; diag explain $r;
done_testing();
