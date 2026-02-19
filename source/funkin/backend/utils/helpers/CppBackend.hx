package funkin.backend.utils.helpers;

import funkin.backend.utils.WindowUtil.MessageBoxIcon;
import funkin.backend.utils.WindowUtil.MessageBoxType;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
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
#include <psapi.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <stdint.h>
#include <stdio.h>
')
#elseif linux
@:cppFileCode("#include <stdio.h>")
#end
class CppBackend
{
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
	#end
}

