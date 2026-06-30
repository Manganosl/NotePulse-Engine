package funkin.scripting.lua.functions;

import funkin.backend.utils.WindowUtil;
import openfl.Lib;

class WindowFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;

		Lua_helper.add_callback(lua, "setWindowPosition", function(?xValue:Int = 0, ?yValue:Int = 0) {
			#if windows
			WindowUtil.getWindow().x = xValue;
			WindowUtil.getWindow().y = yValue;
			#end
		});
		
		Lua_helper.add_callback(lua, "windowScreenCenter", function(?axis:String = 'xy') {
			#if windows
			var desktopDimensions:Array<Int> = [
				Std.int(Lib.application.window.display.bounds.width),
				Std.int(Lib.application.window.display.bounds.height)
			];
			
			if (axis.toLowerCase().contains('x'))
				WindowUtil.getWindow().x = Std.int((desktopDimensions[0] - WindowUtil.getWindow().width) / 2);

			if (axis.toLowerCase().contains('y'))
				WindowUtil.getWindow().y = Std.int((desktopDimensions[1] - WindowUtil.getWindow().height) / 2);
			#end
		});
		
		Lua_helper.add_callback(lua, "setWindowProperty", function(property:String, ?newValue:Dynamic) {
			#if windows
			if(property != null)
			{
				switch(property)
				{
					case 'borderless':
						WindowUtil.getWindow().borderless = newValue;
					case 'height':
						WindowUtil.getWindow().height = newValue;
					case 'width':
						WindowUtil.getWindow().width = newValue;
					case 'x':
						WindowUtil.getWindow().x = newValue;
					case 'y':
						WindowUtil.getWindow().y = newValue;
					case 'fullscreen':
						WindowUtil.getWindow().fullscreen = newValue;
					case 'title':
						WindowUtil.getWindow().title = newValue;
					case 'resizable':
						WindowUtil.getWindow().resizable = newValue;
				}
			} else {
				FunkinLua.luaTrace("setWindowProperty: Unknown value or null", false, false, FlxColor.RED);
			}
			#end
		});
		
		Lua_helper.add_callback(lua, "windowAlert", function(?msg:String, ?title:String) {
			WindowUtil.getWindow().alert(msg, title);
		});
		
		Lua_helper.add_callback(lua, "windowTweenResize", function(tag:String, windowWidth:Float = 1280, windowHeight:Float = 720, duration:Float = 1, ease:String = 'linear') {
			#if windows
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(WindowUtil.getWindow(), {height: windowHeight, width: windowWidth}, duration, {
				ease: LuaUtils.getTweenEaseByString(ease), 
				onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
			}));
			#end
		});
		
		Lua_helper.add_callback(lua, "windowTweenCenter", function(tag:String, ?axis:String = 'xy', duration:Float = 1, ease:String = 'linear') {
			#if windows
			var desktopDimensions:Array<Int> = [
				Std.int(Lib.application.window.display.bounds.width),
				Std.int(Lib.application.window.display.bounds.height)
			];
			
			var screenCenterX:Int = Std.int((desktopDimensions[0] - WindowUtil.getWindow().width) / 2);
			var screenCenterY:Int = Std.int((desktopDimensions[1] - WindowUtil.getWindow().height) / 2);
			
			if (axis.toLowerCase().contains('x'))
			{
				var winResize:FlxTween = FlxTween.tween(WindowUtil.getWindow(), {x: screenCenterX}, duration, {
				ease: LuaUtils.getTweenEaseByString(ease), 
				onComplete: function(twn:FlxTween) {
						if(!axis.toLowerCase().contains('y'))
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						
						PlayState.instance.modchartTweens.remove(tag);
					}
				});
			}
			if (axis.toLowerCase().contains('y'))
			{
				var winResize:FlxTween = FlxTween.tween(WindowUtil.getWindow(), {y: screenCenterY}, duration, {
				ease: LuaUtils.getTweenEaseByString(ease), 
				onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				});
			}
			#end
		});
		
		Lua_helper.add_callback(lua, "windowTweenX", function(tag:String, value:Float, duration:Float, ease:String = 'linear') {
			#if windows
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(WindowUtil.getWindow(), {x: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease), onComplete:
                function(twn:FlxTween){
					PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					PlayState.instance.modchartTweens.remove(tag);
				}
            }));
			#end
		});

		Lua_helper.add_callback(lua, "windowTweenY", function(tag:String, value:Float, duration:Float, ease:String = 'linear') {
			#if windows
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(WindowUtil.getWindow(), {y: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease), onComplete:
				function(twn:FlxTween){
					PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					PlayState.instance.modchartTweens.remove(tag);
				}
			}));
			#end
		});
		
		Lua_helper.add_callback(lua, "setWindowTitle", function(title:String) {
			#if windows
			FlxG.stage.window.title = (title == null ? openfl.Lib.application.meta["name"] : title.toString());
			#end
		});

		Lua_helper.add_callback(lua, "getSystemUser", function() {
			#if windows
			return Sys.getEnv("USERNAME");
			#else
			return Sys.getEnv("USER");
			#end	
		});

		Lua_helper.add_callback(lua, "setGameDimensions", function(width:Int, height:Int, cameras:Array<String>) {
			var realCameras:Array<FlxCamera> = [];
			for(camStr in cameras){
				if(camStr.toLowerCase() == "camgame") realCameras.push(PlayState.instance.camGame);
				else if(camStr.toLowerCase() == "camhud") realCameras.push(PlayState.instance.camHUD);
				else if(camStr.toLowerCase() == "camother") realCameras.push(PlayState.instance.camOther);
			}
			WindowUtil.setGameDimensions(width, height, realCameras);
		});
	}
}
