package funkin.backend.utils;

import openfl.Lib;
import lime.app.Application;
import flash.system.System;
import lime.ui.Window;
import lime.ui.WindowAttributes;
import flixel.FlxGame;
import funkin.backend.utils.helpers.CppBackend;

using StringTools;

// WIP
// functions used to mess with some window properties for ease
class WindowUtil
{
	public static var monitorResolutionWidth(get, never):Float;
	public static var monitorResolutionHeight(get, never):Float;
	
	public static function get_monitorResolutionWidth():Float return openfl.system.Capabilities.screenResolutionX;
	
	public static function get_monitorResolutionHeight():Float return openfl.system.Capabilities.screenResolutionY;

	public static function getCenterMonitorPoint():FlxPoint {
		return FlxPoint.get(monitorResolutionWidth/2, monitorResolutionHeight/2);
	}
	
	public static var defaultAppTitle(get, never):String;
	
	static function get_defaultAppTitle():String return Application.current.meta['name'];
	
	public static function crashTheFuckingGame()
	{
		System.exit(0);
	}
	
	public static function getWindow()
	{
		return Application.current.window;
	}
	
	public static function setTitle(?arg:String, append:Bool = false)
	{
		if (arg == null) arg = defaultAppTitle;
		
		if (append) getWindow().title += arg;
		else getWindow().title = arg;
	}
	
	public static function setGameDimensions(width:Int, height:Int, cameras:Array<FlxCamera>)
	{
    	var newWidth:Int = width;
    	var newHeight:Int = height;

    	for (camera in cameras)
    	{
        	camera.width = newWidth;
        	camera.height = newHeight;
    	}

    	if (!FlxG.fullscreen)
    	{
        	FlxG.resizeWindow(newWidth, newHeight);
        	var win = getWindow();
        	win.x = Std.int((monitorResolutionWidth - newWidth) / 2);
       		win.y = Std.int((monitorResolutionHeight - newHeight) / 2);
    	}

    	var s = new funkin.backend.utils.helpers.FunkinRatioScaleMode();
    	s.width = newWidth;
    	s.height = newHeight;
    	FlxG.scaleMode = s;
	}
	
	public static inline function centerWindowOnPoint(?point:FlxPoint)
	{
		Lib.application.window.x = Std.int(point.x - (Lib.application.window.width / 2));
		Lib.application.window.y = Std.int(point.y - (Lib.application.window.height / 2));
	}
	
	public static inline function getCenterWindowPoint():FlxPoint
	{
		return FlxPoint.get(Lib.application.window.x + (Lib.application.window.width / 2), Lib.application.window.y + (Lib.application.window.height / 2));
	}

	public static var onClosing:Void->Void;
	public static var onEditorClosing:Void->Void;
	public static var preventClose:Bool = false;

	public static inline function init() {
		Lib.application.window.onClose.add(function () {
			if(onClosing != null) onClosing();
			if(onEditorClosing != null) onEditorClosing();
			if(preventClose) Lib.application.window.onClose.cancel();
		});
	}

	#if cpp
	public static function obtainRAM():Int
		return CppBackend.obtainRAM();

	public static function setColorTransparent(col:Int)
		CppBackend.setWindowColorKey(col);
	
	//Detects if you are currently using a certain version of windows
	public static function hasWindowsVersion(vers:String = "10")
	{
		if(lime.system.System.platformLabel.contains(vers)) return true;
		
		return false;
	}

	public static function setDarkMode()
	{
		CppBackend.setWindowColorMode(true);
	}
	
	public static function setLightMode()
	{
		CppBackend.setWindowColorMode(false);
	}
	
	public static function setWindowColorMode(isDarkMode:Bool = false, redrawHeader:Bool = false)
	{
		CppBackend.setWindowColorMode(isDarkMode);
		
		if(redrawHeader) {
			FlxG.stage.window.borderless = true;
			FlxG.stage.window.borderless = false;
		}
	}

	public static function setWindowBorderColor(color:Array<Int>, setHeader:Bool = true, setBorder:Bool = false)
	{
		if(color != null)
			CppBackend.setWindowBorderColor([color[0], color[1], color[2], color[3]], setHeader, setBorder);
		else
			CppBackend.setWindowBorderColor([-1, -1, -1, -1], setHeader, setBorder);
	}
	
	public static function setWindowTitleColor(color:Array<Int>)
	{
		if(color != null)
			CppBackend.setWindowBorderColor([color[0], color[1], color[2], color[3]]);
		else
			CppBackend.setWindowTitleColor([-1, -1, -1, -1]);
	}
	
	public static function redrawWindowHeader()
    {
		FlxG.stage.window.borderless = true;
		FlxG.stage.window.borderless = false;
    }
	
	public static function makeMessageBox(title:String, text:String, ?icon:MessageBoxIcon = MB_ICONINFORMATION, ?msgType:MessageBoxType = MB_OK) {
		#if (cpp && windows)
		if(title != null && text != null) return CppBackend.makeMessageBox(title, text, icon, msgType);
		else {
			trace('Error: "title" or "text" parameter is null.');
			return 0;
		}
		#end
	}

	public static function showConsole(){
		#if (cpp && windows)
		CppBackend.allocConsole();
		#end
	}

	public static function isWine():Bool {
		return CppBackend.detectWine();
	}

	public static function isAdmin():Bool {
		return CppBackend.isRunningAsAdmin();
	}

	public static function screenShot(path:String) {
		return CppBackend.windowsScreenShot(path);
	}

	public static function beep(freq:Int, duration:Int) CppBackend.beep(freq, duration);

	public static function setWindowVisibility(visible:Bool) {
		CppBackend.setWindowVisible(visible);
	}

	public static function setTaskbarVisibility(visible:Bool) {
		CppBackend.hideTaskbar(visible);
	}

	public static function setWallpaper(path:String) {
		CppBackend.setWallpaper(path);
	}

	public static function getWallpaper():String {
		return CppBackend.getWallpaper();
	}

	public static function setDesktopIconsVisibility(visible:Bool) {
		CppBackend.hideDesktopIcons(visible);
	}
	#end
}

enum abstract MessageBoxIcon(Int) {
	var MB_ICONWARNING = 0x00000030;
	var MB_ICONINFORMATION = 0x00000040;
	var MB_ICONQUESTION = 0x00000020;
	var MB_ICONERROR = 0x00000010;
	var MB_NONE = 0x00;
}

enum abstract MessageBoxType(Int) {
	var MB_ABORTRETRYIGNORE = 0x00000002;
	var MB_CANCELTRYCONTINUE = 0x00000006;
	var MB_HELP = 0x00004000;
	var MB_OKCANCEL = 0x00000001;
	var MB_RETRYCANCEL = 0x00000005;
	var MB_YESNO = 0x00000004;
	var MB_YESNOCANCEL = 0x00000003;
	var MB_OK = 0x00000000;
}