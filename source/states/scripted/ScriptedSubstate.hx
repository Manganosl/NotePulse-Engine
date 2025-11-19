package states.scripted;

import flixel.util.FlxColor;
import psychlua.HScript;
import flixel.addons.display.FlxRuntimeShader;
import flixel.text.FlxText;
import flixel.FlxG;
import sys.io.File;

class ScriptedSubstate extends MusicBeatSubstate
{
	public var hscript:HScript = null;
	private var initialScriptPath:String;
	public static var instance:ScriptedSubstate;

	private var softlocked:Bool = false;

	public function new(?scriptPath:String = null, ?isCode:Bool = false)
	{
		instance = this;
		super();
		this.initialScriptPath = scriptPath;
	}

	override public function create():Void
	{
		super.create();

		if (initialScriptPath != null)
		{
			startHScript(initialScriptPath);
		}

		if (hscript != null)
			callOnHScript('onCreatePost');
	}

	public function startHScript(scriptToLoad:String):Bool
	{
		if (FileSystem.exists(scriptToLoad))
		{
			hscript = initHScript(scriptToLoad);
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
		callOnHScript("onUpdate", [elapsed]);

		super.update(elapsed);

		if (softlocked)
		{
			if (FlxG.keys.justPressed.SPACE)
				MusicBeatState.switchState(new states.MainMenuState());
			return;
		}

		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F5)
			MusicBeatState.switchState(new states.MainMenuState());

		callOnHScript("onUpdatePost", [elapsed]);
	}

	override public function destroy():Void
	{
		callOnHScript('onDestroy');

		if (hscriptArray != null)
		{
			for (s in hscriptArray)
			{
				if (s != null) s.stop();
			}
			hscriptArray = [];
		}
		hscript = null;

		super.destroy();
	}
}
