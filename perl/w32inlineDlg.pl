#!perl

use 5.012; # strict, //
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

myDialog(0);

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
#define DLGAPPLY  L"&Apply"
#define DLGCANCEL L"&Cancel"
#define NUMCHARS(aa) (sizeof(aa)/sizeof((aa)[0]))
#define IDC_BITMAP 99

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
    //
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
       WCHAR  wszTitle[NUMCHARS(DLGAPPLY)];
       WORD   cbCreationData; // bytes of following creation data
//       WORD   wAlign;         // align next control to DWORD boundry.
    } apply;

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
       WCHAR  wszTitle[1];    // title string or ordinal of a resource
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
      DLGAPPLY, 0,
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
      6,6,288,8,
      IDC_BITMAP,
      0xFFFF, 0x0082, // static
      L"", 0,
      },
   };

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

   return DialogBoxIndirectParamW (hinst, (LPCDLGTEMPLATEW)&g_DebugDlgTemplate, hwndApp, /*NULL*/Debug_DlgProc, (LPARAM)pvData);
}

IV c_myDialog(UV hwndApp)
{
    LRESULT r = DoDebugDialog((HWND)hwndApp, NULL);
    printf("result = %d\n", r);fflush(stdout);
    return((IV)r);
}
