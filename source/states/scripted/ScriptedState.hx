package states.scripted;

import flixel.util.FlxColor;
import psychlua.HScript;
import psychlua.LuaUtils;
import tea.SScript;

class ScriptedState extends MusicBeatState
{
	public var hscriptArray:Array<HScript> = new Array<HScript>();
	private var initialScriptPath:String;
	private var initialScriptIsCode:Bool = false;
	private var initialScriptOrigin:String = null;
	public var newScript:HScript = null;

	private var softlocked:Bool = false;

	public function new(?scriptPath:String = null, ?isCode:Bool = false)
	{
		super();
		this.initialScriptPath = scriptPath;
		this.initialScriptIsCode = isCode;
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

	public function daCreate():Void
	{
		callOnHScript('onCreatePost', null);
	}

	override public function create():Void
	{
		super.create();
	}

	public function startHScriptsNamed(scriptToLoad:String)
	{
		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;
			initHScript(scriptToLoad, false);
			trace("Script exists: "+scriptToLoad);
			return true;
		}
		trace("Script does not exist: "+scriptToLoad);
		softlocked = true;
		var errorText:FlxText = new FlxText(0, FlxG.height / 2 - 10, FlxG.width, "Error: Script does not exist:\n"+scriptToLoad+"\n\nPress space key to go back to the Main Menu");
		add(errorText);
		return false;
	}

	public function initHScript(input:String, ?isCode:Bool = false):HScript
	{
		try
		{
			newScript = new HScript(null, input);

			if (newScript.parsingException != null)
			{
				trace('ERROR ON LOADING: ${newScript.parsingException.message}');
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
							trace('ERROR (${isCode ? "code string" : input}: onCreate) - ${e.message.substr(0, len)}');
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
			
			daCreate();
			return newScript;
		}
		catch(e)
		{
			var len:Int = e.message.indexOf('\n') + 1;
			if(len <= 0) len = e.message.length;
			trace('ERROR - ' + e.message.substr(0, len));

			var existing:HScript = cast (SScript.global.get(input), HScript);
			if (existing != null)
			{
				existing.destroy();
				hscriptArray.remove(existing);
			}
			return null;
		}
	}

	private function callOnHScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		if (newScript.exists(funcToCall))
			{
				trace('calling hscript function: $funcToCall');
				var callValue = newScript.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if (len <= 0) len = e.message.length;
							//trace('ERROR (${isCode ? "code string" : input}: onCreate) - ${e.message.substr(0, len)}');
						}
					}
					newScript.destroy();
					hscriptArray.remove(newScript);
					//trace('failed to initialize hscript!!! (${isCode ? "code string" : input})');
					return null;
				}
				else
				{
					trace('initialized hscript successfully: $funcToCall');
				}
			}
			else
			{
				trace('hscript function does not exist: $funcToCall');
			}

			return newScript;
		};

	override public function update(elapsed:Float):Void
	{
		if(softlocked)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				MusicBeatState.switchState(new states.MainMenuState());
			}
			return;
		}

		super.update(elapsed);

		callOnHScript('onUpdate', [elapsed]);
		callOnHScript('onUpdatePost', [elapsed]);
	}

	override public function destroy():Void
	{
		callOnHScript('onDestroy', null);

		for (script in hscriptArray)
		{
			if (script != null) script.destroy();
		}
		hscriptArray = new Array<HScript>();

		super.destroy();
	}
}
