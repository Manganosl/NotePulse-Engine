package funkin.backend.utils.helpers;

import funkin.backend.utils.WindowUtil.MessageBoxIcon;
import funkin.backend.utils.WindowUtil.MessageBoxType;

#if windows
@:buildXml('
<compilerflag value="/DelayLoad:ComCtl32.dll"/>

<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
    <lib name="shell32.lib" if="windows" />
    <lib name="gdi32.lib" if="windows" />
</target>
')
@:cppFileCode('
#define WIN32_LEAN_AND_MEAN // Excludes rarely-used APIs like cryptography, DDE, RPC, and shell functions, reducing compile time and binary size.
#define NOMINMAX // Prevents Windows from defining min() and max() macros, which can conflict with standard C++ functions.
#define NOCRYPT // Excludes Cryptographic APIs, such as Encrypt/Decrypt functions.
#define NOCOMM // Excludes serial communication APIs, such as COM port handling.
#define NOKANJI // Excludes Kanji character set support (not needed unless working with Japanese text processing).
#define NOHELP // Excludes Windows Help APIs, removing functions related to WinHelp and other help systems.

#include <Windows.h>
#include <windowsx.h>
#include <winternl.h>
#include <psapi.h>
#include <cstdio>
#include <commctrl.h>
#include <string>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <stdint.h>
#include <stdio.h>
#include <Shlobj.h>

#include <chrono>
#include <thread>

#define UNICODE

#pragma comment(lib, "Dwmapi")
#pragma comment(lib, "ntdll.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "Shell32.lib")
#pragma comment(lib, "gdi32.lib")

BOOL SaveToFile(HBITMAP hBitmap3, LPCTSTR lpszFileName)
{   
	HDC hDC;
	int iBits;
	WORD wBitCount;
	DWORD dwPaletteSize=0, dwBmBitsSize=0, dwDIBSize=0, dwWritten=0;
	BITMAP Bitmap0;
	BITMAPFILEHEADER bmfHdr;
	BITMAPINFOHEADER bi;
	LPBITMAPINFOHEADER lpbi;
	HANDLE fh, hDib, hPal,hOldPal2=NULL;
	hDC = CreateDC("DISPLAY", NULL, NULL, NULL);
	iBits = GetDeviceCaps(hDC, BITSPIXEL) * GetDeviceCaps(hDC, PLANES);
	DeleteDC(hDC);
	if (iBits <= 1)
		wBitCount = 1;
	else if (iBits <= 4)
		wBitCount = 4;
	else if (iBits <= 8)
		wBitCount = 8;
	else
		wBitCount = 24; 
	GetObject(hBitmap3, sizeof(Bitmap0), (LPSTR)&Bitmap0);
	bi.biSize = sizeof(BITMAPINFOHEADER);
	bi.biWidth = Bitmap0.bmWidth;
	bi.biHeight =-Bitmap0.bmHeight;
	bi.biPlanes = 1;
	bi.biBitCount = wBitCount;
	bi.biCompression = BI_RGB;
	bi.biSizeImage = 0;
	bi.biXPelsPerMeter = 0;
	bi.biYPelsPerMeter = 0;
	bi.biClrImportant = 0;
	bi.biClrUsed = 256;
	dwBmBitsSize = ((Bitmap0.bmWidth * wBitCount +31) & ~31) /8
													* Bitmap0.bmHeight; 
	hDib = GlobalAlloc(GHND,dwBmBitsSize + dwPaletteSize + sizeof(BITMAPINFOHEADER));
	lpbi = (LPBITMAPINFOHEADER)GlobalLock(hDib);
	*lpbi = bi;

	hPal = GetStockObject(DEFAULT_PALETTE);
	if (hPal)
	{ 
		hDC = GetDC(NULL);
		hOldPal2 = SelectPalette(hDC, (HPALETTE)hPal, FALSE);
		RealizePalette(hDC);
	}


	GetDIBits(hDC, hBitmap3, 0, (UINT) Bitmap0.bmHeight, (LPSTR)lpbi + sizeof(BITMAPINFOHEADER) 
		+dwPaletteSize, (BITMAPINFO *)lpbi, DIB_RGB_COLORS);

	if (hOldPal2)
	{
		SelectPalette(hDC, (HPALETTE)hOldPal2, TRUE);
		RealizePalette(hDC);
		ReleaseDC(NULL, hDC);
	}

	fh = CreateFile(lpszFileName, GENERIC_WRITE,0, NULL, CREATE_ALWAYS, 
		FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL); 

	if (fh == INVALID_HANDLE_VALUE)
		return FALSE; 

	bmfHdr.bfType = 0x4D42; // "BM"
	dwDIBSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + dwPaletteSize + dwBmBitsSize;
	bmfHdr.bfSize = dwDIBSize;
	bmfHdr.bfReserved1 = 0;
	bmfHdr.bfReserved2 = 0;
	bmfHdr.bfOffBits = (DWORD)sizeof(BITMAPFILEHEADER) + (DWORD)sizeof(BITMAPINFOHEADER) + dwPaletteSize;

	WriteFile(fh, (LPSTR)&bmfHdr, sizeof(BITMAPFILEHEADER), &dwWritten, NULL);

	WriteFile(fh, (LPSTR)lpbi, dwDIBSize, &dwWritten, NULL);
	GlobalUnlock(hDib);
	GlobalFree(hDib);
	CloseHandle(fh);

	return TRUE;
} 

int screenCapture(int x, int y, int w, int h, LPCSTR fname)
{
    HDC hdcSource = GetDC(NULL);
    HDC hdcMemory = CreateCompatibleDC(hdcSource);

    int capX = GetDeviceCaps(hdcSource, HORZRES);
    int capY = GetDeviceCaps(hdcSource, VERTRES);

    HBITMAP hBitmap = CreateCompatibleBitmap(hdcSource, w, h);
    HBITMAP hBitmapOld = (HBITMAP)SelectObject(hdcMemory, hBitmap);

    BitBlt(hdcMemory, 0, 0, w, h, hdcSource, x, y, SRCCOPY);
    hBitmap = (HBITMAP)SelectObject(hdcMemory, hBitmapOld);

    DeleteDC(hdcSource);
    DeleteDC(hdcMemory);

    HPALETTE hpal = NULL;
    if(SaveToFile(hBitmap, fname)) return 1;
    return 0;
}
')
#elseif linux
@:cppFileCode("#include <stdio.h>")
#end

// Most CPP code taken from https://github.com/Slushi-Github/Slushi-Engine/blob/main/funkinscsource/slushi/windows/WindowsCPP.hx
class CppBackend {
	#if windows
	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);

		return (allocatedRAM / 1024);
	")
	#elseif linux
	@:functionCode('
		FILE *meminfo = fopen(\"/proc/meminfo\", \"r\");

    	if(meminfo == NULL)
			return -1;

    	char line[256];
    	while(fgets(line, sizeof(line), meminfo))
    	{
        	int ram;
        	if(sscanf(line, \"MemTotal: %d kB\", &ram) == 1)
        	{
            	fclose(meminfo);
            	return (ram / 1024);
        	}
    	}

    	fclose(meminfo);
    	return -1;
	')
	#end
	public static function obtainRAM()
	{
		return 0;
	}

	#if windows
	@:functionCode("
        HWND window = GetActiveWindow();
		int isDark = isDarkMode ? 1 : 0;
		
        if (DwmSetWindowAttribute(window, 19, &isDark, sizeof(isDark)) != S_OK) {
            DwmSetWindowAttribute(window, 20, &isDark, sizeof(isDark));
        }
        UpdateWindow(window);
    ")
	public static function setWindowColorMode(isDarkMode:Bool) {}
	
	@:functionCode("
        HWND window = GetActiveWindow();

		COLORREF finalColor;
		if(color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
			finalColor = 0xFFFFFFFF; // Default border
		} else if(color[3] == 0) {
			finalColor = 0xFFFFFFFE; // No border (must have setBorder as true)
		} else {
			finalColor = RGB(color[0], color[1], color[2]); // Use your custom color
		}

		if (window != NULL) {
			if(setHeader) DwmSetWindowAttribute(window, 35, &finalColor, sizeof(COLORREF));
			if(setBorder) DwmSetWindowAttribute(window, 34, &finalColor, sizeof(COLORREF));

			UpdateWindow(window);
		}
    ")
	public static function setWindowBorderColor(color:Array<Int>, setHeader:Bool = true, setBorder:Bool = false) {}
	
	@:functionCode('
	HWND window = GetActiveWindow();

	COLORREF finalColor;
	if(color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
		finalColor = 0xFFFFFFFF; // Default border
	} else {
		finalColor = RGB(color[0], color[1], color[2]); // Use your custom color
	}

	if (window != NULL) {
		DwmSetWindowAttribute(window, 36, &finalColor, sizeof(COLORREF));
		UpdateWindow(window);
	}
	')
	public static function setWindowTitleColor(color:Array<Int>) {}
	
	@:functionCode("return MessageBoxA(GetActiveWindow(), text, title, icon | msgType);")
	public static function makeMessageBox(title:String, text:String, icon:MessageBoxIcon, msgType:MessageBoxType) {
		return 0;
	}

	@:functionCode('
	// https://stackoverflow.com/questions/15543571/allocconsole-not-displaying-cout

	if (!AllocConsole())
		return;

	freopen(\"CONIN$\", \"r\", stdin);
	freopen(\"CONOUT$\", \"w\", stdout);
	freopen(\"CONOUT$\", \"w\", stderr);

	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	if (hOut != INVALID_HANDLE_VALUE) {
		DWORD outMode = 0;
		if (GetConsoleMode(hOut, &outMode)) {
			// ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
			// ENABLE_PROCESSED_OUTPUT = 0x0001 (leave as-is)
			outMode |= 0x0004;
			SetConsoleMode(hOut, outMode);
		}
	}

	HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
	if (hIn != INVALID_HANDLE_VALUE) {
		DWORD inMode = 0;
		if (GetConsoleMode(hIn, &inMode)) {
			inMode |= 0x0200;
			SetConsoleMode(hIn, inMode);
		}
	}
	')
	public static function allocConsole() {
	}

	@:functionCode('
	PROCESS_MEMORY_COUNTERS_EX pmc;

	if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc)))
		return pmc.WorkingSetSize;

	return 0;
	')
    public static function getProcessMemoryWorkingSetSize(){
		return 0;
	};

	@:functionCode('
		HMODULE ntdll = GetModuleHandleA("ntdll.dll");
		if (ntdll) {
			void* wine_get_version = GetProcAddress(ntdll, "wine_get_version");
			if (wine_get_version) {
				return true;
			}
		}
		return false;
	')
	public static function detectWine():Bool
	{
		return false;
	}

	@:functionCode(' Beep(freq, duration); ')
	public static function beep(freq:Int, duration:Int){}

	@:functionCode('
		HWND window = GetActiveWindow();

		if (show) {
			ShowWindow(window, SW_SHOW);
		} else {
			ShowWindow(window, SW_HIDE);
		}
	')
	static public function setWindowVisible(show:Bool){}

	@:functionCode('
		BOOL isAdmin = FALSE;
		SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
		PSID adminGroup = nullptr;

		if (AllocateAndInitializeSid(&ntAuthority, 2,
			SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
			0, 0, 0, 0, 0, 0, &adminGroup)) {

			if (!CheckTokenMembership(nullptr, adminGroup, &isAdmin)) {
				isAdmin = FALSE;
			}

			FreeSid(adminGroup);
		}

		return isAdmin == TRUE;
	')
	public static function isRunningAsAdmin():Bool
	{
		return false;
	}

	@:functionCode('
		int screenWidth = GetSystemMetrics(SM_CXSCREEN);
		int screenHeight = GetSystemMetrics(SM_CYSCREEN);
		screenCapture(0, 0, screenWidth, screenHeight, path);
	')
	@:noCompletion
	public static function windowsScreenShot(path:String){
	}

	@:functionCode('
		bool value = hide;
		HWND hwnd = FindWindowA("Shell_traywnd", nullptr);
		HWND hwnd2 = FindWindowA("Shell_SecondaryTrayWnd", nullptr);
	
		if (value == true) {
			ShowWindow(hwnd, SW_HIDE);
			ShowWindow(hwnd2, SW_HIDE);
		} else {
			ShowWindow(hwnd, SW_SHOW);
			ShowWindow(hwnd2, SW_SHOW);
		}
    ')
	public static function hideTaskbar(hide:Bool){
	}

	@:functionCode('
		const char* filepath = path;
	
		int uiAction = SPIF_UPDATEINIFILE | SPIF_SENDCHANGE;
		char filepathBuffer[MAX_PATH];
		strcpy_s(filepathBuffer, filepath);
	
		SystemParametersInfoA(SPI_SETDESKWALLPAPER, 0, filepathBuffer, uiAction);	
    ')
	public static function setWallpaper(path:String){
	}

	@:functionCode('
		bool value = hide;
		HWND hProgman = FindWindowW (L"Progman", L"Program Manager");
		HWND hChild = GetWindow (hProgman, GW_CHILD);
		
		if (value == true) {
			ShowWindow (hChild, SW_HIDE);
		} else {
			ShowWindow (hChild, SW_SHOW);
		}
    ')
	public static function hideDesktopIcons(hide:Bool){
	}

	@:functionCode('
		HWND hd;

		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);

		SetWindowPos(hd, NULL, x, NULL, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    ')
	public static function moveDesktopWindowsInX(x:Int){
	}

	@:functionCode('
		HWND hd;

		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);

		SetWindowPos(hd, NULL, NULL, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    ')
	public static function moveDesktopWindowsInY(y:Int){
	}

	@:functionCode('
		HWND hd;

		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);

		SetWindowPos(hd, NULL, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    ')
	public static function moveDesktopWindowsInXY(x:Int, y:Int){
	}

	@:functionCode('
		HWND hd;

		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);
		RECT rect;

		GetWindowRect(hd, &rect);

		int x = rect.left;

		return x;
	')
	public static function returnDesktopWindowsX(){
		return 0;
	}

	@:functionCode('
		HWND hd;

		hd = FindWindowA("Progman", NULL);
		hd = FindWindowEx(hd, 0, "SHELLDLL_DefView", NULL);
		hd = FindWindowEx(hd, 0, "SysListView32", NULL);
		RECT rect;

		GetWindowRect(hd, &rect);

		int y = rect.top;

		return y;
	')
	public static function returnDesktopWindowsY(){
		return 0;
	}

	@:functionCode('
		HWND hProgman = FindWindowW(L"Progman", L"Program Manager");
		HWND hChild = GetWindow(hProgman, GW_CHILD);

		float a = alpha;

		if (alpha > 1) {
			a = 1;
		} 
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(hChild, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
    ')
	public static function _setDesktopWindowsAlpha(alpha:Float){
		return alpha;
	}

	@:functionCode('
		HWND hwnd = FindWindowA("Shell_traywnd", nullptr);
		HWND hwnd2 = FindWindowA("Shell_SecondaryTrayWnd", nullptr);

		float a = alpha;

		if (alpha > 1) {
			a = 1;
		} 
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(hwnd, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
		SetLayeredWindowAttributes(hwnd2, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
    ')
	public static function _setTaskBarAlpha(alpha:Float){
		return alpha;
	}

	@:functionCode('
		HWND window;
		HWND window2;

		switch (numberMode) {
			case 0:
				window = FindWindowW(L"Progman", L"Program Manager");
				window = GetWindow(window, GW_CHILD);
			case 1:
				window = FindWindowA("Shell_traywnd", nullptr);
				window2 = FindWindowA("Shell_SecondaryTrayWnd", nullptr);
		}

		if (numberMode != 1) {
			SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
		}
		else {
			SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
			SetWindowLong(window2, GWL_EXSTYLE, GetWindowLong(window2, GWL_EXSTYLE) ^ WS_EX_LAYERED);
		}
	')
	public static function _setWindowLayeredMode(numberMode:Int){}
	#end
}

