package backend.extraUtils;

import openfl.Lib;

import lime.app.Application;

import flash.system.System;

import lime.ui.Window;

import lime.ui.WindowAttributes;

import flixel.FlxGame;

// WIP
// functions used to mess with some window properties for ease
class WindowUtil
{
	public static var monitorResolutionWidth(get, never):Float;
	public static var monitorResolutionHeight(get, never):Float;
	
	static function get_monitorResolutionWidth():Float return openfl.system.Capabilities.screenResolutionX;
	
	static function get_monitorResolutionHeight():Float return openfl.system.Capabilities.screenResolutionY;
	
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

    	var s = new backend.extraUtils.helpers.FunkinRatioScaleMode();
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

	public static var preventClosing:Bool = true;
	public static var onClosing:Void->Void;

	static var __triedClosing:Bool = false;
	public static inline function resetClosing() __triedClosing = false;

	public static inline function init() {
		Lib.application.window.onClose.add(function () {
			if (preventClosing && !__triedClosing) {
				Lib.application.window.onClose.cancel();
				__triedClosing = true;
			}
			if (onClosing != null) onClosing();
		});
	}
}