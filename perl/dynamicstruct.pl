#!perl

use 5.012; # strict, //
use warnings;
$|=1;

#use Inline C => Config => CLEAN_AFTER_BUILD => 0;   # uncomment to keep the compiled version
use Inline C => 'DATA';
sub my_wrapper { c_wrapper(@_?@_:0) }

my_wrapper();

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
#define NUMCHARS(x) (sizeof(x)/sizeof(x[0]))
LRESULT dynamic_wdialog(void)
{
    WCHAR my_title[] = L"TitleString";
    WCHAR my_font[] = L"MS Shell Dlg";
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
        WCHAR     title[NUMCHARS(my_title)+1];
        WORD      pointsize;
        WORD      weight;
        BYTE      italic;
        BYTE      charset;
        WCHAR     typeface[NUMCHARS(my_font)+1];
        BYTE      dialogs[0];
    } template;
    memset(&template, 0x00, sizeof(template));
    template.dlgVer = 1;
    template.signature = 0xFFFF;
    template.style = WS_SYSMENU | CS_HREDRAW | CS_VREDRAW | DS_SETFONT | WS_SIZEBOX;
    template.cDlgItems = 0; // TODO: get from param
    template.cx = 180;
    template.cy = 120;
    wcsncpy(template.title, my_title, NUMCHARS(my_title));
    template.pointsize = 8;
    template.charset = 1;
    wcsncpy(template.typeface, my_font, NUMCHARS(my_font));

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
    dynamic_wdialog();
}
