use strict;
use warnings;
use Win32::API;
use Win32::API::Callback;
use Encode qw(encode decode);
use Fcntl qw(:DEFAULT);

BEGIN { print STDERR "\n\n"; }
END   { print STDERR "\n\n"; }

# NOTE: This implementation targets 64-bit Windows Perl.
# For 32-bit, change pointer sizes/pack templates where noted.

# Constants
use constant {
    WS_OVERLAPPED       => 0x00000000,
    WS_OVERLAPPEDWINDOW => 0x00CF0000,  # https://learn.microsoft.com/en-us/windows/win32/winmsg/window-styles
    WS_POPUP            => 0x80000000,
    WS_CAPTION          => 0x00C00000,
    WS_SYSMENU          => 0x00080000,
    WS_VISIBLE          => 0x10000000,
    WS_CHILD            => 0x40000000,
    WS_TABSTOP          => 0x00010000,
    WS_EX_DLGMODALFRAME => 0x00000001,
    WS_EX_CLIENTEDGE    => 0x00000200,
    ES_LEFT             => 0x0000,
    ES_AUTOHSCROLL      => 0x0080,
    BS_DEFPUSHBUTTON    => 0x00000001,
    BS_PUSHBUTTON       => 0x00000000,
    SW_SHOW             => 5,
    EM_LIMITTEXT        => 0x00C5,
    IDOK                => 1,
    IDCANCEL            => 2,
};

# Win32 types packing for 64-bit
my $PTR = 'Q';   # pointer-sized unsigned (64-bit)
my $UINT = 'L';  # 32-bit unsigned
my $LONG = 'l';  # 32-bit signed
my $WORD = 'S';  # 16-bit
my $WCHAR = 'v'; # 16-bit wchar (for building wide strings)

# Helper: UTF-8 Perl string -> UTF-16LE null-terminated bytes
sub to_wide_bytes {
    my ($s) = @_;
    $s = '' unless defined $s;
    my $u16 = encode("UTF-16LE", $s);
    return $u16 . "\0\0";
}
# Helper: decode wide buffer
sub from_wide_bytes {
    my ($bytes) = @_;
    $bytes =~ s/\0+$//s;
    return decode("UTF-16LE", $bytes);
}

# Load APIs (wide variants where applicable)
my $GetModuleHandleW        = Win32::API->new('kernel32', 'GetModuleHandleW', 'P', 'N')             or die "GetModuleHandleW: $^E";
my $RegisterClassW          = Win32::API->new('user32', 'RegisterClassW', 'P', 'N')                 or die "RegisterClassW: $^E";
my $RegisterClassExW        = Win32::API->new('user32', 'RegisterClassExW', 'P', 'N')               or die "RegisterClassExW: $^E";
my $GetClassInfoW           = Win32::API->new('user32', 'GetClassInfoW', 'PPP', 'N')                or die "GetClassInfoW: $^E";
my $GetClassInfoW_NPP       = Win32::API->new('user32', 'GetClassInfoW', 'NPP', 'N')                or die "GetClassInfoW: $^E";
my $GetClassInfoW_atom      = Win32::API->new('user32', 'GetClassInfoW', 'NNP', 'N')                or die "GetClassInfoW: $^E";
my $CreateWindowExW         = Win32::API->new('user32', 'CreateWindowExW', 'NPPNNNNNNNNP', 'N')     or die "CreateWindowExW: $^E";
my $CreateWindowExW_atom    = Win32::API->new('user32', 'CreateWindowExW', 'NNPNNNNNNNNP', 'N')     or die "CreateWindowExW: $^E";
my $ShowWindow              = Win32::API->new('user32', 'ShowWindow', 'NN', 'N')                    or die "ShowWindow: $^E";
my $UpdateWindow            = Win32::API->new('user32', 'UpdateWindow', 'N', 'N')                   or die "UpdateWindow: $^E";
my $SetWindowPos            = Win32::API->new('user32', 'SetWindowPos', 'NNNNNNN', 'N')             or die "SetWindowPos: $^E";
my $GetSystemMetrics        = Win32::API->new('user32', 'GetSystemMetrics', 'N', 'N')               or die "GetSystemMetrics: $^E";
my $DefWindowProcW          = Win32::API->new('user32', 'DefWindowProcW', 'NNNN', 'N')              or die "DefWindowProcW: $^E";
my $DispatchMessageW        = Win32::API->new('user32', 'DispatchMessageW', 'P', 'N')               or die "DispatchMessageW: $^E";
my $TranslateMessage        = Win32::API->new('user32', 'TranslateMessage', 'P', 'N')               or die "TranslateMessage: $^E";
my $GetMessageW             = Win32::API->new('user32', 'GetMessageW', 'PNNN', 'N')                 or die "GetMessageW: $^E";
my $PostQuitMessage         = Win32::API->new('user32', 'PostQuitMessage', 'N', 'N')                or die "PostQuitMessage: $^E";
my $DestroyWindow           = Win32::API->new('user32', 'DestroyWindow', 'N', 'N')                  or die "DestroyWindow: $^E";
my $SendMessageW            = Win32::API->new('user32', 'SendMessageW', 'NNNN', 'N')                or die "SendMessageW: $^E";
my $GetWindowTextW          = Win32::API->new('user32', 'GetWindowTextW', 'NPN', 'N')               or die "GetWindowTextW: $^E";
my $SetWindowLongPtrW       = Win32::API->new('user32', 'SetWindowLongPtrW', 'NNN', 'N')            or die "SetWindowLongPtrW: $^E";
my $GetWindowLongPtrW       = Win32::API->new('user32', 'GetWindowLongPtrW', 'NN', 'N')             or die "GetWindowLongPtrW: $^E";
my $LoadCursorW             = Win32::API->new('user32', 'LoadCursorW', 'NP', 'N')                   or die "LoadCursorW: $^E";
my $GetLastError            = Win32::API->new('kernel32', 'GetLastError', '', 'I')                  or die "GetLastError: $^E";

