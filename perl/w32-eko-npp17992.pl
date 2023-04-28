#!perl
# https://community.notepad-plus-plus.org/topic/17992/how-to-get-the-scintilla-view0-view1-hwnds/29

use 5.012; # strict, //
use warnings;

use Win32::API;
use Win32::API::Callback;
use Encode;

# HWND FindWindowExW(
  # HWND    hWndParent,
  # HWND    hWndChildAfter,
  # LPCWSTR lpszClass,
  # LPCWSTR lpszWindow
# );

my $FindWindow = new Win32::API::More('User32', 'FindWindowExW', 'qqPP', 'q');
if(not defined $FindWindow) {
    die "Can't import API FindWindowExW: $^E\n";
}

# LRESULT SendMessageW(
  # HWND   hWnd,
  # UINT   Msg,
  # WPARAM wParam,
  # LPARAM lParam
# );

my $SendMessage = new Win32::API::More('User32', 'SendMessageW', 'qIQq', 'q');
if(not defined $SendMessage) {
    die "Can't import API SendMessageW: $^E\n";
}

# BOOL EnumChildWindows(
  # HWND        hWndParent,
  # WNDENUMPROC lpEnumFunc,
  # LPARAM      lParam
# );
my $EnumChildWindows = new Win32::API::More('User32', 'EnumChildWindows', 'qKq', 'I');
if(not defined $EnumChildWindows) {
    die "Can't import API EnumChildWindows: $^E\n";
}

# int GetClassNameW(
  # HWND   hWnd,
  # LPWSTR lpClassName,
  # int    nMaxCount
# );
my $GetClassName = new Win32::API::More('User32', 'GetClassNameW', 'qPI', 'I');
if(not defined $GetClassName) {
    die "Can't import API GetClassNameW: $^E\n";
}

# HWND GetParent(
  # HWND hWnd
# );
my $GetParent = new Win32::API::More('User32', 'GetParent', 'q', 'q');
if(not defined $GetParent) {
    die "Can't import API GetParent: $^E\n";
}


my $npp_hwnd = $FindWindow->Call(0, 0, encode('UTF-16le',"Notepad++"), 0);
print "npp_hwnd: $npp_hwnd\n";

# my $sci1_hwnd = $FindWindow->Call($npp_hwnd, 0, encode('UTF-16le',"Scintilla"), 0);
# print "sci1_hwnd: $sci1_hwnd\n";
my %scintilla_hwnd = (0, 0, 1, 0);
my $callback = Win32::API::Callback->new(
	sub {
		my($hwnd, $lParam) = @_;
		my $curr_class    = " " x 1024;
		my $result = $GetClassName->Call($hwnd, $curr_class, 1024);

		if (substr(decode('UTF-16le',$curr_class), 0, $result) eq 'Scintilla') {
            if ($GetParent->Call($hwnd) == $npp_hwnd) {
                if ($scintilla_hwnd{0} == 0) {
                    $scintilla_hwnd{0} = $hwnd;
				} elsif ($scintilla_hwnd{1} == 0) {
                    $scintilla_hwnd{1} = $hwnd;
                    return 0;
				}
			}
		}
        return 1;
	}, "qq", "I",
);

$EnumChildWindows->Call($npp_hwnd, $callback, 0);
print "first scintilla hwnd $scintilla_hwnd{0}\n";
print "second scintilla hwnd $scintilla_hwnd{1}\n";
