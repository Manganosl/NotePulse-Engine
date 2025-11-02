package states.scripted;

import flixel.util.FlxColor;
import psychlua.HScript;
import psychlua.LuaUtils;
import tea.SScript;
import flixel.addons.display.FlxRuntimeShader;
import flixel.text.FlxText;
import flixel.FlxG;
import backend.CustomFadeTransition;
import sys.io.File;

class ScriptedState extends MusicBeatState
{
	public var hscript:HScript = null;
	private var initialScriptPath:String;
	private var initialScriptIsCode:Bool = false;
	private var initialScriptOrigin:String = null;
	public static var instance:ScriptedState;

	private var softlocked:Bool = false;

	public function new(?scriptPath:String = null, ?isCode:Bool = false)
	{
		instance = this;
		super();
		this.initialScriptPath = scriptPath;
		this.initialScriptIsCode = isCode;
	}

	override public function create():Void
	{
		stagesFunc(function(stage:BaseStage) stage.createPost());
		super.create();

		if (initialScriptPath != null)
		{
			startHScript(initialScriptPath);
			if (hscript != null)
				initialScriptOrigin = hscript.origin;
		}

		var fix:backend.CustomFadeTransition = new backend.CustomFadeTransition(0.6, false);
		backend.CustomFadeTransition.finishCallback = function(){
			backend.CustomFadeTransition.dont = true;
		}
		if (hscript != null)
			callOnSScript('onCreatePost');
	}

	public function startHScript(scriptToLoad:String):Bool
	{
		if (FileSystem.exists(scriptToLoad))
		{
			hscript = initSScript(scriptToLoad, false);
			if (hscript == null){
				softlocked = true;
				var errorText = new FlxText(0, FlxG.height / 2 - 10, FlxG.width, "Error while loading Script:\n" + scriptToLoad + "\n\nPress SPACE to go back to Main Menu");
				errorText.setFormat(null, 16, FlxColor.RED, "center");
				add(errorText);
			}
			return hscript != null;
		}

		softlocked = true;
		var errorText = new FlxText(0, FlxG.height / 2 - 10, FlxG.width, "Error: Script does not exist:\n" + scriptToLoad + "\n\nPress SPACE to go back to Main Menu");
		errorText.setFormat(null, 16, FlxColor.RED, "center");
		add(errorText);
		return false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (softlocked)
		{
			if (FlxG.keys.justPressed.SPACE)
				MusicBeatState.switchState(new states.MainMenuState());
			return;
		}
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			trace('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		var daShader:FlxRuntimeShader = new FlxRuntimeShader(arr[0], arr[1]);
		return daShader;
		#else
		trace("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			trace('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			trace('Missing shader $name .frag AND .vert files!');
			#end
		#else
		trace('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end

	override public function destroy():Void
	{
		callOnSScript('onDestroy');

		if (sscriptArray != null)
		{
			for (s in sscriptArray)
			{
				if (s != null) s.destroy();
			}
			sscriptArray = [];
		}
		hscript = null;

		super.destroy();
	}
}