sub WindowProc_fn
{
    my ($hwnd, $uMsg, $wParam, $lParam) = @_;
    printf STDERR "WindowProc_fn(0x%016lx, 0x%016lx, 0x%016lx, 0x%016lx)\n", $hwnd, $uMsg, $wParam, $lParam;
    return Win32::API::Call('user32', 'DefWindowProcW', $hwnd, $uMsg, $wParam, $lParam);
}
my $WindowProc_cb = Win32::API::Callback->new(\&WindowProc_fn, 'NNNN', 'N') or die "Unable to create WindowProc callback: $^E";

my $hInstance = $GetModuleHandleW->Call(0);
printf STDERR "hInstance = 0x%016lx\n", $hInstance;

## typedef struct tagWNDCLASSA {
##   UINT      style;
##   WNDPROC   lpfnWndProc;
##   int       cbClsExtra;
##   int       cbWndExtra;
##   HINSTANCE hInstance;
##   HICON     hIcon;
##   HCURSOR   hCursor;
##   HBRUSH    hbrBackground;
##   LPCSTR    lpszMenuName;
##   LPCSTR    lpszClassName;
## } WNDCLASSA, *PWNDCLASSA, *NPWNDCLASSA, *LPWNDCLASSA;

my $class_name = "PromptDialog";
my $class_name_w = to_wide_bytes($class_name); # pack('v*', unpack('C*', $class_name));
my $menu_name_w = to_wide_bytes("");
my $is_64bit = (length(pack('P', 0)) == 8) ? 1 : 0;


Win32::API::Struct->typedef( WNDCLASSW => qw{
   UINT      style;
   LPVOID    lpfnWndProc;
   int       cbClsExtra;
   int       cbWndExtra;
   HINSTANCE hInstance;
   HICON     hIcon;
   HCURSOR   hCursor;
   HBRUSH    hbrBackground;
   LPCSTR    lpszMenuName;
   LPCSTR    lpszClassName;
});
my $TryWC = Win32::API::Struct->new('WNDCLASSW');
$TryWC->{style} = 0;
$TryWC->{lpfnWndProc} = $WindowProc_cb;
$TryWC->{cbClsExtra} = 3;
$TryWC->{cbWndExtra} = 5;
$TryWC->{hInstance} = $hInstance;
$TryWC->{hIcon} = 0;
$TryWC->{hCursor} = 0x10003;
$TryWC->{hbrBackground} = 0x10;
$TryWC->{lpszMenuName} = $menu_name_w; #to_wide_bytes("MyMenuName");
$TryWC->{lpszClassName} = $class_name_w; #to_wide_bytes("MyClassName");
$TryWC->align(64);
$TryWC->Pack();
use Data::Dump; dd $TryWC; printf STDERR "struct buf      = %s\n", unpack("H*",$TryWC->{buffer}), "\n";

