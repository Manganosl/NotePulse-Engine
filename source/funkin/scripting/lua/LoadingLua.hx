#if LUA_ALLOWED
package funkin.scripting.lua;

import funkin.data.WeekData;

import hxvlc.flixel.*;

import funkin.objects.notes.Note;
import funkin.objects.notes.splashes.NoteSplash;

import funkin.states.handlers.LoadingState;

import funkin.scripting.LuaUtils;

class LoadingLua {
	public var lua:State = null;
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(scriptName:String, isString:Bool = false) {
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		this.scriptName = scriptName.trim();

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
			this.modFolder = myFolder[1];
		#end

		// Lua shit
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString());
		set('difficultyPath', Paths.formatToSongPath(Difficulty.getString()));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState variables
		set('curSection', 0);
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);
		set('combo', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', Main.psychEngineVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		set('playbackRate', 1);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		// Other settings
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		// build target (windows, mac, linux, etc.)
		set('buildTarget', LuaUtils.getBuildTarget());

		for (name => func in customFunctions)
		{
			if(func != null)
				Lua_helper.add_callback(lua, name, func);
		}

		Lua_helper.add_callback(lua, "precacheImage", function(name:String, ?allowGPU:Bool = true) {
			LoadingState.imagesToPrepare.push(name);
		});
		Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
			LoadingState.soundsToPrepare.push(name);
		});
		Lua_helper.add_callback(lua, "precacheMusic", function(name:String) {
			LoadingState.musicToPrepare.push(name);
		});
		Lua_helper.add_callback(lua, "precacheVideo", function(tag:String){
			var video = new FlxVideoSprite(0,0);
			video.load(Paths.video(tag), null);
			video.play();
			video.kill();
		});
		Lua_helper.add_callback(lua, "makeVideoSprite", function(tag:String, videoName:String, ?x:Float, ?y:Float, ?camera:String, ?looped:Bool){
			var video = new FlxVideoSprite(0,0);
			video.load(Paths.video(videoName), null);
			video.play();
			video.kill();
		});
		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
			LoadingState.imagesToPrepare.push(image);
		});
		Lua_helper.add_callback(lua, "makeLuaBackdrop", function(tag:String, image:String, x:Float, y:Float, axis:String = 'xy', xSpacing:Int = 0, ySpacing:Int = 0) {
			LoadingState.imagesToPrepare.push(image);
		});
		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow") {
			LoadingState.imagesToPrepare.push(image);
		});

		addLocalCallback("close", function() {
			closed = true;
			return closed;
		});

		// Empty callbacks to prevent code stopping
		Lua_helper.add_callback(lua, "setProperty", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "setScrollFactor", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "scaleObject", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "addLuaSprite", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "playAnim", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "initLuaShader", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "setSpriteShader", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "setShaderFloat", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "runHaxeCode", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "runTimer", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "setObjectCamera", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "callMethod", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "callMethodFromClass", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "cameraFlash", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "getRandomBool", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "getRandomInt", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "getRandomFloat", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "setHealth", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "setBlendMode", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "addHealth", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "getHealth", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});
		Lua_helper.add_callback(lua, "makeLuaCharacter", function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic) {});

		try{
			if (!isString) isString = !FileSystem.exists(scriptName);
			var result:Dynamic = null;
			if(!isString)
				result = LuaL.dofile(lua, scriptName);
			else
				result = LuaL.dostring(lua, scriptName);

			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				lua = null;
				return;
			}
			if(isString) scriptName = 'unknown';
		} catch(e:Dynamic) {
			return;
		}
		call('onCreate', []);
		call('onCreatePost', []);
	}

	//main
	public var lastCalledFunction:String = '';
	public static var lastCalledScript:LoadingLua = null;
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		if(closed) return LuaUtils.Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try {
			if(lua == null) return LuaUtils.Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				Lua.pop(lua, 1);
				return LuaUtils.Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				return LuaUtils.Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = LuaUtils.Function_Continue;

			Lua.pop(lua, 1);
			if(closed) stop();
			return result;
		}
		catch (e:Dynamic) {
		}
		return LuaUtils.Function_Continue;
	}

	public function set(variable:String, data:Dynamic) {
		if(lua == null) {
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
	}

	public function stop() {
		closed = true;

		if(lua == null) {
			return;
		}
		Lua.close(lua);
		lua = null;
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); //just so that it gets called
	}
}
#end