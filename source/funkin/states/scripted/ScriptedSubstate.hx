package funkin.states.scripted;

import flixel.util.FlxColor;
import funkin.scripting.FunkinScript;
import flixel.addons.display.FlxRuntimeShader;
import flixel.text.FlxText;
import flixel.FlxG;
import sys.io.File;
import flixel.FlxBasic;

class ScriptedSubstate extends MusicBeatSubstate
{
	static var lastScriptPath:String = "";
	public var hscript:FunkinScript = null;
	private var initialScriptPath:String;

	private var softlocked:Bool = false;

	public function new(?scriptPath:String = null){
		super();
		this.initialScriptPath = scriptPath != null ? Paths.modState(scriptPath) : lastScriptPath;
		if(scriptPath != null) lastScriptPath = this.initialScriptPath;
	}

	override public function create():Void
	{
		super.create();

		if (initialScriptPath != null)
			startHScript(initialScriptPath);

		if (hscript != null)
			callOnHScript('onCreatePost');
	}

	public function startHScript(scriptToLoad:String):Bool {
		if (FileSystem.exists(scriptToLoad)){
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

		if(softlocked){
			if(FlxG.keys.justPressed.SPACE)
				MusicBeatState.switchState(new funkin.states.MainMenuState());
			return;
		}

		callOnHScript("onUpdatePost", [elapsed]);
	}

	override public function destroy():Void {
		callOnHScript('onDestroy');
		hscript = null;

		super.destroy();
	}

	#if HSCRIPT_ALLOWED
	override public function insert(pos:Int, obj:flixel.FlxBasic):flixel.FlxBasic {   // Just why...
		super.insert(pos, obj);
		return obj;
	}
	#end
}