my $wc_packed = pack(
    ($is_64bit) ? 'I x4 Q i i Q Q Q Q P P' : 'I L i i L L L L P P',
    0,                          # style
    $WindowProc_cb,             # lpfnWndProc (callback pointer)
    3,                          # cbClsExtra
    5,                          # cbWndExtra
    $hInstance,                 # hInstance
    0,                          # hIcon
    0x10003,                    # hCursor       = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);    IDC_ARROW=32512=0x7F00
    0x10,                       # hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1) = 15+1 = 16 = 0x10
    $menu_name_w,               # lpszMenuName  ## Use Q/L if lpszMenuName==0, else use P
    $class_name_w               # lpszClassName (pointer to our string)
);
printf STDERR "wc_packed       = %s\n", unpack("H*", $wc_packed);
#              wc_packed       = 00000000c8e85a3e1402000000000000000000000000b465f67f000000000000000000000000000000000000000000000000000000000000000000007039583e14020000
printf STDERR "                  ^style_^^x4____^^_proc ptr_____^^cls xt^^wnd xt^^hInstance_____^^hIcon_________^^hCursor_______^^hBkgrnd_______^^lpszMenuName__^^class name ptr^\n";

my $atom = $RegisterClassW->Call($wc_packed);
die "RegisterClassW failed: $^E" unless $atom;
printf STDERR "RegisterClassW: atom=%d\n", $atom;

my $readback_w = "\x00"x72;
printf STDERR "readback before = %s\n", unpack("H*", $readback_w);
my $got = $GetClassInfoW->Call($hInstance, $class_name_w, $readback_w);
warn "GetClassInfoW failed: $got => $^E" unless $got;
printf STDERR "readback PPP    = %s => got:%s\n", unpack("H*", $readback_w), $got;

$got = $GetClassInfoW_atom->Call($hInstance, $atom, $readback_w);
warn "GetClassInfoW_atom failed: $got => $^E" unless $got;
printf STDERR "readback NNP    = %s => got:%s\n", unpack("H*", $readback_w), $got;


$readback_w = "\x00"x72;
$got = $GetClassInfoW_NPP->Call($hInstance, $class_name_w, $readback_w);
warn "GetClassInfoW_NPP failed: $got => $^E" unless $got;
printf STDERR "readback NPP    = %s => got:%s\n", unpack("H*", $readback_w), $got;

=begin comments

Packing of the structure: compare c vs perl

Perl Prints:
hInstance = 0x0000000065b40000
wc_packed = 0000000000000000003bfa429f02000003000000050000000000b465f67f000000000000000000000300010000000000100000000000000070d3f6429f02000040caf8429f020000
            ^style_^^x4____^^_proc ptr_____^^cls xt^^wnd xt^^hInstance_____^^hIcon_________^^hCursor_______^^hBkgrnd_______^^lpszMenuName__^^class name ptr^
c (below)   0000000000000000C117B033F77F000000000000000000000000B033F77F000000000000000000000300010000000000100000000000000000000000000000007251B033F77F0000

C Prints:
hInstance = 0x0000000033b00000
Address          | 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F |
-----------------|-------------------------------------------------|
00000052E3BFF600 | 00 00 00 00 00 00 00 00 C1 17 B0 33 F7 7F 00 00 |
00000052E3BFF610 | 00 00 00 00 00 00 00 00 00 00 B0 33 F7 7F 00 00 |
00000052E3BFF620 | 00 00 00 00 00 00 00 00 03 00 01 00 00 00 00 00 |
00000052E3BFF630 | 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 |
00000052E3BFF640 | 72 51 B0 33 F7 7F 00 00                         |

Google AI helped me figure out how to get the RegisterClassW packed and registered correctly without crashing
(see w32_register_class)

=cut

## CreateWindow: needs Class Name and Title as wchar_t* -- ie,
my $title_str = "PROMPT";
my $title_str_w = to_wide_bytes($title_str); #pack('v*', unpack('C*', $title_str));
printf STDERR "class_str=%-32s => packed_w='%s'\n", "'$class_name'", unpack("H*", $class_name_w);
printf STDERR "title_str=%-32s => packed_w='%s'\n", "'$title_str'", unpack("H*", $title_str_w);
    my $s_inp = '#32770';
    my $s_twb = to_wide_bytes($s_inp);
    my $s_pup = pack('v*', unpack('C*', $s_inp)) . "\0\0";
    printf STDERR "compare encodings: inp=%-32s => \n\ttwb='%s'\n\tpup='%s'\n", "'$s_inp'", unpack("H*", $s_twb), unpack("H*", $s_pup);

my $dlgW = 320;
my $dlgH = 150;


=begin comments

why can't it find the class name?
I tried the encoding experiment above, but even when I use the to_wide_bytes,
it still doesn't find it.

