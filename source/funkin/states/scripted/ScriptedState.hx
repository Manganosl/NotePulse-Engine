package funkin.states.scripted;

import funkin.scripting.FunkinScript;

class ScriptedState extends MusicBeatState
{
	static var lastScriptPath:String = "";
	public var hscript:FunkinScript = null;
	private var initialScriptPath:String;
	public static var instance:ScriptedState;

	private var softlocked:Bool = false;

	public function new(?scriptPath:String = null){
		instance = this;
		super();
		this.initialScriptPath = scriptPath != null ? Paths.modState(scriptPath) : lastScriptPath;
		if(scriptPath != null) lastScriptPath = this.initialScriptPath;
	}

	override public function create():Void {
		super.create();
		if(initialScriptPath != null) startHScript(initialScriptPath);

		if(hscript != null) callOnHScript('onCreatePost');
	}

	public function startHScript(scriptToLoad:String):Bool {
		if(FileSystem.exists(scriptToLoad)){
			hscript = initHScript(scriptToLoad);
			if(hscript == null){
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
		if(hscript != null) callOnHScript("onUpdate", [elapsed]);

		super.update(elapsed);

		if(softlocked){
			if(FlxG.keys.justPressed.SPACE){
				Mods.modPack = null;
				funkin.scripting.GlobalHandler.stopGlobalHX();
				MusicBeatState.switchState(new funkin.states.menus.TitleState());
			}
			return;
		}

		if(hscript != null) callOnHScript("onUpdatePost", [elapsed]);
	}

	override public function destroy():Void {
		if(hscript != null) callOnHScript('onDestroy');
		hscript = null;

		super.destroy();
	}

	#if HSCRIPT_ALLOWED
	override public function insert(pos:Int, obj:flixel.FlxBasic):flixel.FlxBasic {   // Just why...
		return super.insert(pos, obj);
	}
	#end
}
