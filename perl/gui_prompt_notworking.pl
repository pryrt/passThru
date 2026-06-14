use strict;
use warnings;
use Win32::API;
use Win32::API::Callback;
use Encode qw(encode decode);

# Constants
use constant {
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
    WM_COMMAND          => 0x0111,
    WM_CLOSE            => 0x0010,
    WM_DESTROY          => 0x0002,
};

# Win32 API calls
my $GetModuleHandleW  = Win32::API->new('kernel32', 'GetModuleHandleW', 'P', 'N') or die "GetModuleHandleW: $^E";
my $RegisterClassW    = Win32::API->new('user32', 'RegisterClassW', 'P', 'N') or die "RegisterClassW: $^E";
my $CreateWindowExW   = Win32::API->new('user32', 'CreateWindowExW', 'NPPNNNNNNNPP', 'N') or die "CreateWindowExW: $^E";
my $ShowWindow        = Win32::API->new('user32', 'ShowWindow', 'NN', 'N') or die "ShowWindow: $^E";
my $UpdateWindow      = Win32::API->new('user32', 'UpdateWindow', 'N', 'N') or die "UpdateWindow: $^E";
my $SetWindowPos      = Win32::API->new('user32', 'SetWindowPos', 'NNNNNNN', 'N') or die "SetWindowPos: $^E";
my $GetSystemMetrics  = Win32::API->new('user32', 'GetSystemMetrics', 'N', 'N') or die "GetSystemMetrics: $^E";
my $DefWindowProcW    = Win32::API->new('user32', 'DefWindowProcW', 'NNNN', 'N') or die "DefWindowProcW: $^E";
my $DispatchMessageW  = Win32::API->new('user32', 'DispatchMessageW', 'P', 'N') or die "DispatchMessageW: $^E";
my $TranslateMessage  = Win32::API->new('user32', 'TranslateMessage', 'P', 'N') or die "TranslateMessage: $^E";
my $GetMessageW       = Win32::API->new('user32', 'GetMessageW', 'PNNN', 'N') or die "GetMessageW: $^E";
my $DestroyWindow     = Win32::API->new('user32', 'DestroyWindow', 'N', 'N') or die "DestroyWindow: $^E";
my $SendMessageW      = Win32::API->new('user32', 'SendMessageW', 'NNNN', 'N') or die "SendMessageW: $^E";
my $GetWindowTextW    = Win32::API->new('user32', 'GetWindowTextW', 'NPN', 'N') or die "GetWindowTextW: $^E";
my $PostMessageW      = Win32::API->new('user32', 'PostMessageW', 'NNNN', 'N') or die "PostMessageW: $^E";

# Helper functions
sub to_wide_bytes {
    my ($s) = @_;
    return "\0\0" if !defined $s || $s eq '';
    return encode("UTF-16LE", $s) . "\0\0";
}

sub from_wide_bytes {
    my ($bytes) = @_;
    $bytes =~ s/\0+$//s;
    return decode("UTF-16LE", $bytes);
}

# Global state: dialog data by HWND
my %g_dialogs;
my $g_WindowProc_cb; # Keep callback alive

# This is the actual window procedure dispatcher
sub wndproc_dispatch {
    my ($hwnd, $uMsg, $wParam, $lParam) = @_;

    if ($uMsg == WM_COMMAND) {
        my $wParamLo = $wParam & 0xFFFF;  # Extract control ID from wParam

        if ($wParamLo == IDOK) {
            # Store IDOK result and close
            if (exists $g_dialogs{$hwnd}) {
                $g_dialogs{$hwnd}{result} = IDOK;
            }
            $PostMessageW->Call($hwnd, WM_CLOSE, 0, 0);
            return 0;
        }
        elsif ($wParamLo == IDCANCEL) {
            # Store IDCANCEL result and close
            if (exists $g_dialogs{$hwnd}) {
                $g_dialogs{$hwnd}{result} = IDCANCEL;
            }
            $PostMessageW->Call($hwnd, WM_CLOSE, 0, 0);
            return 0;
        }
    }
    elsif ($uMsg == WM_CLOSE) {
        $DestroyWindow->Call($hwnd);
        return 0;
    }
    elsif ($uMsg == WM_DESTROY) {
        # Clean up dialog state
        delete $g_dialogs{$hwnd};
        return 0;
    }

    # Default handling for all other messages
    return $DefWindowProcW->Call($hwnd, $uMsg, $wParam, $lParam);
}

# Register the custom window class (do this once)
my $g_class_registered = 0;

