#!perl
package Win32::Mechanize::NotepadPlusPlus::Prompt;

use 5.014; # strict, //, s///r
use warnings;
our $VERSION = '0.01';
$|=1;

require XSLoader;
XSLoader::load('Win32::Mechanize::NotepadPlusPlus::Prompt', $VERSION);

sub myPrompt($$;$$) { $_[2] //= ''; $_[3] //= 0; _c_prompt(@_) }
