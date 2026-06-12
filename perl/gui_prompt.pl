use strict;
use warnings;
use Win32::API;
use Encode qw(encode decode);
use Fcntl qw(:DEFAULT);

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
my $GetModuleHandleW = Win32::API->new('kernel32', 'GetModuleHandleW', 'P', 'N')
    or die "GetModuleHandleW: $^E";
my $RegisterClassExW = Win32::API->new('user32', 'RegisterClassExW', 'P', 'N')
    or die "RegisterClassExW: $^E";
my $CreateWindowExW   = Win32::API->new('user32', 'CreateWindowExW', 'NPPNNNNNNNPP', 'N')
    or die "CreateWindowExW: $^E";
my $ShowWindow        = Win32::API->new('user32', 'ShowWindow', 'NN', 'N')
    or die "ShowWindow: $^E";
my $UpdateWindow      = Win32::API->new('user32', 'UpdateWindow', 'N', 'N')
    or die "UpdateWindow: $^E";
my $SetWindowPos      = Win32::API->new('user32', 'SetWindowPos', 'NNNNNNN', 'N')
    or die "SetWindowPos: $^E";
my $GetSystemMetrics  = Win32::API->new('user32', 'GetSystemMetrics', 'N', 'N')
    or die "GetSystemMetrics: $^E";
my $CreateWindowExW_ctrl = $CreateWindowExW; # reuse signature
my $DefWindowProcW    = Win32::API->new('user32', 'DefWindowProcW', 'NNNN', 'N')
    or die "DefWindowProcW: $^E";
my $DispatchMessageW  = Win32::API->new('user32', 'DispatchMessageW', 'P', 'N')
    or die "DispatchMessageW: $^E";
my $TranslateMessage  = Win32::API->new('user32', 'TranslateMessage', 'P', 'N')
    or die "TranslateMessage: $^E";
my $GetMessageW       = Win32::API->new('user32', 'GetMessageW', 'PNNN', 'N')
    or die "GetMessageW: $^E";
my $PostQuitMessage   = Win32::API->new('user32', 'PostQuitMessage', 'N', 'N')
    or die "PostQuitMessage: $^E";
my $DestroyWindow     = Win32::API->new('user32', 'DestroyWindow', 'N', 'N')
    or die "DestroyWindow: $^E";
my $SendMessageW      = Win32::API->new('user32', 'SendMessageW', 'NNNN', 'N')
    or die "SendMessageW: $^E";
my $GetWindowTextW    = Win32::API->new('user32', 'GetWindowTextW', 'NPN', 'N')
    or die "GetWindowTextW: $^E";
my $SetWindowLongPtrW = Win32::API->new('user32', 'SetWindowLongPtrW', 'NNN', 'N')
    or die "SetWindowLongPtrW: $^E";
my $GetWindowLongPtrW = Win32::API->new('user32', 'GetWindowLongPtrW', 'NN', 'N')
    or die "GetWindowLongPtrW: $^E";
my $LoadCursorW       = Win32::API->new('user32', 'LoadCursorW', 'NP', 'N')
    or die "LoadCursorW: $^E";
my $RegisterClassW    = Win32::API->new('user32', 'RegisterClassW', 'P', 'N') # fallback
    or die "RegisterClassW: $^E";

# CreateCallback: build a callback function pointer for WindowProc using Win32::API Callback
# Signature for WindowProc: LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM)
# Win32::API Callback package uses prototype 'NNNN' for four params returning N
my $WindowProc_cb; # store to keep it alive

