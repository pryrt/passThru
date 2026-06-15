use strict;
use warnings;
use Win32::API;
use Win32::API::Callback;

# 1. Bind Necessary Core Windows APIs
my $RegisterClassW   = Win32::API->new('user32', 'RegisterClassW', 'P', 'N');
my $GetModuleHandleW = Win32::API->new('kernel32', 'GetModuleHandleW', 'P', 'N'); # 'J' handles 32/64-bit pointer sizing natively
my $GetLastError     = Win32::API->new('kernel32', 'GetLastError', '', 'N');

unless ($RegisterClassW && $GetModuleHandleW) {
    die "Fatal: Failed to map core Windows API endpoints: $^E\n";
}

# 2. Get the actual Module Handle (Crucial for avoiding Error 87)
my $h_instance = $GetModuleHandleW->Call(0);

# 3. Create the Window Callback Loop
my $wnd_proc = Win32::API::Callback->new(
    sub {
        my ($hwnd, $msg, $wparam, $lparam) = @_;
        return Win32::API::Call('user32', 'DefWindowProcW', $hwnd, $msg, $wparam, $lparam);
    },
    'NNNN', 'N' # Universal native pointer integers
);

# Crucial: Extract the actual native memory address pointer from the callback object
my $wnd_proc_address = $wnd_proc->{_code};

# 4. UTF-16LE Encode the Class Name String
my $class_name = "MyPerlClass\0";
my $class_name_w = pack('v*', unpack('C*', $class_name));

# 5. Architecture-Aware Structural Packaging (WNDCLASSW)
my $wndclass_struct;
my $is_64bit = (length(pack('P', 0)) == 8) ? 1 : 0;

if ($is_64bit) {
    # 64-bit WNDCLASSW alignment (Requires explicit padding alignment after 4-byte style)
    # Layout: UINT style (4), 4-byte pad, WNDPROC (8), int (4), int (4), HINSTANCE (8), HICON (8), HCURSOR (8), HBRUSH (8), LPCWSTR (8), LPCWSTR (8)
    $wndclass_struct = pack(
        'I x4 Q i i Q Q Q Q P P',
        3,                 # style (CS_HREDRAW | CS_VREDRAW)
        $wnd_proc,         # Raw function pointer address
        0,                 # cbClsExtra
        0,                 # cbWndExtra
        $h_instance,       # Active hInstance handle
        0,                 # hIcon
        0,                 # hCursor
        0,                 # hbrBackground
        0,                 # lpszMenuName
        $class_name_w      # lpszClassName pointer
    );
} else {
    # 32-bit WNDCLASSW alignment
    # Layout: UINT (4), WNDPROC (4), int (4), int (4), HINSTANCE (4), HICON (4), HCURSOR (4), HBRUSH (4), LPCWSTR (4), LPCWSTR (4)
    $wndclass_struct = pack(
        'I L i i L L L L P P',
        3,                 # style
        $wnd_proc,         # Raw function pointer address
        0, 0,
        $h_instance,       # Active hInstance handle
        0, 0, 0,
        0,
        $class_name_w
    );
}
printf STDERR "wc_packed = %s\n", unpack("H*", $wndclass_struct);
printf STDERR "            ^style_^^x4____^^_proc ptr_____^^cls xt^^wnd xt^^hInstance_____^^hIcon_________^^hCursor_______^^hBkgrnd_______^^lpszMenuName__^^class name ptr^";

# 6. Fire the API
my $atom = $RegisterClassW->Call($wndclass_struct);

if (defined($atom) && $atom != 0) {
    print "Success! Registered Window Class Atom: $atom\n";
} else {
    my $err = $GetLastError->Call();
    print "RegisterClassW failed completely. Windows API Error Code: $err\n";
    if ($err == 87) {
        print "Debugging note: Ensure Perl runtime architecture perfectly aligns with library structures.\n";
    }
}
