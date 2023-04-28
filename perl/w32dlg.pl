#!/usr/bin/perl
use 5.012;
use warnings;
use Win32::API;
use Encode;
use Data::Dump;

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

    # https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulehandlew
    Win32::API::->Import("kernel32", <<ENDPROTO) or die "Import GetModuleHandleW FAILED: $^E";
HMODULE GetModuleHandleW(
    LPCWSTR lpModuleName
)
ENDPROTO
}

# Try taking the bytearray output of a dead-simple dialog (title and OK button)
#   from the PythonScript3 dialog builder, and see if I can pass it to
#   Win32::API-based DialogBoxIndirectParam()
####    my $bytearray = '\x01\x00\xff\xff\x00\x00\x00\x00\x80\x00\x00\x00C\x00\x08\x00\x01\x00\x00\x00\x00\x00\xbe\x00\xd2\x00\x00\x00\x00\x00M\x00y\x00T\x00i\x00t\x00l\x00e\x00\x00\x00\x08\x00\x90\x01\x00\x01M\x00S\x00 \x00S\x00h\x00e\x00l\x00l\x00 \x00D\x00l\x00g\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x93\x00P\n\x00\n\x002\x00\x16\x00\x01\x04\x00\x00B\x00u\x00t\x00t\x00o\x00n\x00\x00\x00O\x00K\x00\x00\x00\x00\x00\x00\x00';
####    dd [bytearray => $bytearray];
####    my $rv = DialogBoxIndirectParamW(0, $bytearray, 0, 0, 0);
####    eval {
####        print STDERR "DialogBoxIndirectParamW returned $rv\n";
####        die "\tERR>> $^E" if $rv < 1;
####    };
####    print "StringAt: '$@'";
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

# WinDialog\win_helper\__init__.py::Dialog::__create_dialog
#   - skip objects, and do the low-level stuff
#   - skip any controls; first task is just to get it to show a dialog
#   - dialog_template.py::Window::__init__() just sets the python class data structures
#   - dialog_template.py::Window::create() actually populates the bytearray
#        element                                        bytes
#        self._array += WORD(self.dlgVer)               2
#        self._array += WORD(self.signature)            2
#        self._array += DWORD(self.helpID)
#        self._array += DWORD(self.exStyle)
#        self._array += DWORD(self.style)
#        self._array += WORD(self.cDlgItems)
#        self._array += SHORT(self.x)
#        self._array += SHORT(self.y)
#        self._array += SHORT(self.cx)
#        self._array += SHORT(self.cy)
#        self._array += WORD(self.menu)
#        if isinstance(self.windowClass, str):
#            windowClass = create_unicode_buffer(self.windowClass)
#        elif isinstance(self.windowClass, int):
#            windowClass = WORD(self.windowClass)
#        self._array += windowClass
#        self._array += create_unicode_buffer(self.title)
#        # currently hard coded
#        self._array += WORD(8)                                # pointsize
#        self._array += WORD(400)                              # weight
#        self._array += BYTE(0)                                # italic
#        self._array += BYTE(0x1)                              # charset
#        self._array += create_unicode_buffer('MS Shell Dlg')  # typeface
#   => oh, right, just use the Struct definer...    https://learn.microsoft.com/en-us/windows/win32/dlgbox/dlgtemplateex
Win32::API::Struct->typedef( 'DLGTEMPLATEEX' => qw(
    WORD      dlgVer;
    WORD      signature;
    DWORD     helpID;
    DWORD     exStyle;
    DWORD     style;
    WORD      cDlgItems;
    short     x;
    short     y;
    short     cx;
    short     cy;
    LPWSTR    menu;
    LPWSTR    windowClass;
    WCHAR     title[titleLen];
    WORD      pointsize;
    WORD      weight;
    BYTE      italic;
    BYTE      charset;
    WCHAR     typeface[stringLen];
));

my $w = Win32::API::Struct->new('DLGTEMPLATEEX');
$w->{dlgVer} = 1;
$w->{signature} = 0xFFFF;
$w->{helpID} = 0;
$w->{exStyle} = 0x00000080;
$w->{style} = 0x00080000 | 0x0002 | 0x0001 | 0x40 | 0x00040000;   # WS.SYSMENU | CS.HREDRAW | CS.VREDRAW | DS.SETFONT | WS.SIZEBOX
$w->{cDlgItems} = 0;
$w->{x} = 0;
$w->{y} = 0;
$w->{cx} = 190;
$w->{cy} = 210;
$w->{menu} = 0;
$w->{windowClass} = 0;
$w->{title} = encode('UTF-16le',"MyDialogTitle");
$w->{pointsize} = 8;
$w->{weight} = 400;
$w->{italic} = 0;
$w->{charset} = 1;
$w->{typeface} = encode('UTF-16le', "MS Shell Dlg");
#print "original size: ", $w->sizeof, "\n";
$w->align('auto');
print $w->Dump(''), "\nsize: ", $w->sizeof, "\n";
#dd $w;

# WinDialog\__init__.py::line132 next is GetModuleHandle(None)
my $hMod = GetModuleHandleW("");        dd { hMod => $hMod };
