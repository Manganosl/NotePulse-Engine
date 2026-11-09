package funkin.scripting;

import funkin.game.modchart.math.DrawInstruction;
#if HSCRIPT_ALLOWED
import hscript.Expr.Error;
import hscript.Parser;
import hscript.Expr;
import hscript.*;
import haxe.PosInfos;
#end

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.util.FlxColor;
import funkin.scripting.LuaUtils;
import funkin.backend.utils.WindowUtil;
#if LUA_ALLOWED
import llua.Lua;
#end

import funkin.scripting.lua.FunkinLua;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

/*
 * The class that handles haxe scripts. The code was built off some mod's code, so props to them!
 */
using StringTools;
interface HscriptInterface {
    public var scriptName:String;
    public function set(variable:String, data:Dynamic):Void;
    public function call(func:String, args:Array<Dynamic>):Dynamic;
    public function stop():Void;
}

#if HSCRIPT_ALLOWED
class FunkinScript implements HscriptInterface {

	/*
	 * All the classes pre-imported into every haxe script / runHaxeCode.
	 * These variables are free to be edited to allow for custom pre-imported classes.
	 */
    public static var classes:Map<String, Dynamic> = [
		// Haxe classes
		"Math" 						=> Math, 
		"Std" 						=> Std,
		"StringTools" 				=> StringTools,
		"Reflect" 					=> Reflect, 
		'Type' 						=> Type,
		'Date' 						=> Date, 
		'DateTools' 				=> DateTools,
		#if sys
		'Sys' 						=> Sys,
		"File" 						=> sys.io.File,
		"FileSystem" 				=> sys.FileSystem,
		#end

		// OpenFL & Lime classes
		"Assets"					=> openfl.utils.Assets,
		"Application"				=> lime.app.Application,
		"Main" 						=> Main,

		//Flixel Classes
		"FlxG" 						=> flixel.FlxG,
		"FlxSprite" 				=> flixel.FlxSprite,
		"FlxTimer"				 	=> flixel.util.FlxTimer,
		"FlxTween" 					=> flixel.tweens.FlxTween,
		"FlxEase" 					=> flixel.tweens.FlxEase,
		"FlxText" 					=> flixel.text.FlxText,
		"FlxTextBorderStyle" 		=> flixel.text.FlxTextBorderStyle,
		'FlxTextFormatMarkerPair' 	=> flixel.text.FlxTextFormatMarkerPair,
		'FlxTextFormat' 			=> flixel.text.FlxTextFormat,
		"FlxEmitter" 				=> flixel.effects.particles.FlxEmitter,
		"FlxParticle" 				=> flixel.effects.particles.FlxParticle,
		"FlxEmitterMode" 			=> flixel.effects.particles.FlxEmitter.FlxEmitterMode,

		//Friday Night Funkin' Classes
		"PlayState" 				=> funkin.states.PlayState,
		"MusicBeatState" 			=> funkin.states.base.MusicBeatState,
		"MusicBeatSubstate" 		=> funkin.states.base.MusicBeatSubstate,
		"ScriptedState" 			=> funkin.states.scripted.ScriptedState,
		"ScriptedSubstate" 			=> funkin.states.scripted.ScriptedSubstate,
		"GameOverSubstate" 			=> funkin.substates.GameOverSubstate,
		"FunkinSprite"              => funkin.objects.FunkinSprite,
		"Character" 				=> funkin.objects.Character,
		"FunkinVideoSprite"			=> funkin.objects.FunkinVideoSprite,
		"HealthIcon"				=> funkin.objects.HealthIcon,
		"Alphabet"					=> funkin.objects.Alphabet,
		"Note" 						=> funkin.objects.notes.Note,
		"PlayField"					=> funkin.objects.notes.PlayField,
		"MirrorField"				=> funkin.objects.notes.MirrorField,
		"StrumNote"					=> funkin.objects.notes.StrumNote,
		"ClientPrefs" 				=> funkin.data.ClientPrefs,
		"Mods" 						=> funkin.backend.Mods,
		"Conductor" 				=> funkin.backend.Conductor,
		"Paths" 					=> funkin.backend.Paths,
		#if PRETTY_TRACE "Log" 		=> funkin.backend.Log, #end
		"CoolUtil"					=> funkin.backend.utils.CoolUtil,
		"WindowUtil" 				=> funkin.backend.utils.WindowUtil,
		"CameraUtil"				=> funkin.backend.utils.CameraUtil,
		"NdllUtil" 					=> funkin.backend.utils.NdllUtil,
		"CustomShader" 				=> funkin.game.shaders.CustomShader,
		"LuaUtils" 					=> funkin.scripting.LuaUtils,

		// Modcharting Classes
		"ModManager" 				=> funkin.game.modchart.ModManager,
		"SubModifier" 				=> funkin.game.modchart.SubModifier,
		"NoteModifier" 				=> funkin.game.modchart.NoteModifier,
		"ScriptedModifier" 			=> funkin.game.modchart.ScriptedModifier,
		"DrawInstruction"			=> funkin.game.modchart.math.DrawInstruction,
		"EventTimeline" 			=> funkin.game.modchart.EventTimeline,
		"Modifier" 					=> funkin.game.modchart.Modifier,
		"StepCallbackEvent" 		=> funkin.game.modchart.events.StepCallbackEvent,
		"CallbackEvent" 			=> funkin.game.modchart.events.CallbackEvent,
		"ModEvent" 					=> funkin.game.modchart.events.ModEvent,
		"EaseEvent" 				=> funkin.game.modchart.events.EaseEvent,
		"SetEvent" 					=> funkin.game.modchart.events.SetEvent,

		// Away3D
		#if(foxlite && FOXLITE_ALLOWED)
		"FoxScene"					=> foxlite.FoxScene,
		"FoxCamera"					=> foxlite.FoxCamera,
		"FoxModel"					=> foxlite.FoxModel,
		"FoxShader"					=> foxlite.FoxShader,
		"FoxCache"					=> foxlite.FoxCache,
		"FoxDirectionalLight"		=> foxlite.lights.FoxDirectionalLight,
		"FoxDirectionalSound"		=> foxlite.flixel.FoxDirectionalSound,
		"FoxRenderMetrics"			=> foxlite.flixel.FoxRenderMetrics,
		"FoxStencilAction"			=> foxlite.stencil.FoxStencilAction,
		"FoxMesh"					=> foxlite.mesh.FoxMesh,
		"FoxQuadMesh"				=> foxlite.mesh.FoxQuadMesh,
		"FoxPanoramaSky"			=> foxlite.sky.FoxPanoramaSky,
		"FoxFlxSprite"				=> foxlite.flixel.FoxFlxSprite,
		"FoxFPSCamera"				=> foxlite.extras.FoxFPSCamera,
		"FoxRenderer"				=> foxlite.renderer.FoxRenderer,
		"FoxLoaderUtil"				=> foxlite.loaders.FoxLoaderUtil,
		"FoxMaterial"				=> foxlite.material.FoxMaterial,
		"FoxTexture"				=> foxlite.texture.FoxTexture,
		#end

		//Extras
		"Json" 						=> { //Using the base Json library produces a null function pointer
			parse: function(txt:String):Dynamic { return haxe.Json.parse(txt); },
			stringify: function(value:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String) { return haxe.Json.stringify(value, replacer, space); }
		},
		"FlxTextAlign" 				=> { // Same for this
			LEFT: flixel.text.FlxTextAlign.LEFT,
			CENTER: flixel.text.FlxTextAlign.CENTER,
			RIGHT: flixel.text.FlxTextAlign.RIGHT,
			JUSTIFY: flixel.text.FlxTextAlign.JUSTIFY
		},
		"FlxBasic" 					=> flixel.FlxBasic,
		"FlxCamera" 				=> flixel.FlxCamera,
		"FlxMath" 					=> flixel.math.FlxMath,
		"FlxGroup" 					=> flixel.group.FlxGroup,
		"FlxTypedGroup" 			=> flixel.group.FlxGroup.FlxTypedGroup,
		"FlxSpriteGroup"	 		=> flixel.group.FlxSpriteGroup,
		"FlxSound" 					=> #if(flixel >= "5.3.0") flixel.sound.FlxSound #else flixel.system.FlxSound #end,
		#if !flash 
		"FlxRuntimeShader" 			=> flixel.addons.display.FlxRuntimeShader, 
		#end
		"ShaderFilter"				=> openfl.filters.ShaderFilter,

		"FlxAnimate"                => animate.FlxAnimate,

		//Abstracts
		"FlxPoint" 					=> LuaUtils.getMacroAbstractClass("flixel.math.FlxPoint"),
		"FlxAxes" 					=> LuaUtils.getMacroAbstractClass("flixel.util.FlxAxes"),
		"FlxColor" 					=> LuaUtils.getMacroAbstractClass("flixel.util.FlxColor"),
		"FlxKey"		 			=> LuaUtils.getMacroAbstractClass("flixel.input.keyboard.FlxKey"),
		'BlendMode' 				=> LuaUtils.getMacroAbstractClass("openfl.display.BlendMode")
    ];

