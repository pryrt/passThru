#!/usr/bin/perl
use 5.012;
use warnings;
use Win32::API;

BEGIN {
    # https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessage
    Win32::API::->Import("user32", <<ENDPROTO) or die "Import SendMessage FAILED: $^E";
LRESULT SendMessage(
    HWND hWnd, 
    UINT Msg, 
    WPARAM wParam, 
    LPARAM lParam
)
ENDPROTO
        
    # https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-dialogboxindirectparamw
    Win32::API::->Import("user32", <<ENDPROTO) or die "Import DialogBoxIndirectParam FAILED: $^E";
INT_PTR DialogBoxIndirectParamW(
    HINSTANCE       hInstance,
    LPSTR           hDialogTemplate,
    HWND            hWndParent,
    LPVOID          lpDialogFunc,
    LPARAM          dwInitParam
)
ENDPROTO
    # https://metacpan.org/pod/Win32%3A%3AAPI#USING-STRUCTURES -- shows how to define a structure, and then do an LP to that structure
    # I think maybe Win32::API::Callback is the way to define callback functions
}

# Try taking the bytearray output of a dead-simple dialog (title and OK button)
#   from the PythonScript3 dialog builder, and see if I can pass it to 
#   Win32::API-based DialogBoxIndirectParam()
my $bytearray = '\x01\x00\xff\xff\x00\x00\x00\x00\x80\x00\x00\x00C\x00\x08\x00\x01\x00\x00\x00\x00\x00\xbe\x00\xd2\x00\x00\x00\x00\x00M\x00y\x00T\x00i\x00t\x00l\x00e\x00\x00\x00\x08\x00\x90\x01\x00\x01M\x00S\x00 \x00S\x00h\x00e\x00l\x00l\x00 \x00D\x00l\x00g\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x93\x00P\n\x00\n\x002\x00\x16\x00\x01\x04\x00\x00B\x00u\x00t\x00t\x00o\x00n\x00\x00\x00O\x00K\x00\x00\x00\x00\x00\x00\x00';
use Data::Dump; dd [bytearray => $bytearray];
my $rv = DialogBoxIndirectParamW(0, $bytearray, 0, 0, 0);
eval {
    print STDERR "DialogBoxIndirectParamW returned $rv\n";
    die "\tERR>> $^E" if $rv < 1;
};
print "StringAt: '$@'";
=begin

https://perlmonks.org/index.pl?node_id=1199451 
    -- example with Win32::API::Callback

https://www.reddit.com/r/perl/comments/1i13h7/win32api_and_user32setwineventhook_help/
    -- maybe shows a real CALLBACK situation
    
https://stackoverflow.com/questions/10406277/how-can-i-pass-a-pointer-to-a-perl-function-as-a-callback-to-a-function-with-poi
    -- and here
    
https://community.notepad-plus-plus.org/post/45891
    -- how did I not remember when Eko was flexing and showed FindWindowExW, complete with callback,
        showing that it works
=cut
