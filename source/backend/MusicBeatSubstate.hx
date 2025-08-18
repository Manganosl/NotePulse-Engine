package backend;

import flixel.FlxSubState;
import psychlua.HScript;
import psychlua.LuaUtils;
import psychlua.FunkinLua;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public var className:String = "";
	public var useCustomStateName:Bool = false;
	public var scriptsAllowed:Bool = true;

	public var menuScriptArray:Array<HScript> = [];
	public function runStateFiles(state:String, checkSpecificScript:Bool = false) {
		if(!scriptsAllowed) return;
		var filesPushed = [];
		for (folder in Paths.getStateScripts(state))
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith((checkSpecificScript ? (state + ".hx") : '.hx')) && !filesPushed.contains(file)) {
						menuScriptArray.push(new HScript(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
	}

	override function destroy() {
		for (sc in menuScriptArray) {
			sc.call("onDestroy", []);
			sc.stop();
		}
		menuScriptArray = [];
		
		super.destroy();
	}

	override function create() {
		runStateFiles((useCustomStateName ? className : Type.getClassName(Type.getClass(this))));

		super.create();
		quickCallMenuScript("onCreatePost", []);
	}

	public function setOnMenuScript(variable:String, arg:Dynamic) {
		if(!scriptsAllowed) return;
		for (i in 0...menuScriptArray.length) {
			menuScriptArray[i].set(variable, arg);
		}
	}
	
	public function quickCallMenuScript(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal = LuaUtils.Function_Continue;
		if(!scriptsAllowed) return returnVal;
		for (sc in menuScriptArray) {
			var myValue = sc.call(event, args);
			if(myValue == LuaUtils.Function_StopLua) break;
			if(myValue != null && myValue != LuaUtils.Function_Continue) returnVal = myValue;
		}
		return returnVal;
	}
	
	public function callOnMenuScript(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = LuaUtils.Function_Continue;
		if(!scriptsAllowed) return returnVal;
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (sc in menuScriptArray) {
			if(exclusions.contains(sc.scriptName)) continue;

			var myValue = sc.call(event, args);
			if(myValue == LuaUtils.Function_StopLua && !ignoreStops) break;
			
			if(myValue != null && myValue != LuaUtils.Function_Continue) returnVal = myValue;
		}
		return returnVal;
	}

	inline function get_controls():Controls
		return Controls.instance;

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
	
	public function sectionHit():Void
	{
		//yep, you guessed it, nothing again, dumbass
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