	/*
	 * All of the variables set by using `static var`. These variables can be accessed by all scripts.
	 * (Note: Be sure to clear this map on mod change to prevent any other mods from using your vars)
	 */
	public static var staticVariables:Map<String, Dynamic> = [];

    public var parser:Parser;
    public var interp:Interp;
    public var expr:Expr;

	public var variables(get, never):Map<String, Dynamic>;
	public function get_variables() return interp.variables;

    public var scriptName:String;
	public var modFolder:Null<String>;

	//Scripts attached to this script. You can make some goofy chains with this.
	public var subScripts:Array<funkin.scripting.FunkinScript> = [];

	// True when theres an error with the script
	public var isDummy:Bool = false;

	// True after load()
	public var loaded(default, null):Bool = false;

	// I thought this would be cool
	public static final SCRIPT_EXTENSIONS:Array<String> = ["hx", "hscript", "hsc", "hxs"];

	var parentObject:Dynamic = null;
	var ignoreScriptErrors:Bool = false;
	var _importedPaths:Array<String> = [];
	var _lastCallErrors:Map<String, String> = [];

	static var _redirectsInitialized:Bool = false;

	/**
	 * Creates a new haxe script instance that runs interpreted haxe code.
	 *
	 * @param path			The path to the haxe script.
	 *							NOTE: This does not support direct code strings. See the
	 *							`HaxeFunctions` class for a version supporting code strings.
	 * @param _parentClass	The parent state instance this script will be assigned to. 
	 * @param _autoRunScript	(This is used internally by `HaxeFunctions` and is not recommened to use)
	 * @param _ignoreErrors	Whether the script should ignore the critical error popup if an error is found.
	 * @param _autoLoad		Whether the script should be executed right after being parsed.
	 */
    public function new(path:String, ?_parentClass:Dynamic = null, ?_autoRunScript:Bool = true, ?_ignoreErrors:Bool = false, ?_autoLoad:Bool = true) {
		if(!_autoRunScript) return;

		if(!_redirectsInitialized) {
			_redirectsInitialized = true;
			redirectImports(getDefaultImportRedirects());
		}

        if(parser == null) initParser();
		if(interp == null) initInterp();
        scriptName = path;
		parentObject = _parentClass;
		ignoreScriptErrors = _ignoreErrors;

		#if MODS_ALLOWED
		if(scriptName != null && scriptName.length > 0){
			var myFolder:Array<String> = scriptName.trim().split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
		}
		#end

		parseFile();
		if(_autoLoad) load();
	}

