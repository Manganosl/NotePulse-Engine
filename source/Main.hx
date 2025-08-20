package;

#if android
import android.content.Context;
#end

import debug.*;

import objects.VolumeTray;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if linux
import lime.graphics.Image;
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

import backend.ExtraKeysHandler;

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 240, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};
	#if !mobile
		public static var framerateSprite:debug.Framerate;
	#end

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
	
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();

		ExtraKeysHandler.instance = new ExtraKeysHandler();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		var mainGame:FridayGame = new FridayGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen,);
		#if desktop @:privateAccess mainGame._customSoundTray = VolumeTray; #end
		addChild(mainGame);

		#if (!mobile && !web)
		    var framerateSprite = new debug.Framerate();
			addChild(framerateSprite);
			SystemInfo.init();
		#end

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		FlxG.mouse.useSystemCursor = true;
		
		#if !CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

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

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if !CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nIf this is related to EK, report it here: https://github.com/FunkinExtraKeys/FNF-PsychEngine-EK\nIf not, report this error to Psych Engine: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}

class FridayGame extends FlxGame
{
	public static var onGameCrash:(errMsg:String, crashDump:String) -> Void;

	/**
	* Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	*/
	override function create(_):Void {
		try super.create(_)
		catch (e) onCrash(e);
	}

	override function onFocus(_):Void {
		try super.onFocus(_)
		catch (e) onCrash(e);
	}

	override function onFocusLost(_):Void {
		try super.onFocusLost(_)
		catch (e) onCrash(e);
	}

	/**
	* Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	*/
	override function onEnterFrame(_):Void {
		try super.onEnterFrame(_)
		catch (e) onCrash(e);
	}

	/**
	* This function is called by `step()` and updates the actual game state.
	* May be called multiple times per "frame" or draw call.
	*/
	override function update():Void {
		try super.update()
		catch (e) onCrash(e);
	}

	/**
	* Goes through the game state and draws all the game objects and special effects.
	*/
	override function draw():Void {
		try super.draw()
		catch (e) onCrash(e);
	}

	private final function onCrash(e:haxe.Exception):Void {
    	var errMsg:String = "";
    	var path:String;
    	var callStack:Array<StackItem> = haxe.CallStack.exceptionStack(true);
    	var dateNow:String = Date.now().toString();

    	dateNow = dateNow.replace(" ", "_");
    	dateNow = dateNow.replace(":", "'");

    	path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

    	for (stackItem in callStack)
    	{
    	    switch (stackItem)
    	    {
    	        case FilePos(s, file, line, column):
    	            errMsg += file + " (line " + line + ")\n";
    	        default:
    	            Sys.println(stackItem);
    	            trace(stackItem);
    	    	}
    		}

    	errMsg += "\nUncaught Error: " + e.message + "\nIn case this wasn't caused by any modifications, report this error to NotePulse Engine: https://github.com/Manganosl/NotePulse-Engine\n\n> Crash Handler written by: sqirra-rng";

    	if (!sys.FileSystem.exists("./crash/"))
        	sys.FileSystem.createDirectory("./crash/");

    	sys.io.File.saveContent(path, errMsg + "\n");

    	Sys.println(errMsg);
    	Sys.println("Crash dump saved in " + haxe.io.Path.normalize(path));

    	#if (!mobile && !web)
    	try {
    	    openfl.Lib.application.window.alert(errMsg, "Error!");
    	} catch(e:Dynamic) {}
    	#end

    	if(onGameCrash != null) onGameCrash(errMsg, e.message);

   		flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
    	FlxG.switchState(new states.CrashHandlerState(FlxG.state, errMsg, e.message));
	}
}