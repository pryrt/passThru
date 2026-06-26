#!perl
package Win32::Mechanize::NotepadPlusPlus::Prompt;

use 5.014; # strict, //, s///r
use warnings;
our $VERSION = '0.01';
$|=1;

require XSLoader;
XSLoader::load('Win32::Mechanize::NotepadPlusPlus::Prompt', $VERSION);

sub prompt($$$;$) { $_[0] //= 0; $_[3] //= ''; $_[4] = 0; _c_prompt(@_) }
sub prompt_multiline($$$;$) { $_[0] //= 0; $_[3] //= ''; $_[4] = 1; _c_prompt(@_) }