	static inline function fileExists(path:String):Bool
		return #if sys FileSystem.exists(path) #else Assets.exists(path) #end;

	static inline function readFile(path:String):String
		return #if sys File.getContent(path) #else Assets.getText(path) #end;

	function parseFile():Void {
		if(scriptName == null || scriptName.length < 1 || !fileExists(scriptName)) {
			isDummy = true;
			Log.error('Script "$scriptName" does not exist!');
			return;
		}

		try {
			parser.line = 1; //Reset the parser position.
			expr = parser.parseString(readFile(scriptName), scriptName);
		} catch(e) {
			handleLoadError(e);
		}
	}

	public function load():Void {
		if(loaded || isDummy || expr == null || interp == null) return;
		loaded = true;

		try {
			interp.variables.set("this", this);
			for(varToBring => val in classes) interp.variables.set(varToBring, val);

			this.setParent((parentObject != null ? parentObject : LuaUtils.getHScriptParent()));
			addHScriptExtras(this.interp, LuaUtils.isPlayStateScript(interp.scriptObject));

			interp.variables.set("getModSetting", function(saveTag:String, ?modName:String = null) {
				if(modName == null) {
					if(this.modFolder == null) {
						Log.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!');
						return null;
					}
					modName = this.modFolder;
				}
				return LuaUtils.getModSetting(saveTag, modName);
			});

			expr = stripScriptMetadata(expr);
			interp.execute(expr);
			call("onCreate", []);
		} catch(e) {
			handleLoadError(e);
		}
	}

