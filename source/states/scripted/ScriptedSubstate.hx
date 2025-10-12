package states.scripted;

import flixel.util.FlxColor;
import psychlua.HScript;
import psychlua.LuaUtils;
import tea.SScript;

class ScriptedSubstate extends MusicBeatSubstate
{
	public var hscriptArray:Array<HScript> = new Array<HScript>();
	private var initialScriptPath:String;
	private var initialScriptIsCode:Bool = false;
	private var initialScriptOrigin:String = null;

	public function new(?scriptPath:String = null, ?isCode:Bool = false)
	{
		super();
		this.initialScriptPath = scriptPath;
		this.initialScriptIsCode = isCode;
	}

	override public function create():Void
	{
		super.create();
		if (initialScriptPath != null)
		{
			startHScriptsNamed(initialScriptPath);
			if (hscriptArray.length > 0)
			{
				var s:HScript = hscriptArray[hscriptArray.length - 1];
				if (s != null) initialScriptOrigin = s.origin;
			}
		}
	}

	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;
			initHScript(scriptToLoad, false);
			return true;
		}
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
			var origin:String = newScript.origin;

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
							addTextToDebug('ERROR (${isCode ? "code string" : input}: onCreate) - ${e.message.substr(0, len)}', FlxColor.RED);
						}
					}
					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize hscript!!! (${isCode ? "code string" : input})');
					return null;
				}
				else
				{
					trace('initialized hscript successfully: ${isCode ? "code string" : input}');
				}
			}

			return newScript;
		}
		catch(e)
		{
			var len:Int = e.message.indexOf('\n') + 1;
			if(len <= 0) len = e.message.length;
			addTextToDebug('ERROR - ' + e.message.substr(0, len), FlxColor.RED);

			var existing:HScript = cast (SScript.global.get(input), HScript);
			if (existing != null)
			{
				existing.destroy();
				hscriptArray.remove(existing);
			}
			return null;
		}
	}

	private function callOnHScriptForOrigin(origin:String, funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		var len:Int = hscriptArray.length;
		if (len < 1) return returnVal;

		for(i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if (script == null || !script.exists(funcToCall)) continue;
			if (origin != null && script.origin != origin) continue;

			try
			{
				var callValue = script.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
					{
						var l:Int = e.message.indexOf('\n') + 1;
						if (l <= 0) l = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, l), FlxColor.RED);
					}
				}
				else
				{
					var myValue:Dynamic = callValue.returnValue;
					if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}
					if (myValue != null) returnVal = myValue;
				}
			}
			catch(e)
			{
				var l:Int = e.message.indexOf('\n') + 1;
				if (l <= 0) l = e.message.length;
				addTextToDebug('ERROR - ' + e.message.substr(0, l), FlxColor.RED);
			}
		}
		#end

		return returnVal;
	}

	override public function update(elapsed:Float):Void
	{
		if (initialScriptOrigin != null)
			callOnHScriptForOrigin(initialScriptOrigin, 'onUpdate', [elapsed]);

		super.update(elapsed);

		if (initialScriptOrigin != null)
			callOnHScriptForOrigin(initialScriptOrigin, 'onUpdatePost', [elapsed]);
	}

	override public function destroy():Void
	{
		if (initialScriptOrigin != null)
			callOnHScriptForOrigin(initialScriptOrigin, 'onDestroy', null, true);

		for (script in hscriptArray)
		{
			if (script != null) script.destroy();
		}
		hscriptArray = new Array<HScript>();

		super.destroy();
	}

	private function addTextToDebug(msg:String, color:Int):Void
	{
		trace(msg);
	}
}