add in dumps from C:
hInstance = 0x00000000d0290000
Address          | 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F |
-----------------|-------------------------------------------------|
00000003005FFAE0 | 00 00 00 00 00 00 00 00 C1 17 29 D0 F7 7F 00 00 |
00000003005FFAF0 | 00 00 00 00 00 00 00 00 00 00 29 D0 F7 7F 00 00 |
00000003005FFB00 | 00 00 00 00 00 00 00 00 03 00 01 00 00 00 00 00 |
00000003005FFB10 | 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 |
00000003005FFB20 | 72 51 29 D0 F7 7F 00 00                         |
Address          | 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F |
-----------------|-------------------------------------------------|
00007FF7D0295172 | 50 00 72 00 6F 00 6D 00 70 00 74 00 44 00 69 00 |
00007FF7D0295182 | 61 00 6C 00 6F 00 67 00 00 00                   |
Address          | 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F |
-----------------|-------------------------------------------------|
00007FF7D029518C | 50 00 52 00 4F 00 4D 00 50 00 54 00 00 00       |
The text was, 'x'

and dumps from perl:
hInstance = 0x0000000065b40000
wc_packed = 0000000000000000a024a0aa9e02000003000000050000000000b465f67f0000000000000000000003000100000000001000000000000000000000000000000050528ea89e020000
            ^style_^^x4____^^_proc ptr_____^^cls xt^^wnd xt^^hInstance_____^^hIcon_________^^hCursor_______^^hBkgrnd_______^^lpszMenuName__^^class name ptr^
RegisterClassW: atom=49548
class_str='PromptDialog'                   => packed_w='500072006f006d00700074004400690061006c006f0067000000'
title_str='PROMPT'                         => packed_w='500052004f004d00500054000000'
compare encodings: inp='#32770'                         =>
        twb='2300330032003700370030000000'
        pup='2300330032003700370030000000'
Failed to create dialog: Cannot find window class at C:\usr\local\share\github\passThru\perl\w32prompt.pl line 178.

Maybe it's not encoding things properly (ie, wrong Win32::API type characters).  I wish I had a way to see what it was doing inside the Win32::API calls

============================

With the GetClassInfo, I was able to discover:
- using PPP gives the "cannot find window class"
- using NNP and passing in the atom correctly interprets things.
- I tried NPP and passing in the string,
  - it gives "Win32::API::Call: parameter 3 had a buffer overflow"
  - try giving it a longer buffer (150 bytes), and it gave
            0000000000000000709347c65c02000003000000050000000000f278f67f00000000000000000000030001000000000010000000000000000000000000000000508245c65c020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
            ^style_^^x4____^^_proc ptr_____^^cls xt^^wnd xt^^hInstance_____^^hIcon_________^^hCursor_______^^hBkgrnd_______^^lpszMenuName__^^class name ptr^

So, confirm that N should be used for hInstance, and N for atom or P for class_name_w
-- so change CreateWindowExW and CreateWindowExW_atom to use NN for the last two args (the hInstance and the LPVOID which I always pass as 0, so should be an N not a P)
    -> that caused either of those to crash
    -> so did NP for the last two. :-(

=cut

# Create the main dialog window
my $hwnd;
if(0) {
warn "here";
eval {
    $hwnd = $CreateWindowExW->Call(
        WS_EX_DLGMODALFRAME,
        to_wide_bytes("PromptDialog"), # $class_name_w, # to_wide_bytes("#32770"),
        $title_str_w,
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        0, 0, $dlgW, $dlgH,
        0, 0, $hInstance, 0
    );
    1;
} or do {
    warn "eval failed:\n\t!: $!\n\t@: $@\n\tE: $^E";
};
warn "here";
} elsif(0) {
$got = $GetClassInfoW_atom->Call($hInstance, $atom, $readback_w);
warn "GetClassInfoW_atom failed: $got => $^E" unless $got;
printf STDERR "readback NNP    = %s\n\t=> got vs atom:%s vs %s\n", unpack("H*", $readback_w), $got, $atom;
warn "here";
eval {
    $hwnd = $CreateWindowExW_atom->Call(
        WS_EX_DLGMODALFRAME,
        $atom,
        $title_str_w,
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        0, 0, $dlgW, $dlgH,
        0, 0, $hInstance, 0
    );
    1;
} or do {
    warn "eval failed:\n\t!: $!\n\t@: $@\n\tE: $^E";
};
warn "here";
}

warn "Failed to create dialog: $^E" unless $hwnd;
printf STDERR "hwnd=%032p\n", $hwnd;


#---------------