	function handleLoadError(e:Dynamic):Void {
		if(!ignoreScriptErrors) FlxG.stage.window.alert('Error on haxe script.\n${Std.string(e)}', 'Error on Haxe Script!');
		else Log.error('[$scriptName] Error on haxe script: ${Std.string(e)}');
	}

	/**
	 * Hot-reloads the script
	 * @return `false` if the script can't be reloaded
	 */
	public function reload():Bool {
		if(isDummy || scriptName == null) return false;

		var saved:Map<String, Dynamic> = [];
		var oldParent:Dynamic = parentObject;
		if(interp != null) {
			oldParent = interp.scriptObject;
			for(k => v in interp.variables)
				if(!Reflect.isFunction(v)) saved.set(k, v);
		}

		stopSubScripts();
		expr = null;
		loaded = false;
		_librariesAllowed = true;
		_importedPaths = [];
		_lastCallErrors = [];
		parentObject = oldParent;

		initParser();
		initInterp();
		interp.allowStaticVariables = interp.allowPublicVariables = false;

		parseFile();
		load();

		if(interp != null) {
			for(k => v in saved) interp.variables.set(k, v);
			interp.allowStaticVariables = interp.allowPublicVariables = true;
		}

		return true;
	}

	public static function addHScriptExtras(obj:Interp, isPlayState:Bool = false) {
		if(obj == null) return;

		if(isPlayState) {
			obj.variables.set("game", PlayState.instance); //runHaxeCode moment
			obj.variables.set("add", function(basic:FlxBasic, ?frontOfChars:Bool = false) {
				if (frontOfChars) {
					PlayState.instance.add(basic);
					return;
				}

				var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
				if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
				else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);

				PlayState.instance.insert(position, basic);
			});

			obj.variables.set('insert', PlayState.instance.insert);
			obj.variables.set('remove', PlayState.instance.remove);
			obj.variables.set('addBehindGF', PlayState.instance.addBehindGF);
			obj.variables.set('addBehindDad', PlayState.instance.addBehindDad);
			obj.variables.set('addBehindBF', PlayState.instance.addBehindBF);
			obj.variables.set('setVar', function(name:String, value:Dynamic) {
				PlayState.instance.variables.set(name, value);
				return value;
			});
			obj.variables.set('getVar', function(name:String) {
				var result:Dynamic = null;
				if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
				return result;
			});
			obj.variables.set('removeVar', function(name:String) {
				if(PlayState.instance.variables.exists(name)) {
					PlayState.instance.variables.remove(name);
					return true;
				}
				return false;
			});

			obj.variables.set('customSubstate', CustomSubstate.instance);
			obj.variables.set('customSubstateName', CustomSubstate.name);
		} else {
			obj.variables.set("game", obj.scriptObject);
			obj.variables.set('add', obj.scriptObject.add);
			obj.variables.set('insert', obj.scriptObject.insert);
			obj.variables.set('remove', obj.scriptObject.remove);

			if(obj.scriptObject.variables != null) {
				obj.variables.set('setVar', function(name:String, value:Dynamic) {
					obj.scriptObject.variables.set(name, value);
					return value;
				});
				obj.variables.set('getVar', function(name:String) {
					var result:Dynamic = null;
					if(obj.scriptObject.variables.get(name) != null) result = obj.scriptObject.variables.get(name);
					return result;
				});
				obj.variables.set('removeVar', function(name:String) {
					if(obj.scriptObject.variables.get(name) != null) {
						obj.scriptObject.variables.remove(name);
						return true;
					}
					return false;
				});
			}
		}

