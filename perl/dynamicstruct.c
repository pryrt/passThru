#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Windows.h>

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
        CHAR    z[0];
        CHAR    Z[0];
    } s_instance;
    memset(&s_instance, 0x00, sizeof(s_instance));
    printf("sizseof(s_instance   ) = %d | %p\n", sizeof(s_instance)         , &s_instance);
    printf("sizseof(s_instance.dw) = %d | %p\n", sizeof(s_instance.dw)      , &s_instance.dw);
    printf("sizseof(s_instance.w ) = %d | %p\n", sizeof(s_instance.w)       , &s_instance.w);
    printf("sizseof(s_instance.s ) = %d | %p\n", sizeof(s_instance.s)       , &s_instance.s);
    printf("sizseof(s_instance.i ) = %d | %p\n", sizeof(s_instance.i)       , &s_instance.i);
    printf("sizseof(s_instance.z ) = %d | %p\n", sizeof(s_instance.z)       , &s_instance.z);
    printf("sizseof(s_instance.Z ) = %d | %p\n", sizeof(s_instance.Z)       , &s_instance.Z);
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
    WCHAR my_font[] = L"Segoe UI Symbol"; //L"MS Shell Dlg";
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
    dynamic_wdialog(L"\x263A Title Parameter");
}

int main()
{
    c_wrapper(0);
    return(0);
}