sub register_temp_wndclass {
    my ($hInstance, $class_name_w) = @_;

    # Build WNDCLASSW structure for RegisterClassW (simpler than WNDCLASSEX)
    # WNDCLASSW layout (WIN32): UINT style; WNDPROC lpfnWndProc; int cbClsExtra; int cbWndExtra;
    # HINSTANCE hInstance; HICON hIcon; HCURSOR hCursor; HBRUSH hbrBackground; LPCWSTR lpszMenuName; LPCWSTR lpszClassName;
    # We'll pack as: style (L), lpfnWndProc (Q), cbClsExtra (l), cbWndExtra (l), hInstance (Q), hIcon (Q), hCursor (Q), hbrBackground (Q), lpszMenuName (Q), lpszClassName (Q)
    # Note: RegisterClassW expects pointer to WNDCLASSW; Win32::API will copy bytes.
    my $wndproc_ref = sub {
        my ($hwnd, $uMsg, $wParam, $lParam) = @_;
        # Call our Perl-level wndproc dispatcher
        return wndproc_dispatch($hwnd, $uMsg, $wParam, $lParam);
    };
    $WindowProc_cb = Win32::API::Callback->new($wndproc_ref, 'NNNN', 'N')
        or die "Unable to create WindowProc callback";

    # Prepare WNDCLASSW packed struct
    my $style = 0;
    my $lpfnWndProc = $WindowProc_cb->ptr;
    my $cbClsExtra = 0;
    my $cbWndExtra = 0;
    my $hIcon = 0;
    my $hCursor = $LoadCursorW->Call(0, to_wide_bytes(0x7F00)); # IDC_ARROW = MAKEINTRESOURCE(32512) but easier to pass 0x7F00? Might be inconsistent.
    # Better: use NULL cursor to let system default; set to 0.
    $hCursor = 0;
    my $hbrBackground = 0xFFFF0008; # COLOR_BTNFACE + 1 encoded as HBRUSH — this is hacky; set 0 instead.
    $hbrBackground = 0;
    my $lpszMenuName = 0;
    # class name pointer: create a permanent buffer
    my $class_name_buf = $class_name_w;
    # We must pass pointers for lpfnWndProc and strings; build binary struct:
    my $packed = pack($UINT . $PTR . 'l l ' . $PTR x 5,
        $style, $lpfnWndProc, $cbClsExtra, $cbWndExtra,
        $hInstance, $hIcon, $hCursor, $hbrBackground, $lpszMenuName, 0);
    # But RegisterClassW expects last field lpszClassName pointer; Win32::API can't reference our Perl buffer directly.
    # Simpler approach: call RegisterClassW via RegisterClassW with a pointer to memory is fragile in Perl.
    # Instead, try RegisterClassW variant requiring only class name registration via existing class names.
    # To avoid this complexity, attempt using pre-existing system dialog class "#32770".
    return 1; # indicate we will use system dialog class
}

# lexical closure
my %dialog_state;