		obj.variables.set("controls", Controls.instance);
		obj.variables.set("trace", function(str:String, ?posInf:PosInfos){
			if(posInf == null) posInf = obj.posInfos();
			Log.hxTrace(str, posInf);
		});
		obj.variables.set("window", WindowUtil.getWindow());

		obj.variables.set("Function_Stop", LuaUtils.Function_Stop);
		obj.variables.set("Function_Continue", LuaUtils.Function_Continue);
		obj.variables.set("Function_StopHScript", LuaUtils.Function_StopHScript);
		obj.variables.set("Function_StopLua", LuaUtils.Function_StopLua);
		obj.variables.set("Function_StopAll", LuaUtils.Function_StopAll);

		//TODO: replace this with "$type". This should work for now
		obj.variables.set("__type__", function(target:Dynamic):String {
			return switch(Type.typeof(target)) {
				case TInt: "Int";
				case TFloat: "Float";
				case TBool: "Bool";
				case TObject: "Object";
				case TFunction: "Function";
				case TClass(clsInst): //also houses "String". TODO: Support for scripted classes & enums
					Type.getClassName(clsInst);
				case TEnum(enmInst):
					Type.getEnumName(enmInst);
				case TUnknown: "Unknown";
				default: "Null";
			}
		});

		obj.variables.set("debugPrint", function(text:Dynamic = "", color:FlxColor = null) {
			#if(LUA_ALLOWED || HSCRIPT_ALLOWED)
			if(FlxG.state is PlayState)
				PlayState.instance.addTextToDebug(text, (color == null ? FlxColor.WHITE : color));
			else #end
				Log.hxTrace(text);
		});

