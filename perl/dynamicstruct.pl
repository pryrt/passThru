#!perl

use 5.012; # strict, //
use warnings;
use utf8;   # means the source code is formatted as UTF8
use open ':std', ':encoding(UTF-8)';
use Encode;
$|=1;

#use Inline C => Config => CLEAN_AFTER_BUILD => 0;   # uncomment to keep the compiled version
use Inline C => 'DATA';
sub my_wrapper { c_wrapper(@_?@_:0) }
#my_wrapper();

my $u16le = encode('UTF-16LE', my $str = "Trial Text \x{263A}");
printf "from perl: str:'%s':%d vs u16le:'%s':%d\n", $str, length($str), $u16le, length($u16le);
#dialog_with_title_and_length(length($u16le), $u16le);

sv_nolen("▶◀ Bow Ties ▶◀");
dialog_with_perl_title("▶◀ Bow Ties ▶◀");

__DATA__

__C__
void printf_bytes(LPVOID ptr, size_t sz)
{
    char* cp = (char*)ptr;
    printf("OBJECT(size=%d)\n", sz);
    for(size_t i=0; i<sz; i++) {
        if(0==i%16) printf("%4s0x%016X%4s", "", ptr+i, "");
        printf("\\x%02X", cp[i]&0xFF);
        if(15==i%16) printf("\n");
    }
    printf("\n");fflush(stdout);
}

void dynamic_struct(LPCSTR str)
{
    #pragma pack(push, 4)

    printf("string was \"%s\": %d characters\n", str, strlen(str));

    size_t NCHAR = strlen(str) + 1;
    struct {
        DWORD   dw;
        WORD    w;
        CHAR    s[NCHAR];
        int     i;
    } s_instance;
    memset(&s_instance, 0x00, sizeof(s_instance));
    printf("%p => sizseof(s_instance   ) = %d\n", &s_instance       , sizeof(s_instance)         );
    printf("%p => sizseof(s_instance.dw) = %d\n", &s_instance.dw    , sizeof(s_instance.dw)      );
    printf("%p => sizseof(s_instance.w ) = %d\n", &s_instance.w     , sizeof(s_instance.w)       );
    printf("%p => sizseof(s_instance.s ) = %d\n", &s_instance.s     , sizeof(s_instance.s)       );
    printf("%p => sizseof(s_instance.i ) = %d\n", &s_instance.i     , sizeof(s_instance.i)       );
    s_instance.dw = 0xDeadBeef;
    s_instance.w  = 0x1234;
    strncpy(s_instance.s, str, NCHAR-1);
    s_instance.i = 255;
    printf_bytes(&s_instance, sizeof(s_instance));

    #pragma pack(pop)
    fflush(stdout);
}
INT_PTR CALLBACK cDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch(uMsg)
    {
        case WM_INITDIALOG: {
            break;
        }
        case WM_COMMAND: {
            break;
        }
        case WM_CLOSE: {
            EndDialog(hwnd, IDCANCEL);
            break;
        }
    }
    return FALSE;
}

