#!perl

use 5.014; # strict, //, s///r
use warnings;
$|=1;

#use Inline C => Config => CLEAN_AFTER_BUILD => 0;   # uncomment to keep the compiled version
use Inline C => 'DATA';
# hw();
print wrapped("Hello, World"), "\n";
noret("Hello, World");
#noarg();
print  "sizes       => ", sizes(5), "\n";
print  "list        => (", join(';', retlist(2)), ")\n";
printf "lret        => 0x%016X\n", lret(undef);
printf "lretiv      => 0x%016X\n", lreturn_iv(undef);
printf "noarg_lret  => 0x%016X\n", noarg_lret();

sub noarg_lret { lreturn_iv(@_ ? @_ : undef); }
sub myDialog { c_myDialog(@_?@_:0) }
sub myPrompt($$;$) { $_[2] //= ''; _c_prompt(@_) }

my $r = myPrompt("prompt", "title", "default");
printf "result in perl: %s\n", $r//'<undef>';

__DATA__

__C__

void hw(void) {
    printf("Hello, World\n");
    fflush(stdout);
}

SV* wrapped(char* msg) {
    char ch_out[256] = "Fake Out";
    size_t len;
    len = strlen(msg);
    return(newSVpvf("%s", ch_out));
}

void noret(char* msg) {
    printf("%s\n", msg);
    fflush(stdout);
    return;
}

void noarg(void) {
    printf("%s\n", "My Message");
    fflush(stdout);
    return;
}

#define print_sizeof(x) printf("sizeof(%s) = %d\n", #x, sizeof(x))
int sizes(int input) {
    printf("sizeof(%s) = %d\n", "int", sizeof(int));
    print_sizeof(int);
    print_sizeof(long);
    print_sizeof(long long);
    print_sizeof(LRESULT);
    print_sizeof(HWND);
    print_sizeof(IV);
    print_sizeof(SV);
    // https://learn.microsoft.com/en-us/cpp/cpp/char-wchar-t-char16-t-char32-t?view=msvc-170
    //  comparing sizes and notations for char, wchar_t, char16_t, and char32_t
    //
    print_sizeof(char);
    print_sizeof('a');
    print_sizeof(wchar_t);      // native "wide": for MS, it's 16bit (2byte) UTF16-LE (Windows internal native type)
    print_sizeof(L'a');         // the L prefix to a character or string makes it wchar_t
    print_sizeof(u'a');         // the u prefix makes it char16_t
    print_sizeof(U'a');         // the U prefix makes it char32_t
    //                          // wchar_t, char16_t, and char32_t are all "wide strings", though some people use "wide string" only for wchar_t
    //                          // char and char8_t are "narrow strings", even if they are used for storing utf8 sequences
    fflush(stdout);
    return(0);
}

void retlist(int qty) {
    SV* mysvp;
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    mysvp = newSViv(314);
    for(int i=0; i<qty; i++)
        Inline_Stack_Push(mysvp);
    Inline_Stack_Push(newSViv(qty));
    mysvp = newSVnv(2.718281828);
    Inline_Stack_Push(mysvp);
    mysvp = newSVpvf("printf[%d]", qty);
    Inline_Stack_Push(mysvp);
    LRESULT lr = -555;
    mysvp = newSVuv(lr);
    Inline_Stack_Push(mysvp);
    Inline_Stack_Done;
}

SV* lret(SV* ignore) {
    LRESULT lr = 0xdeadbeef;
    return(newSVuv(lr));
}

IV lreturn_iv(SV* ignore) {
    LRESULT lr = 0x123456789abcdef0;
    return((IV)lr);
}

// https://app.assembla.com/spaces/pryrt/subversion/source/HEAD/trunk/c_cpp/misc/manualDialog.c
// => https://stackoverflow.com/questions/2270196/c-win32api-creating-a-dialog-box-without-resource

#define DLGTITLE  L"Debug"
#define DLGFONT   L"MS Sans Serif"
#define DLGOK     L"&OK"
#define DLGCANCEL L"&Cancel"
#define DLGBMPLBL L"Bitmap Label"
#define NUMCHARS(aa) (sizeof(aa)/sizeof((aa)[0]))
#define IDC_LABEL 99

#pragma pack(push, 4)

static struct { // dltt

    DWORD  style;
    DWORD  dwExtendedStyle;
    WORD   ccontrols;
    short  x;
    short  y;
    short  cx;
    short  cy;
    WORD   menu;         // name or ordinal of a menu resource
    WORD   windowClass;  // name or ordinal of a window class
    WCHAR  wszTitle[NUMCHARS(DLGTITLE)]; // title string of the dialog box
    short  pointsize;       // only if DS_SETFONT flag is set
    WCHAR  wszFont[NUMCHARS(DLGFONT)];   // typeface name, if DS_SETFONT is set

    // control info
    // OK
    struct {
       DWORD  style;
       DWORD  exStyle;
       short  x;
       short  y;
       short  cx;
       short  cy;
       WORD   id;
       WORD   sysClass;       // 0xFFFF identifies a system window class
       WORD   idClass;        // ordinal of a system window class
       WCHAR  wszTitle[NUMCHARS(DLGOK)];
       WORD   cbCreationData; // bytes of following creation data
//       WORD   wAlign;         // align next control to DWORD boundry.
    } apply;

    // CANCEL
    struct {
       DWORD  style;
       DWORD  exStyle;
       short  x;
       short  y;
       short  cx;
       short  cy;
       WORD   id;
       WORD   sysClass;       // 0xFFFF identifies a system window class
       WORD   idClass;        // ordinal of a system window class
       WCHAR  wszTitle[NUMCHARS(DLGCANCEL)];
       WORD   cbCreationData; // bytes of following creation data
    } cancel;

    // BITMAP
    struct {
       DWORD  style;
       DWORD  exStyle;
       short  x;
       short  y;
       short  cx;
       short  cy;
       WORD   id;
       WORD   sysClass;       // 0xFFFF identifies a system window class
       WORD   idClass;        // ordinal of a system window class
       WCHAR  wszTitle[NUMCHARS(DLGBMPLBL)];    // title string or ordinal of a resource
       WORD   cbCreationData; // bytes of following creation data
    } bitmap;

   } g_DebugDlgTemplate = {

   WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU  // style  0x94c800c4
   | DS_MODALFRAME | DS_3DLOOK
   | DS_SETFONT,
   0x0,        // exStyle;
   3,          // ccontrols
   0, 0, 300, 180,
   0,                       // menu: none
   0,                       // window class: none
   DLGTITLE,                // Window caption
   8,                       // font pointsize
   DLGFONT,

      {
      WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_GROUP | BS_DEFPUSHBUTTON,   // 0x50030001
      WS_EX_NOPARENTNOTIFY, // 0x4
      190,160,50,14,
      IDOK,
      0xFFFF, 0x0080, // button
      DLGOK, 0,
      },

      {
      WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON,    // 0x50010000
      WS_EX_NOPARENTNOTIFY, // 0x4
      244,160,50,14,
      IDCANCEL,
      0xFFFF, 0x0080, // button
      DLGCANCEL, 0,
      },

      {
      WS_CHILD | WS_VISIBLE | WS_GROUP | SS_LEFT,    // 0x50020000
      WS_EX_NOPARENTNOTIFY, // 0x4
      6,6,288,26,
      IDC_LABEL,
      0xFFFF, 0x0082, // static
      DLGBMPLBL, 0,
      },
   };

    // https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-dlgitemtemplate =>
    //  => shows the 0x0080 = BUTTON, 0x0081 = EDIT (textbox?), 0x0082 = STATIC (label, including bitmap),
    //      0x0083 = LIST BOX, 0x0084 = SCROLL BAR, 0x0085 = COMBOBOX

#pragma pack(pop)

INT_PTR CALLBACK Debug_DlgProc (
    HWND   hwnd,
    UINT   uMsg,
    WPARAM wParam,
    LPARAM lParam)
{
    switch (uMsg)
       {
       case WM_INITDIALOG:
           {
               onInitDlg(hwnd);
           }
           break;

       case WM_COMMAND:
           {
           UINT wId = LOWORD(wParam);
           if (wId == IDOK || wId == IDCANCEL)
              {
              EndDialog (hwnd, wId);
              }
           }
           break;

       case WM_CLOSE:
           EndDialog(hwnd, IDCANCEL);
           break;
       }

    return FALSE;
}

void printf_bytes(LPVOID ptr, size_t sz)
{
    char* cp = (char*)ptr;
    for(size_t i=0; i<sz; i++) {
        if(0==i%16) printf("%-8d", i);
        printf("\\x%02X", cp[i]&0xFF);
        if(15==i%16) printf("\n");
    }
    printf("\n");fflush(stdout);
}

LRESULT DoDebugDialog(HWND hwndApp, LPVOID pvData)
{
   HINSTANCE hinst = hwndApp ? (HINSTANCE)(LONG_PTR)GetWindowLongPtr(hwndApp, GWLP_HINSTANCE)
                             : (HINSTANCE)GetModuleHandle(NULL);

   printf_bytes(&g_DebugDlgTemplate, sizeof(g_DebugDlgTemplate));
   printf("DialogBoxIndirectParamW(0x%X, %p, 0x%X, %p, 0x%X)\n", hinst, &g_DebugDlgTemplate, hwndApp, /*NULL*/Debug_DlgProc, (LPARAM)pvData);
   printf("%s\nHit ^C to exit...", "\x20\x21\x22");fflush(stdout);

   return DialogBoxIndirectParamW (hinst, (LPCDLGTEMPLATEW)&g_DebugDlgTemplate, hwndApp, Debug_DlgProc, (LPARAM)pvData);
}

IV c_myDialog(UV hwndApp)
{
    LRESULT r = DoDebugDialog((HWND)hwndApp, NULL);
    printf("result = %d\n", r);fflush(stdout);
    return((IV)r);
}

char* gs_dlgPrompt;
char* gs_dlgTitle;
char* gs_dlgDefault;

void onInitDlg(HWND hwnd) {
    SetWindowTextA(hwnd, gs_dlgTitle);
    SetDlgItemTextA(hwnd, IDC_LABEL, gs_dlgPrompt);
}

void _c_prompt(char* str_prompt, char* str_title, char* str_default)
{
    printf("prompt='%s', title='%s', default='%s'\n", str_prompt, str_title, str_default);
    gs_dlgPrompt = str_prompt;
    gs_dlgTitle = str_title;
    gs_dlgDefault = str_default;
    LRESULT r = DoDebugDialog((HWND)0, NULL);
    printf("result = %d\n", r);fflush(stdout);
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    Inline_Stack_Push(&PL_sv_undef);
    Inline_Stack_Done;
    return;
}

__NOTES__

Per Inline::C::Cookbook, `return &PL_sv_undef` is the way to _return_ an undef.
My guess is that Inline_Stack_Push(&PL_sv_undef) will push undef onto the stack,
    if I want to have 1 or more returns, including an undef.

For _c_prompt, I want it to return undef on CANCEL/X, and the value of the
    prompted string, otherwise.  I could just do an SV* return value, but
    I want to keep in practice for the list-context return.

Verify that pushing the address of the undef-constant _does_ work.

Remind myself that if I give a NULL dialog-proc function, it draws the dialog but never interact

    That reminds me that my vague plan for a true perl-based callback would be to define the
    real callback in c, so I don't have to figure out all the pointers back and forth,
    but then call my perl function (via a CREF in my SV/SV*) from the c callback.
    (I would do something that would set a global SV* or whatever the code-specific SV-subtype
    was... I wish I remembered where I was working on that, because I could have sworn I was;
    oh, I wonder if I was working on it on my other PC, but forgot to commit... if that's the case,
    then I want to rename this, so that there aren't conflicts)

    however, my new plan is just to define the full prompt dialog in c, and just return the
    string (or undef) to perl; if I'm going to have Inline::C->XS anyway, why not just handle
    it there for now.  I can use some other project for making a more generic dialog creation

svn commit -m "verify returning undef; confirm dlgProc==NULL will display with no interaction; remind myself of the old plan, but decide I still want to go down my new route of doing the full prompt dialog/dlgProc in C (Inline::C now, XS later), and just return the string to perl" → r68

Now, let's start defining a different dialog.  I need two more controls.

Actually, looking up the details:
    https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-dlgitemtemplate =>
     => shows the types:
        0x0080 = BUTTON
        0x0081 = EDIT (textbox?)
        0x0082 = STATIC (label, including bitmap)
        0x0083 = LIST BOX
        0x0084 = SCROLL BAR
        0x0085 = COMBOBOX
So the third control is actual a STATIC control (label or bitmap); since that example doesn't actually
embed a bitmap, it's really a LABEL.  I was able to give it default text using the hardcoded structure.
I then was able to send a new string during WM_INITDIALOG using SetDlgItemTextA(), so I _should_ be
able to dynamically create that label.

While playing around, before finding the Set, I found the Get at
    https://stackoverflow.com/questions/7389757/get-text-from-an-edit-control-pure-win32-api
    where I was able to derive the following:
        int iChars = GetWindowTextLength( GetDlgItem(hwnd, IDC_LABEL) );    // not including '\0'
        iChars = 2;
        char str[256] = "initial text";
        UINT n = GetDlgItemText(hwnd, IDC_LABEL, str, (iChars>255) ? (256) : (iChars + 1));
        printf("GetDlgItemText => '%s'[%d] vs iChars=%d\n", str, n, iChars);
Save that in my notes, because that's what I'll need for saving the results of the INPUT box,
eventually.

By making the label's height bigger, and using \n in the SetDlgItemTextA(), I can make it multiple lines.
If I make a line really long, does it wrap?  Yep.  Height of 26 allows for 3 full rows plus the top of a T
for the fourth row (which is kindof weird, because each row of text was actually 13 pixels, so I would have
expected 41-42 for that; it almost appears that the "height" starts at the _bottom_ of the first row of text,
or the height isn't in pixels, both of which are weird to understand)

But all that to say: I just need _one_ additional field, an EDIT control, to be able to round out my dialog.

svn commit -m "figure out button types for LABEL (0x0082) and probably TEXTBOX (0x0081); experiment with setting text on LABEL" → r69

Able to add some globals and a function that pre-populates the TITLE and LABEL text.

svn commit -m "pre-populate TITLE and LABEL from perl strings"
