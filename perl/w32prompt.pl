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
    WS_OVERLAPPEDWINDOW => 0x00CF0000,
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
my $GetModuleHandleW = Win32::API->new('kernel32', 'GetModuleHandleW', 'P', 'N')            or die "GetModuleHandleW: $^E";
my $RegisterClassW    = Win32::API->new('user32', 'RegisterClassW', 'P', 'N')              or die "RegisterClassExW: $^E";
my $CreateWindowExW   = Win32::API->new('user32', 'CreateWindowExW', 'NPPNNNNNNNPP', 'N')   or die "CreateWindowExW: $^E";
my $ShowWindow        = Win32::API->new('user32', 'ShowWindow', 'NN', 'N')                  or die "ShowWindow: $^E";
my $UpdateWindow      = Win32::API->new('user32', 'UpdateWindow', 'N', 'N')                 or die "UpdateWindow: $^E";
my $SetWindowPos      = Win32::API->new('user32', 'SetWindowPos', 'NNNNNNN', 'N')           or die "SetWindowPos: $^E";
my $GetSystemMetrics  = Win32::API->new('user32', 'GetSystemMetrics', 'N', 'N')             or die "GetSystemMetrics: $^E";
my $CreateWindowExW_ctrl = $CreateWindowExW; # reuse signature
my $DefWindowProcW    = Win32::API->new('user32', 'DefWindowProcW', 'NNNN', 'N')            or die "DefWindowProcW: $^E";
my $DispatchMessageW  = Win32::API->new('user32', 'DispatchMessageW', 'P', 'N')             or die "DispatchMessageW: $^E";
my $TranslateMessage  = Win32::API->new('user32', 'TranslateMessage', 'P', 'N')             or die "TranslateMessage: $^E";
my $GetMessageW       = Win32::API->new('user32', 'GetMessageW', 'PNNN', 'N')               or die "GetMessageW: $^E";
my $PostQuitMessage   = Win32::API->new('user32', 'PostQuitMessage', 'N', 'N')              or die "PostQuitMessage: $^E";
my $DestroyWindow     = Win32::API->new('user32', 'DestroyWindow', 'N', 'N')                or die "DestroyWindow: $^E";
my $SendMessageW      = Win32::API->new('user32', 'SendMessageW', 'NNNN', 'N')              or die "SendMessageW: $^E";
my $GetWindowTextW    = Win32::API->new('user32', 'GetWindowTextW', 'NPN', 'N')             or die "GetWindowTextW: $^E";
my $SetWindowLongPtrW = Win32::API->new('user32', 'SetWindowLongPtrW', 'NNN', 'N')          or die "SetWindowLongPtrW: $^E";
my $GetWindowLongPtrW = Win32::API->new('user32', 'GetWindowLongPtrW', 'NN', 'N')           or die "GetWindowLongPtrW: $^E";
my $LoadCursorW       = Win32::API->new('user32', 'LoadCursorW', 'NP', 'N')                 or die "LoadCursorW: $^E";
my $CreateWindowW   = sub { $CreateWindowExW->Call(0, @_); };
my $GetLastError     = Win32::API->new('kernel32', 'GetLastError', '', 'I')                 or die "GetLastError: $^E";

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

my $class_name = "MyPromptClass\0";
my $class_name_w = pack('v*', unpack('C*', $class_name));

my $is_64bit = (length(pack('P', 0)) == 8) ? 1 : 0;

my $wc_packed = pack(
    ($is_64bit) ? 'I x4 Q i i Q Q Q Q Q P' : 'I L i i L L L L L P',
    0,                          # style
    $WindowProc_cb,             # lpfnWndProc (callback pointer)
    3,                          # cbClsExtra
    5,                          # cbWndExtra
    $hInstance,                 # hInstance
    0,                          # hIcon
    0x10003,                    # hCursor       = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);    IDC_ARROW=32512=0x7F00
    0x10,                       # hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1) = 15+1 = 16 = 0x10
    0,                          # lpszMenuName  ## Use Q/L if lpszMenuName==0, else use P
    $class_name_w               # lpszClassName (pointer to our string)
);
printf STDERR "wc_packed = %s\n", unpack("H*", $wc_packed);
#              wc_packed = 00000000c8e85a3e1402000000000000000000000000b465f67f000000000000000000000000000000000000000000000000000000000000000000007039583e14020000
printf STDERR "            ^style_^^x4____^^_proc ptr_____^^cls xt^^wnd xt^^hInstance_____^^hIcon_________^^hCursor_______^^hBkgrnd_______^^lpszMenuName__^^class name ptr^";

my $atom = $RegisterClassW->Call($wc_packed);
die "RegisterClassW failed: $^E" unless $atom;
printf STDERR "RegisterClassW: atom=%d\n", $atom;

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

