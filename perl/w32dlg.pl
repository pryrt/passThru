#!/usr/bin/perl
use 5.012;
use warnings;
use Win32::API;
use Encode;
use Data::Dump;
use Win32::GuiTest();

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

    # my structure
    #Win32::API::Struct->typedef( 'MYSTRUCT' => qw/unsigned char bytes[$lb];/);
    Win32::API::Struct->typedef( 'MYSTRUCT' => qw(
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
    WCHAR     title[32];
    WORD      pointsize;
    WORD      weight;
    BYTE      italic;
    BYTE      charset;
    WCHAR     typeface[32];
    ));

    # https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-dialogboxindirectparamw
    Win32::API::->Import("user32", <<ENDPROTO) or die "Import DialogBoxIndirectParam FAILED: $^E";
INT_PTR DialogBoxIndirectParamW(
    HINSTANCE       hInstance,
    LPMYSTRUCT      hDialogTemplate,
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
if(0) {
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
dd active_hWnd => Win32::GuiTest::GetActiveWindow(0);
dd fg_hWnd =>  my $hWndParent = Win32::GuiTest::GetForegroundWindow();
my $hMod = GetModuleHandleW("");        dd { hMod => $hMod };
my $__default_dialog_proc;

=begin exception

dd [retval => DialogBoxIndirectParamW($hMod, $w, $hWndParent, $__default_dialog_proc, 0)];

# unforunately, DialogBoxIndirectParamW() always seems to cause perl to crash with Exception Code c0000005

        Faulting application name: perl.exe, version: 5.30.0.1, time stamp: 0x5ce675b5
        Faulting module name: USER32.dll, version: 10.0.22621.1485, time stamp: 0x394fb7c7
        Exception code: 0xc0000005
        Fault offset: 0x000000000001edb9
        Faulting process id: 0x0x3694
        Faulting application start time: 0x0x1D97A2721A37743
        Faulting application path: c:\usr\local\apps\berrybrew\perls\system\perl\bin\perl.exe
        Faulting module path: C:\WINDOWS\System32\USER32.dll
        Report Id: 1bfbafbe-aeeb-4228-908a-c1903aefb8d5
        Faulting package full name:
        Faulting package-relative application ID:

My best bet as to what's going on is that I don't have a dialog proc, so it crashes because of that.

=cut
}

=begin URLs

https://stackoverflow.com/questions/2270196/c-win32api-creating-a-dialog-box-without-resource => possible C example of manual dialog

Using that example, in manualDialog.c, I was able to get the following bytes to run,
even though I modified it to run with NUL instead of Debug_DlgProc

0       \xC4\x00\xC8\x90\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x2C\x01
16      \xB4\x00\x00\x00\x00\x00\x44\x00\x65\x00\x62\x00\x75\x00\x67\x00
32      \x00\x00\x08\x00\x4D\x00\x53\x00\x20\x00\x53\x00\x61\x00\x6E\x00
48      \x73\x00\x20\x00\x53\x00\x65\x00\x72\x00\x69\x00\x66\x00\x00\x00
64      \x01\x00\x03\x50\x04\x00\x00\x00\xBE\x00\xA0\x00\x32\x00\x0E\x00
80      \x01\x00\xFF\xFF\x80\x00\x26\x00\x41\x00\x70\x00\x70\x00\x6C\x00
96      \x79\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x50\x04\x00\x00\x00
112     \xF4\x00\xA0\x00\x32\x00\x0E\x00\x02\x00\xFF\xFF\x80\x00\x26\x00
128     \x43\x00\x61\x00\x6E\x00\x63\x00\x65\x00\x6C\x00\x00\x00\x00\x00
144     \x00\x00\x02\x50\x04\x00\x00\x00\x06\x00\x06\x00\x20\x01\x08\x00
160     \x63\x00\xFF\xFF\x82\x00\x00\x00\x00\x00\x00\x00

So that means it _doesn't_ need a process (though it's not usable without)...
which means the problem is the way I pass the structure.  I need to somehow
get the call with that structure to give a pointer to the memory for the structure

=cut
# try a "structure" that's really just an array of bytes:
my $bytes = "\xC4\x00\xC8\x90\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x2C\x01"
        .   "\xB4\x00\x00\x00\x00\x00\x44\x00\x65\x00\x62\x00\x75\x00\x67\x00"
        .   "\x00\x00\x08\x00\x4D\x00\x53\x00\x20\x00\x53\x00\x61\x00\x6E\x00"
        .   "\x73\x00\x20\x00\x53\x00\x65\x00\x72\x00\x69\x00\x66\x00\x00\x00"
        .   "\x01\x00\x03\x50\x04\x00\x00\x00\xBE\x00\xA0\x00\x32\x00\x0E\x00"
        .   "\x01\x00\xFF\xFF\x80\x00\x26\x00\x41\x00\x70\x00\x70\x00\x6C\x00"
        .   "\x79\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x50\x04\x00\x00\x00"
        .   "\xF4\x00\xA0\x00\x32\x00\x0E\x00\x02\x00\xFF\xFF\x80\x00\x26\x00"
        .   "\x43\x00\x61\x00\x6E\x00\x63\x00\x65\x00\x6C\x00\x00\x00\x00\x00"
        .   "\x00\x00\x02\x50\x04\x00\x00\x00\x06\x00\x06\x00\x20\x01\x08\x00"
        .   "\x63\x00\xFF\xFF\x82\x00\x00\x00\x00\x00\x00\x00";
my $lb = length($bytes);

# Win32::API::Struct->typedef( 'DLGTEMPLATEEX' => qw/unsigned char bytes[$lb];/);
my $w = Win32::API::Struct->new('MYSTRUCT');
#$w->{bytes} = $bytes;
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
print "original size: ", $w->sizeof, "\n";
$w->align('auto');
print "aligned size: ", $w->sizeof, "\n";
$w->Dump('');


dd [retval => DialogBoxIndirectParamW(0, $w, 0, 0, 0)]; # okay, having the MYSTRUCT/LPMYSTRUCT pair has changed things...
#### Argument "M-D\0M-HM-^P\0\0\0\0^C\0\0\0\0\0,^AM-4\0\0\0\0\0D\0e\0b\0..." isn't numeric in pack at c:/usr/local/apps/strawberry/perl/vendor/lib/Win32/API/Struct.pm line 347.
#### Invalid type '$' in pack at c:/usr/local/apps/strawberry/perl/vendor/lib/Win32/API/Struct.pm line 347.

printf "GetModuleHandle(%s)=0x%X ('%s')\n", $_, GetModuleHandleW($_), $^E for 0, qw/NULL NUL perl.exe user32.dll user32 conhost.exe conhost/;
#sleep(60);
=begin

I think the problem is I used LPSTR above,
but I am passing it a DLGTEMPLATEEX.  I
should try calling it LPDLGTEMPLATEEX in the
prototype, and see if that fixes it -- because
the examples all show it working with LPX in
proto and X as the defined structure.

=cut
