package funkin.states.base;

import funkin.states.scripted.ScriptedState;
import flixel.addons.ui.FlxUIState;
import funkin.states.scripted.ScriptedState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import flixel.FlxState;
import sys.io.File;
import haxe.io.Path;
import funkin.scripting.LuaUtils;
import funkin.scripting.lua.FunkinLua;
import funkin.scripting.HScript;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
#end

class MusicBeatState extends FlxUIState
{
	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public static var globalScript:HScript = null;
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<funkin.scripting.lua.DebugLuaText>;
	#end

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	override function destroy() {
		super.destroy();
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor, ?trace:Bool = false, ?type:String) {
		var newText:funkin.scripting.lua.DebugLuaText = luaDebugGroup.recycle(funkin.scripting.lua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:funkin.scripting.lua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		if(trace){
			if(type == "trace" || type == null) Log.hxTrace(text);
			if(type == "error") error(text);
			if(type == "warn") warn(text);
			if(type == "info") info(text);
		}

	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad)) {
			for (script in hscriptArray)
				if(script.scriptName == scriptToLoad) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String) {
		var newScript = new HScript(file);
		if(newScript != null) hscriptArray.push(newScript);
		return newScript;
	}
	#end

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1) return returnVal;
		for(i in 0...len) {
			var script:HScript = hscriptArray[i];
			if(script == null || exclusions.contains(script.scriptName)) continue;

			var myValue:Dynamic = null;
			try {
				var callValue = script.call(funcToCall, args);
				myValue = callValue;
				if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) {
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.scriptName)) continue;
			if(!instancesExclude.contains(variable)) instancesExclude.push(variable);

			script.set(variable, arg);
		}
		#end
	}

	override function create() {
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		if(luaDebugGroup == null){
			luaDebugGroup = new FlxTypedGroup<funkin.scripting.lua.DebugLuaText>();
			insert(99999999, luaDebugGroup);
		}
		#end

		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.6, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

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

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;


		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

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
		Conductor.curBeat = curBeat = Math.floor(curStep / 4);
		Conductor.curDecBeat = curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		Conductor.curDecStep = curDecStep = lastChange.stepTime + shit;
		Conductor.curStep = curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if(Mods.modPack != null){
			if(Mods.modPack.titleState != null && nextState is funkin.states.menus.TitleState)
				nextState = new ScriptedState(Mods.modPack.titleState);
			if(Mods.modPack.mainMenuState != null && nextState is funkin.states.MainMenuState)
				nextState = new ScriptedState(Mods.modPack.mainMenuState);
			if(Mods.modPack.storyMenuState != null && nextState is funkin.states.menus.StoryMenuState)
				nextState = new ScriptedState(Mods.modPack.storyMenuState);
			if(Mods.modPack.freeplayMenuState != null && nextState is funkin.states.menus.FreeplayState)
				nextState = new ScriptedState(Mods.modPack.freeplayMenuState);
		}
		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	#if HSCRIPT_ALLOWED
	public function importScript(path:String, absolute:Bool = false) {
		var scriptPath = ((Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) ? Paths.mods(Mods.currentModDirectory + '/' + path + (path.endsWith(".hx") ? "" : ".hx")) : Paths.mods(path));
		try {
			this.hscriptArray.push(new HScript((absolute ? path : scriptPath)));
			return true;
		} catch(e) {
			FunkinLua.luaTrace('importScript: Path "${(absolute ? path : scriptPath)}" does not exist!', true, false, 0xFFFF0000);
		}
		return false;
	}
	#end

	#if (!flash && sys)
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			Log.error('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		var daShader:FlxRuntimeShader = new FlxRuntimeShader(arr[0], arr[1]);
		return daShader;
		#else
		Log.error("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			Log.warn('Shader $name was already initialized!');
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
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED, true, "error");
			#else
			Log.error('Missing shader $name .frag AND .vert files!');
			#end
		#else
		Log.error('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end
}