#include <wchar.h>
LRESULT dynamic_wdialog(WCHAR my_title[])
{
    printf("wcslen(my_title)=%d\n", wcslen(my_title));
    WCHAR my_font[] = L"MS Shell Dlg";
    size_t title_strlen = wcslen(my_title);
    size_t font_strlen = wcslen(my_font);
    #pragma pack(push, 4)
    struct {
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
        WORD      menu;
        WORD      windowClass;
        WCHAR     title[title_strlen+1];
        WORD      pointsize;
        WORD      weight;
        BYTE      italic;
        BYTE      charset;
        WCHAR     typeface[font_strlen+1];
        BYTE      dialogs[0];
    } template;
    memset(&template, 0x00, sizeof(template));
    template.dlgVer = 1;
    template.signature = 0xFFFF;
    template.style = WS_SYSMENU | CS_HREDRAW | CS_VREDRAW | DS_SETFONT | WS_SIZEBOX;
    template.cDlgItems = 0; // TODO: get from param
    template.cx = 180;
    template.cy = 120;
    wcsncpy(template.title, my_title, title_strlen);
    template.pointsize = 8;
    template.charset = 1;
    wcsncpy(template.typeface, my_font, font_strlen);

    #pragma pack(pop)
    printf_bytes(&template, sizeof(template));
    printf("address(template) = 0x%016X (sizeof=%d)\n", &template           , sizeof(template         ));
    printf("address(title)    = 0x%016X (sizeof=%d)\n", &template.title     , sizeof(template.title   ));
    printf("address(typeface) = 0x%016X (sizeof=%d)\n", &template.typeface  , sizeof(template.typeface));
    printf("address(dialogs)  = 0x%016X (sizeof=%d)\n", &template.dialogs   , sizeof(template.dialogs ));
    fflush(stdout);

    LRESULT lr = DialogBoxIndirectParamW(0, (LPCDLGTEMPLATEW)&template, 0, cDlgProc, (LPARAM)NULL);
    return(lr);
}

void c_wrapper(int ignore)
{
    //dynamic_struct("This string is normal.");
    //dynamic_struct("quick");
    dynamic_wdialog(L"\x2713 Dynamic Title From Parameter");
}

void dialog_with_title_and_length(int n_bytes, SV* sv_u16le_title)
{
    char* bytes = SvPV(sv_u16le_title, n_bytes);
    printf_bytes(bytes, n_bytes);
    size_t len_plus_null = n_bytes/2 + 1;
    WCHAR* wstr = (WCHAR*)calloc(len_plus_null, sizeof(WCHAR));
    swprintf(wstr, len_plus_null, L"%ls", (WCHAR*)bytes);
    wprintf(L"wstr = '%ls' len_plus_null=%d wcslen=%d\n", wstr, len_plus_null, wcslen(wstr));
    printf_bytes(wstr, len_plus_null*sizeof(WCHAR));
    dynamic_wdialog(wstr);
}

void sv_nolen(SV* sv_utf8)
{
    char* str = SvPVutf8_nolen(sv_utf8);
    printf("sv_nolen(%s):\n", str);
    printf_bytes(str, strlen(str)+1);


    int nNeeded = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED | MB_ERR_INVALID_CHARS, str, -1, NULL, 0);    // figure out chars needed
    WCHAR* wstr = (WCHAR*) calloc(nNeeded, sizeof(WCHAR));
    int nConverted = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED | MB_ERR_INVALID_CHARS, str, -1, wstr, nNeeded);    // make use of it
    printf("nNeeded=%d, nConverted=%d\n", nNeeded, nConverted);
    printf("normal printf of wstr => '%ls'\n", wstr);
    wprintf(L"wide printf of wstr => '%ls'\n", wstr);
    printf_bytes(wstr, nNeeded*sizeof(WCHAR));
}

void dialog_with_perl_title(SV* sv_title_utf8)
{
    char* title_utf8 = SvPVutf8_nolen(sv_title_utf8);
    int nNeeded = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED | MB_ERR_INVALID_CHARS, title_utf8, -1, NULL, 0);    // figure out chars needed
    WCHAR* wTitle = (WCHAR*) calloc(nNeeded, sizeof(WCHAR));
    int nConverted = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED | MB_ERR_INVALID_CHARS, title_utf8, -1, wTitle, nNeeded);    // make use of it
    dynamic_wdialog(wTitle);
}

// https://perlmonks.org/index.pl?node_id=1213554 => stevieb asked about threads and callbacks, but it shows the call_sv() to call a coderef
//      https://perldoc.perl.org/perlapi#call_sv
// that answer also had BrowserUK point to https://perlmonks.org/index.pl?node_id=413556, which may have more on callbacks
// see also pseudo-closures https://stackoverflow.com/a/41417121
