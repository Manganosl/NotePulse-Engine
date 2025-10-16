package states.scripted;

import flixel.util.FlxColor;
import psychlua.HScript;
import psychlua.LuaUtils;
import tea.SScript;
import flixel.text.FlxText;
import flixel.FlxG;
import backend.CustomFadeTransition;
import sys.io.File;

class ScriptedState extends MusicBeatState
{
	public var hscript:HScript = null;
	public var hscriptArray:Array<HScript> = [];
	private var initialScriptPath:String;
	private var initialScriptIsCode:Bool = false;
	private var initialScriptOrigin:String = null;

	private var softlocked:Bool = false;

	public function new(?scriptPath:String = null, ?isCode:Bool = false)
	{
		super();
		this.initialScriptPath = scriptPath;
		this.initialScriptIsCode = isCode;
	}

	public function daCreate():Void
	{
		callOnHScript('onCreatePost');
	}

	override public function create():Void
	{
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
			daCreate();

	}

	public function startHScript(scriptToLoad:String):Bool
	{
		if (FileSystem.exists(scriptToLoad))
		{
			initHScript(scriptToLoad, false);
			return hscript != null;
		}

		softlocked = true;
		var errorText = new FlxText(0, FlxG.height / 2 - 10, FlxG.width, "Error: Script does not exist:\n" + scriptToLoad + "\n\nPress SPACE to go back to Main Menu");
		errorText.setFormat(null, 16, FlxColor.RED, "center");
		add(errorText);
		return false;
	}

	public function initHScript(input:String, ?isCode:Bool = false):HScript
	{
		try
		{
			var newScript:HScript = null;

			if (isCode)
				newScript = new HScript(input, null);
			else
				newScript = new HScript(null, input);

			if (newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return null;
			}

			hscriptArray.push(newScript);

			if (newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if (len <= 0) len = e.message.length;
							addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
						}
					}

					newScript.destroy();
					hscriptArray.remove(newScript);
					addTextToDebug('failed to initialize hscript!!! (${isCode ? "code string" : input})', FlxColor.RED);
					return null;
				}
				else
				{
					addTextToDebug('initialized hscript successfully: ${isCode ? "code string" : input}', FlxColor.GREEN);
				}
			}

			hscript = newScript;
			return newScript;
		}
		catch (e:Dynamic)
		{
			var msg:String = Std.is(e, String) ? (e:Dynamic) : (e.message != null ? e.message : 'Unknown HScript error');
			addTextToDebug('HScript error: ' + msg, FlxColor.RED);

			var newScript:HScript = cast (SScript.global.get(input), HScript);
			if (newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}

			return null;
		}
	}

	public function callOnHScript(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?exclusions:Array<String> = null, ?excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if (args == null) args = [];
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		#if HSCRIPT_ALLOWED
		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for (i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			try
			{
				var callValue = script.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
					{
						var elen:Int = e.message.indexOf('\n') + 1;
						if (elen <= 0) elen = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, elen), FlxColor.RED);
					}
					continue;
				}

				var myValue:Dynamic = callValue.returnValue;

				if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if (myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
			catch (err:Dynamic)
			{
				var msg:String = (err != null && err.message != null) ? err.message : Std.string(err);
				var elen:Int = msg.indexOf('\n') + 1;
				if (elen <= 0) elen = msg.length;
				addTextToDebug('Exception calling ${funcToCall} on hscript: ' + msg.substr(0, elen), FlxColor.RED);
			}
		}
		#end

		return returnVal;
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

		callOnHScript('onUpdate', [elapsed], false, null, null);
		callOnHScript('onUpdatePost', [elapsed], false, null, null);
	}

	override public function destroy():Void
	{
		callOnHScript('onDestroy');

		if (hscriptArray != null)
		{
			for (s in hscriptArray)
			{
				if (s != null) s.destroy();
			}
			hscriptArray = [];
		}
		hscript = null;

		super.destroy();
	}
}
