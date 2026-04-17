package;

#if android
import android.content.Context;
#end

import funkin.objects.debug.FunkinDebugDisplay;
import funkin.objects.debug.FunkinDebugPrint;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import haxe.macro.Compiler;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;

#if linux
import lime.graphics.Image;
#end

import funkin.backend.ExtraKeysHandler;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{
	public static var GIT_COMMIT:String = Compiler.getDefine("GIT_COMMIT") != null ?
	Compiler.getDefine("GIT_COMMIT").split("=")[0] : null;
	public static var npeVersion:String = "0.8.0";
	public static var psychEngineVersion:String = '0.7.3';

	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: Init, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};
	public static var fpsVar:FunkinDebugDisplay;
	public static var traces:FunkinDebugPrint;
	

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}
	
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(funkin.scripting.CallbackHandler.call)); #end
		Controls.instance = new Controls();

		ExtraKeysHandler.instance = new ExtraKeysHandler();
		ClientPrefs.loadDefaultKeys();

		addChild(new FunkinGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		traces = new FunkinDebugPrint();
		addChild(traces);

		#if !mobile
		fpsVar = new FunkinDebugDisplay(10, 10, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		FlxG.signals.postUpdate.add(handleDebugDisplayKeys);

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		funkin.backend.utils.WindowUtil.setDarkMode();
		funkin.backend.utils.WindowUtil.init();
		funkin.backend.Log.init();

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		FlxG.mouse.useSystemCursor = true;

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

  	function handleDebugDisplayKeys():Void
  	{
  	  	if (!FlxG.keys.justPressed.F3) return;

		if(!fpsVar.visible)
			fpsVar.visible = true;
		else if(!fpsVar.isAdvanced)
			fpsVar.isAdvanced = true;
		else {
			fpsVar.isAdvanced = false;
			fpsVar.visible = false;
		}
  	}
}