sub register_custom_class {
    return if $g_class_registered;

    my $hInstance = $GetModuleHandleW->Call(0);
    my $class_name = to_wide_bytes("PerlDialogClass");

    # Create the callback for window procedure
    my $wndproc_ref = sub {
        my ($hwnd, $uMsg, $wParam, $lParam) = @_;
        return wndproc_dispatch($hwnd, $uMsg, $wParam, $lParam);
    };

    $g_WindowProc_cb = Win32::API::Callback->new($wndproc_ref, 'NNNN', 'N')
        or die "Unable to create WindowProc callback: $^E";

    # Build WNDCLASSW structure (40 bytes on 64-bit)
    # Layout: style(L), lpfnWndProc(Q), cbClsExtra(l), cbWndExtra(l), hInstance(Q),
    #         hIcon(Q), hCursor(Q), hbrBackground(Q), lpszMenuName(Q), lpszClassName(Q)
    my $wnd_class = pack('L Q l l Q Q Q Q Q Q',
        0,                          # style
        $g_WindowProc_cb,           # lpfnWndProc (callback pointer)
        0,                          # cbClsExtra
        0,                          # cbWndExtra
        $hInstance,                 # hInstance
        0,                          # hIcon
        0,                          # hCursor
        0,                          # hbrBackground
        0,                          # lpszMenuName
        unpack('Q', pack('P', $class_name))  # lpszClassName (pointer to our string)
    );

    my $ret = $RegisterClassW->Call($wnd_class);
    die "RegisterClassW failed: $^E" unless $ret;

    $g_class_registered = 1;
}

# Main dialog function
sub guiPrompt {
    my ($title, $prompt) = @_;
    $title  ||= "Input";
    $prompt ||= "Enter value:";

    # Ensure class is registered
    register_custom_class();

    my $hInstance = $GetModuleHandleW->Call(0);
    my $title_w   = to_wide_bytes($title);
    my $class_w   = to_wide_bytes("PerlDialogClass");

    my $dlgW = 420;
    my $dlgH = 140;

    # Create the main dialog window
    my $hwnd = $CreateWindowExW->Call(
        WS_EX_DLGMODALFRAME,
        $class_w,
        $title_w,
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        0, 0, $dlgW, $dlgH,
        0, 0, $hInstance, 0
    );

    return undef unless $hwnd;

    # Initialize dialog state
    $g_dialogs{$hwnd} = {
        hwnd   => $hwnd,
        result => undef,
    };

    # Center dialog on screen
    my $screenW = $GetSystemMetrics->Call(0);
    my $screenH = $GetSystemMetrics->Call(1);
    my $x = int(($screenW - $dlgW) / 2);
    my $y = int(($screenH - $dlgH) / 2);
    $SetWindowPos->Call($hwnd, 0, $x, $y, $dlgW, $dlgH, 0);

    # Create label
    my $prompt_w = to_wide_bytes($prompt);
    my $hLabel = $CreateWindowExW->Call(
        0,
        to_wide_bytes("STATIC"),
        $prompt_w,
        WS_CHILD | WS_VISIBLE,
        12, 12, $dlgW - 24, 20,
        $hwnd, 0, $hInstance, 0
    );

    # Create text input
    my $EDIT_ID = 1001;
    my $hEdit = $CreateWindowExW->Call(
        WS_EX_CLIENTEDGE,
        to_wide_bytes("EDIT"),
        to_wide_bytes(""),
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | ES_LEFT | ES_AUTOHSCROLL,
        12, 36, $dlgW - 24, 24,
        $hwnd, $EDIT_ID, $hInstance, 0
    );
    $SendMessageW->Call($hEdit, EM_LIMITTEXT, 1024, 0);

    $g_dialogs{$hwnd}{hEdit} = $hEdit;

    # Create OK button
    my $btn_ok = $CreateWindowExW->Call(
        0,
        to_wide_bytes("BUTTON"),
        to_wide_bytes("OK"),
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_DEFPUSHBUTTON,
        $dlgW - 220, $dlgH - 60, 80, 24,
        $hwnd, IDOK, $hInstance, 0
    );

    # Create Cancel button
    my $btn_cancel = $CreateWindowExW->Call(
        0,
        to_wide_bytes("BUTTON"),
        to_wide_bytes("Cancel"),
        WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON,
        $dlgW - 120, $dlgH - 60, 80, 24,
        $hwnd, IDCANCEL, $hInstance, 0
    );

    $ShowWindow->Call($hwnd, SW_SHOW);
    $UpdateWindow->Call($hwnd);

    # Modal message loop
    while (1) {
        my $msg_buf = "\0" x 64;
        my $ret = $GetMessageW->Call($msg_buf, 0, 0, 0);

        # ret == 0 means WM_QUIT, ret == -1 means error
        last if $ret <= 0;

        # Process the message
        $TranslateMessage->Call($msg_buf);
        $DispatchMessageW->Call($msg_buf);

        # Check if this dialog has completed
        if (!exists $g_dialogs{$hwnd}) {
            # Dialog was destroyed
            last;
        }
    }

    # Get result
    my $result = $g_dialogs{$hwnd}{result} // IDCANCEL;
    my $text = undef;

    if ($result == IDOK && exists $g_dialogs{$hwnd}{hEdit}) {
        my $buflen = 2048;
        my $outbuf = "\0" x $buflen;
        $GetWindowTextW->Call($g_dialogs{$hwnd}{hEdit}, $outbuf, $buflen / 2);
        $text = from_wide_bytes($outbuf);
    }

    # Clean up
    delete $g_dialogs{$hwnd};

    return ($result == IDOK) ? $text : undef;
}

# Example usage
if (!caller) {
    my $res = guiPrompt("My Title", "Enter your name:");
    if (defined $res) {
        print "You entered: $res\n";
    } else {
        print "Cancelled\n";
    }
}

1;