# Primary function: guiPrompt(title, prompt) -> returns Perl string or undef
sub guiPrompt {
    my ($title, $prompt) = @_;
    $title ||= "Input";
    $prompt ||= "Enter value:";

    my $hInstance = $GetModuleHandleW->Call(0);
    # Use standard dialog class "#32770" to avoid registering our own class
    my $class_name = to_wide_bytes("#32770");
    my $title_w = to_wide_bytes($title);

    my $dlgW = 420;
    my $dlgH = 140;

    my $hwnd = $CreateWindowExW->Call(
        WS_EX_DLGMODALFRAME,
        $class_name,
        $title_w,
        WS_POPUP | WS_CAPTION | WS_SYSMENU,
        0, 0, $dlgW, $dlgH,
        0, 0, $hInstance, 0
    );
    return undef unless $hwnd;

    # center
    my $screenW = $GetSystemMetrics->Call(0);
    my $screenH = $GetSystemMetrics->Call(1);
    my $x = int(($screenW - $dlgW) / 2);
    my $y = int(($screenH - $dlgH) / 2);
    $SetWindowPos->Call($hwnd, 0, $x, $y, $dlgW, $dlgH, 0);

    # Create controls
    my $prompt_w = to_wide_bytes($prompt);
    my $hLabel = $CreateWindowExW_ctrl->Call(
        0,
        to_wide_bytes("STATIC"),
        $prompt_w,
        WS_CHILD | WS_VISIBLE,
        12, 12, $dlgW - 24, 20,
        $hwnd, 0, $hInstance, 0
    );

    my $EDIT_ID = 1001;
    my $hEdit = $CreateWindowExW_ctrl->Call(
        WS_EX_CLIENTEDGE,
        to_wide_bytes("EDIT"),
        to_wide_bytes(""),
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | ES_LEFT | ES_AUTOHSCROLL,
        12, 36, $dlgW - 24, 24,
        $hwnd, $EDIT_ID, $hInstance, 0
    );
    $SendMessageW->Call($hEdit, EM_LIMITTEXT, 1024, 0);

    my $btn_ok = $CreateWindowExW_ctrl->Call(
        0,
        to_wide_bytes("BUTTON"),
        to_wide_bytes("OK"),
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_DEFPUSHBUTTON,
        $dlgW - 220, $dlgH - 60, 80, 24,
        $hwnd, IDOK, $hInstance, 0
    );
    my $btn_cancel = $CreateWindowExW_ctrl->Call(
        0,
        to_wide_bytes("BUTTON"),
        to_wide_bytes("Cancel"),
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON,
        $dlgW - 120, $dlgH - 60, 80, 24,
        $hwnd, IDCANCEL, $hInstance, 0
    );

    # Store state in a lexical closure accessible to wndproc_dispatch
    $dialog_state{ $hwnd } = {
        hwnd => $hwnd,
        hEdit => $hEdit,
        result => undef,
    };

    $ShowWindow->Call($hwnd, SW_SHOW);
    $UpdateWindow->Call($hwnd);

    # Modal loop
    my $msg_pack = 'LLLLLLLL'; # placeholder for MSG struct; Win32::API handles internally when calling GetMessageW
    while (1) {
        my $ret = $GetMessageW->Call( my $msgbuf = "\0" x 64, 0, 0, 0 );
        last if $ret == 0; # WM_QUIT
        last if $ret == -1;
        $TranslateMessage->Call($msgbuf);
        $DispatchMessageW->Call($msgbuf);

        # Check if dialog ended
        my $st = $dialog_state{ $hwnd } or last;
        if (defined $st->{result}) {
            last;
        }
    }

    my $res = $dialog_state{ $hwnd }{result};
    # cleanup
    delete $dialog_state{ $hwnd };
    if ($res && $res == IDOK) {
        # get text
        my $buflen = 2048; # bytes
        my $outbuf = "\0" x $buflen;
        $GetWindowTextW->Call($hEdit, $outbuf, $buflen/2);
        my $perlstr = from_wide_bytes($outbuf);
        # destroy window
        $DestroyWindow->Call($hwnd);
        return $perlstr;
    } else {
        $DestroyWindow->Call($hwnd);
        return undef;
    }
}

# Dispatcher used by the WindowProc callback (a minimal implementation).
# Handles WM_COMMAND for IDOK/IDCANCEL, WM_CLOSE, WM_DESTROY.
use constant {
    WM_COMMAND => 0x0111,
    WM_DESTROY => 0x0002,
    WM_CLOSE   => 0x0010,
};

sub wndproc_dispatch {
    my ($hwnd, $uMsg, $wParam, $lParam) = @_;
    my $loword = $wParam & 0xFFFF;
    if ($uMsg == WM_COMMAND) {
        if ($loword == IDOK || $loword == IDCANCEL) {
            my $st = $dialog_state{ $hwnd };
            if ($st) {
                $st->{result} = $loword;
            }
            # Post quit message to break modal loop
            $PostQuitMessage->Call(0);
            return 0;
        }
    } elsif ($uMsg == WM_CLOSE) {
        my $st = $dialog_state{ $hwnd };
        $st->{result} = IDCANCEL if $st;
        $PostQuitMessage->Call(0);
        return 0;
    } elsif ($uMsg == WM_DESTROY) {
        $PostQuitMessage->Call(0);
        return 0;
    }
    # call default
    return $DefWindowProcW->Call($hwnd, $uMsg, $wParam, $lParam);
}

# Example usage:
if (!caller) {
    my $res = guiPrompt("My Title", "Enter your name:");
    if (defined $res) {
        print "You entered: $res\n";
    } else {
        print "Cancelled\n";
    }
}
