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