		//other variables
		obj.variables.set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		obj.variables.set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		obj.variables.set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		obj.variables.set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		obj.variables.set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
		obj.variables.set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		obj.variables.set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		obj.variables.set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		obj.variables.set('gamepadJustPressed', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		obj.variables.set('gamepadPressed', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		obj.variables.set('gamepadReleased', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		obj.variables.set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_P;
				case 'down': return Controls.instance.NOTE_DOWN_P;
				case 'up': return Controls.instance.NOTE_UP_P;
				case 'right': return Controls.instance.NOTE_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}
			return false;
		});
		obj.variables.set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT;
				case 'down': return Controls.instance.NOTE_DOWN;
				case 'up': return Controls.instance.NOTE_UP;
				case 'right': return Controls.instance.NOTE_RIGHT;
				default: return Controls.instance.pressed(name);
			}
			return false;
		});
		obj.variables.set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_R;
				case 'down': return Controls.instance.NOTE_DOWN_R;
				case 'up': return Controls.instance.NOTE_UP_R;
				case 'right': return Controls.instance.NOTE_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}
			return false;
		});

		obj.variables.set("state", FlxG.state);
		obj.variables.set('buildTarget', LuaUtils.getBuildTarget());
		obj.variables.set("engine", {
			title: openfl.Lib.application.meta["name"],
			file: openfl.Lib.application.meta["file"],
			version: openfl.Lib.application.meta["version"],
			dimensions: {width: 1280, height: 720}
		});

		#if LUA_ALLOWED
		obj.variables.set("createGlobalCallback", function(name:String, func:Dynamic) {
			if(FlxG.state is PlayState) {
				for(script in PlayState.instance.luaArray) {
					if(script != null && script.lua != null && !script.closed) 
						Lua_helper.add_callback(script.lua, name, func);
				}
			}

			FunkinLua.customFunctions.set(name, func);
		});

		obj.variables.set("createCallback", function(name:String, func:Dynamic, ?lua:FunkinLua) {
			if(lua == null) {
				Log.error('createCallback: no script was found or 3rd argument was null!');
				return false;
			}

			lua.addLocalCallback(name, func);
			return true;
		});
		#end
	}

	//CALLBACKS FOR HSCRIPT

	var _librariesAllowed:Bool = true;
	function onImportFailed(cl:Array<String>, classAlias:Null<String>):Bool {
		if(!_librariesAllowed || cl == null || cl.length < 1) return false;

		var scriptPath:Null<String> = findSourceFile(cl.join("/"));
		if(scriptPath == null) return false;
		if(_importedPaths.contains(scriptPath)) return true;
		_importedPaths.push(scriptPath);

		try {
			parser.line = 1;
			var importedExpr:Expr = parser.parseString(readFile(scriptPath), cl.join("/") + ".hx");
			@:privateAccess interp.exprReturn(importedExpr);
		} catch(e) {
			Log.error('Error while importing "${cl.join(".")}" from source/ ${Std.string(e)}');
			return false;
		}

		return true;
	}

	function findSourceFile(relPath:String):Null<String> {
		var folders:Array<String> = [];
		#if MODS_ALLOWED
		if(modFolder != null && modFolder.length > 0) folders.push(modFolder);
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0 && !folders.contains(Mods.currentModDirectory))
			folders.push(Mods.currentModDirectory);
		for(mod in Mods.getGlobalMods())
			if(!folders.contains(mod)) folders.push(mod);
		#end
		if(folders.length < 1) folders.push("");

		for(folder in folders){
			for(ext in SCRIPT_EXTENSIONS) {
				var scriptPath = Paths.getScriptPath('source/$relPath.$ext', folder);
				if(fileExists(scriptPath)) return scriptPath;
			}
		}
		return null;
	}

	/**
	 * Makes `import oldClass;` load `newClass` instead
	 * Being used for the old Psych's packages
	 * @param oldName The old package
	 * @param newName The new package
	 */
	public static function redirectImport(oldName:String, newName:String):Void
		Interp.importRedirects.set(oldName, newName);

	public static function redirectImports(redirects:Map<String, String>):Void {
		if(redirects == null) return;
		for(oldName => newName in redirects) redirectImport(oldName, newName);
	}

	// Should I add more? Probably, but these are the basic ones and I doubt anyone imported something like uh... Idk PsychCamera
	public static function getDefaultImportRedirects():Map<String, String> {
		var redirects:Map<String, String> = [];

		redirects["states.PlayState"] = "funkin.states.PlayState";
		redirects["states.MainMenuState"] = "funkin.states.MainMenuState";
		redirects["states.FreeplayState"] = "funkin.states.menus.FreeplayState";
		redirects["states.StoryMenuState"] = "funkin.states.menus.StoryMenuState";
		redirects["states.TitleState"] = "funkin.states.menus.TitleState";
		redirects["substates.GameOverSubstate"] = "funkin.substates.GameOverSubstate";
		redirects["objects.Character"] = "funkin.objects.Character";
		redirects["objects.Note"] = "funkin.objects.notes.Note";
		redirects["objects.StrumNote"] = "funkin.objects.notes.StrumNote";
		redirects["objects.Alphabet"] = "funkin.objects.Alphabet";
		redirects["objects.HealthIcon"] = "funkin.objects.HealthIcon";
		redirects["backend.ClientPrefs"] = "funkin.data.ClientPrefs";
		redirects["backend.Mods"] = "funkin.backend.Mods";
		redirects["backend.Conductor"] = "funkin.backend.Conductor";
		redirects["backend.Paths"] = "funkin.backend.Paths";
		redirects["backend.CoolUtil"] = "funkin.backend.utils.CoolUtil";
		redirects["backend.MusicBeatState"] = "funkin.states.base.MusicBeatState";
		redirects["backend.MusicBeatSubstate"] = "funkin.states.base.MusicBeatSubstate";
		redirects["psychlua.CustomSubstate"] = "funkin.scripting.CustomSubstate";

		return redirects;
	}

	public static function getErrorMessage( e : Expr.Error ):String {
		var message = switch( #if hscriptPos e.e #else e #end ) {
			case EInvalidChar(c): "Invalid character: '"+(StringTools.isEof(c) ? "EOF (End Of File)" : String.fromCharCode(c))+"' ("+c+")";
			case EUnexpected(s): "Unexpected token: \""+s+"\"";
			case EUnterminatedString: "Unterminated string";
			case EUnterminatedComment: "Unterminated comment";
			case EInvalidPreprocessor(str): "Invalid preprocessor (" + str + ")";
			case EUnknownVariable(v): "Unknown variable: "+v;
			case EInvalidIterator(v): "Invalid iterator: "+v;
			case EInvalidOp(op): "Invalid operator: "+op;
			case EInvalidAccess(f): "Invalid access to field " + f;
			case ECustom(msg): msg;
			case EInvalidClass(cla): "Invalid class: " + cla + " was not found.";
			case EAlreadyExistingClass(cla): 'Custom Class named $cla already exists.';
		};
		return message;
	}

    public static function onHaxeTrace(v:Dynamic, ?interpreter:Interp, ?level:String = "trace") {
		var posInfos = (interpreter != null ? interpreter.posInfos() : {fileName: "hscript", lineNumber: 0, className: null, methodName: null});
		#if PRETTY_TRACE
		switch(level.toLowerCase()) {
			case "error":
				error(v, {fileName: posInfos.fileName, lineNumber: posInfos.lineNumber, className: null, methodName: null});
				MusicBeatState.getState().addTextToDebug(v, FlxColor.RED, false);
				return;
			case "warn":
				warn(v, {fileName: posInfos.fileName, lineNumber: posInfos.lineNumber, className: null, methodName: null});
				MusicBeatState.getState().addTextToDebug(v, FlxColor.YELLOW, false);
				return;
		}
		#end

		Log.hxTrace(Std.string(v), {fileName: posInfos.fileName, lineNumber: posInfos.lineNumber, className: null, methodName: null});
    }

    function onError(e:Error) {
		var splitErr = getErrorMessage(e).split(": ");
		if(splitErr.length > 1)
			MusicBeatState.getState().addTextToDebug(getErrorMessage(e), FlxColor.RED, false);
		else
			MusicBeatState.getState().addTextToDebug(e.origin + ":" + e.line + ": " + getErrorMessage(e), FlxColor.RED, false);
		#if PRETTY_TRACE
		var pos:PosInfos = {fileName: e.origin, lineNumber: e.line, className: null, methodName: null};
		if(splitErr.length > 1)
			error(splitErr.slice(1).join(": "), pos);
		else
			error(getErrorMessage(e), pos);
		#else
		trace(e);
		#end
    }

	function onWarn(e:Error) {
		#if PRETTY_TRACE
		MusicBeatState.getState().addTextToDebug(getErrorMessage(e), FlxColor.YELLOW, false);
		var pos:PosInfos = {fileName: e.origin, lineNumber: e.line, className: null, methodName: null};
		warn(getErrorMessage(e), pos);
		#else
		trace(getErrorMessage(e));
		#end
	}

	//BACKEND FUNCTIONS

	public function setPublicMap(map:Map<String, Dynamic>) {
		if(interp != null) interp.publicVariables = map;
		return this;
	}

	public function setParent(parent:Dynamic) {
		if(interp != null) {
			interp.scriptObject = parent;
			if(parent.variables != null) interp.publicVariables = parent.variables;
		}
		return this;
	}

	public function getScriptParent():Dynamic
		return interp.scriptObject;

	function _includeSubscript(path:String, absolute:Bool = false):Bool {
		var scriptPath = (absolute ? path : Paths.getScriptPath(path, this.modFolder));

		if(fileExists(scriptPath)){
			var hscriptToPush = new FunkinScript(scriptPath, this.getScriptParent(), true, true);
			hscriptToPush.call("onScriptImported", [this]);
			subScripts.push(hscriptToPush);
			return true;
		}

		Log.error('Path "$scriptPath" does not exist!');
		return false;
	}

	public function initParser() {
		parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = parser.allowRegex = true;
		parser.preprocessorValues = LuaUtils.preprocessors;
	}

	public function initInterp() {
		interp = new Interp();
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.staticVariables = staticVariables;
		interp.errorHandler = onError;
		interp.warnHandler = onWarn;
		interp.importFailedCallback = onImportFailed;
	}

	function stripScriptMetadata(e:Expr):Expr {
		#if hscriptPos
		return switch(e.e) {
			case EBlock(exprs):
				{e: EBlock([for (s in exprs) stripScriptMetadata(s)]), pmin: e.pmin, pmax: e.pmax, origin: e.origin, line: e.line};
			case EMeta(name, args, inner):
				if(name == ":bypassAccessor")
					e;
				else if(resolveMetadataTag(name, args))
					{e: EBlock([]), pmin: e.pmin, pmax: e.pmax, origin: e.origin, line: e.line};
				else
					{e: EMeta(name, args, stripScriptMetadata(inner)), pmin: e.pmin, pmax: e.pmax, origin: e.origin, line: e.line}; // unknown tag, keep looking (stacked metadata)
			default:
				e;
		}
		#else
		return switch(e) {
			case EBlock(exprs):
				EBlock([for (s in exprs) stripScriptMetadata(s)]);
			case EMeta(name, args, inner):
				if(name == ":bypassAccessor")
					e;
				else if(resolveMetadataTag(name, args))
					EBlock([]);
				else
					EMeta(name, args, stripScriptMetadata(inner));
			default:
				e;
		}
		#end
	}

	function resolveMetadataTag(name:String, args:Array<Expr>):Bool {
		switch(name) {
			case ":ignoreException": this.parser.resumeErrors = true;
			case ":noDebug": this.interp.errorHandler = (err) -> {};
			case ":noLibraries": this._librariesAllowed = false;
			case ":include": //legacy importScript from older versions
				var _isAbsolute:Bool = false;
				if(args.length > 1) _isAbsolute = switch(#if hscriptPos args[1].e #else args[1] #end) { case EIdent(abs): (abs.trim() == "true"); default: false; }

				switch(#if hscriptPos args[0].e #else args[0] #end) {
					case EConst(CString(scriptPath)): _includeSubscript(Std.string(scriptPath.trim()), _isAbsolute);
					default: //nothing
				}

			default:
				return false;
		}
		return true;
	}

	//SCRIPT CALLBACKS
	function stopSubScripts(){
		for(sub in subScripts) {
			sub.call("onDestroy", []);
			sub.stop();
		}
		subScripts = [];
	}

	public function stop() {
		stopSubScripts();

		expr = null;
		interp = null;
	}

	public function get(name:String):Dynamic
		return (interp != null ? interp.variables.get(name) : null);

	public function set(variable:String, data:Dynamic)
		if(interp != null) interp.variables.set(variable, data);

	public function call(func:String, args:Array<Dynamic>):Dynamic {
		if(interp == null) return null;

		var functionVar = interp.variables.get(func);
		if(functionVar == null || !Reflect.isFunction(functionVar)) return null;

		try {
			return (args != null && args.length > 0) ? Reflect.callMethod(null, functionVar, args) : functionVar();
		} catch(e:Dynamic) {
			var msg:String = Std.string(e);
			if(_lastCallErrors.get(func) != msg) {
				_lastCallErrors.set(func, msg);
				Log.error('[$scriptName] error in $func(): $msg');
			}
			return null;
		}
	}
}

#else

/* Ignore this. It's for if hscript is removed */
class FunkinScript {
	public function new(path:String, ?_parentClass:Dynamic, ?_autoRunScript:Bool, ?_ignoreErrors:Bool, ?_autoLoad:Bool) {
		throw "FunkinScript is not supported on this platform!";
	}
}

#end
