package states.scripted;

import flixel.util.FlxColor;
import psychlua.HScript;
import tea.SScript;

class ScriptedState extends MusicBeatState
{
	public var hscript:HScript = null;
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
			return true;
		}

		softlocked = true;
		var errorText = new flixel.text.FlxText(0, FlxG.height / 2 - 10, FlxG.width, "Error: Script does not exist:\n" + scriptToLoad + "\n\nPress SPACE to go back to Main Menu");
		errorText.setFormat(null, 16, FlxColor.RED, "center");
		add(errorText);
		return false;
	}

	public function initHScript(input:String, ?isCode:Bool = false):HScript
	{
		try
		{
			hscript = new HScript(null, input);
			if (hscript.parsingException != null)
			{
				hscript.destroy();
				hscript = null;
				return null;
			}

			if (hscript.exists('onCreate'))
			{
				var callValue = hscript.call('onCreate');
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					hscript.destroy();
					hscript = null;
					return null;
				}
			}

			return hscript;
		}
		catch (e:Dynamic)
		{
			if (hscript != null) hscript.destroy();
			hscript = null;
			return null;
		}
	}

	private function callOnHScript(funcToCall:String, ?args:Array<Dynamic> = null):Void
	{
		if (hscript == null) return;

		try{hscript.call(funcToCall, args);} catch(e:Dynamic){}
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

		callOnHScript('onUpdate', [elapsed]);
		callOnHScript('onUpdatePost', [elapsed]);
	}

	override public function destroy():Void
	{
		callOnHScript('onDestroy');

		if (hscript != null)
		{
			hscript.destroy();
			hscript = null;
		}

		super.destroy();
	}
}
