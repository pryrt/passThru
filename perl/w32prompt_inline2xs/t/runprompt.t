#!perl
use Win32::Mechanize::NotepadPlusPlus::Prompt;

use 5.014; # //, strict, say, s///r
use warnings;
use Test::More tests => 4;
use Win32::GuiTest qw/GetForegroundWindow/;

my $hw = GetForegroundWindow();
my $txt = sprintf("hwnd(0x%08x)", $hw);

my $r = Win32::Mechanize::NotepadPlusPlus::Prompt::prompt_multiline(0, "multiple\nline\nprompt", "multiline(hw:0x00000000)", "this is the default value");
isnt $r, undef, "prompt_multiline(hw:0x00000000) => didn't cancel"; diag explain $r;

$r = Win32::Mechanize::NotepadPlusPlus::Prompt::prompt_multiline($hw, "multiple\nline\nprompt", "multiline($txt)", "this is the default value");
isnt $r, undef, "prompt_multiline($txt) => didn't cancel"; diag explain $r;

$r = Win32::Mechanize::NotepadPlusPlus::Prompt::prompt(0, "with hwnd 0", "prompt(hw:0x00000000)", "another value");
isnt $r, undef, "prompt_multiline(hw:0x00000000) => didn't cancel"; diag explain $r;

$r = Win32::Mechanize::NotepadPlusPlus::Prompt::prompt($hw, "single line", "prompt($txt)", "last value");
isnt $r, undef, "prompt_multiline($txt) => didn't cancel"; diag explain $r;

done_testing();

__END__

