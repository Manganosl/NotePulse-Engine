package funkin.states.base;

import funkin.states.scripted.ScriptedState;
import flixel.FlxState;
import funkin.states.scripted.ScriptedState;
import flixel.addons.transition.FlxTransitionableState;
import sys.io.File;
import haxe.io.Path;
import funkin.scripting.LuaUtils;
import funkin.scripting.lua.FunkinLua;
import funkin.scripting.FunkinScript;
import funkin.scripting.ScriptPack;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
#end

import funkin.game.shaders.CustomShader;

class MusicBeatState extends FlxTransitionableState
{
	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public static var globalScript:FunkinScript = null;
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	#if HSCRIPT_ALLOWED
	public var scriptPack:ScriptPack = new ScriptPack("MusicBeatState");

	public var hscriptArray(get, never):Array<FunkinScript>; // To keep compatibility or something like that
	function get_hscriptArray():Array<FunkinScript> return scriptPack.scripts;
	public var instancesExclude:Array<String> = [];

	/**
	 * If `true` will load a HScript file called like the state in mod/states
	 */
	public var autoStateScripts:Bool = true;
	public var stateScriptName:String = null;

	var _autoScripts:Array<FunkinScript> = [];
	var _autoScriptsLoaded:Bool = false;
	var _autoScriptsPosted:Bool = false;
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
		#if HSCRIPT_ALLOWED
		scriptPack.destroy();
		_autoScripts = [];
		#end

		super.destroy();
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor, ?doTrace:Bool = false, ?type:String) {
		Main.traces?.displayLog(text, color, 15);

		if(doTrace){
			if(type == "trace" || type == null) trace(text);
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

	/**
	 * Creates a script from a file
	 * @return The script
	 */
	public function initHScript(file:String):Null<FunkinScript> {
		return scriptPack.add(new FunkinScript(file));
	}
	#end

	/**
	 * Calls a function on the state's scriptPack
	 * Kept this just in case some mod uses it, its better to just make the call on the scriptPack directly
	 */
	public function callOnHScript(event:String, args:Array<Dynamic>, ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		#if HSCRIPT_ALLOWED
		return scriptPack.call(event, args, ignoreStops, exclusions, excludeValues);
		#else
		return LuaUtils.Function_Continue;
		#end
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

	#if HSCRIPT_ALLOWED
	function stateScriptsEnabled():Bool {
		return autoStateScripts && !(this is PlayState) && !(this is ScriptedState) && !(this is funkin.states.handlers.CrashHandlerState);
	}

	function loadStateScripts():Void {
		if(_autoScriptsLoaded) return;
		_autoScriptsLoaded = true;
		if(!stateScriptsEnabled()) return;

		var name:String = (stateScriptName != null ? stateScriptName : Type.getClassName(Type.getClass(this)).split(".").pop());
		var path:String = Paths.modState(name);
		if(!FileSystem.exists(path)) return;

		var script = scriptPack.add(new FunkinScript(path, this));
		if(script != null) _autoScripts.push(script);
	}

	inline function callStateScripts(func:String, ?args:Array<Dynamic>):Void {
		if(_autoScripts.length > 0) callOnHScript(func, args == null ? [] : args, true);
	}
	#end

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		#if HSCRIPT_ALLOWED loadStateScripts(); #end

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
		#if HSCRIPT_ALLOWED
		loadStateScripts();
		if(!_autoScriptsPosted) {
			_autoScriptsPosted = true;
			callStateScripts('onCreatePost');
		}
		callStateScripts('onUpdate', [elapsed]);
		#end

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

		#if HSCRIPT_ALLOWED callStateScripts('onUpdatePost', [elapsed]); #end
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
		if(nextState == FlxG.state){
			resetState();
			return;
		}

		if(Mods.modPack != null){
			if((Mods.modPack.titleState != null && Mods.modPack.titleState != "") && nextState is funkin.states.menus.TitleState)
				nextState = new ScriptedState(Mods.modPack.titleState);
			if((Mods.modPack.mainMenuState != null && Mods.modPack.mainMenuState != "") && nextState is funkin.states.MainMenuState)
				nextState = new ScriptedState(Mods.modPack.mainMenuState);
			if((Mods.modPack.storyMenuState != null && Mods.modPack.storyMenuState != "") && nextState is funkin.states.menus.StoryMenuState)
				nextState = new ScriptedState(Mods.modPack.storyMenuState);
			if((Mods.modPack.freeplayMenuState != null && Mods.modPack.freeplayMenuState != "") && nextState is funkin.states.menus.FreeplayState)
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

		#if HSCRIPT_ALLOWED callStateScripts('onStepHit', [curStep]); #end

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

		#if HSCRIPT_ALLOWED callStateScripts('onBeatHit', [curBeat]); #end
	}

	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});

		#if HSCRIPT_ALLOWED callStateScripts('onSectionHit', [curSection]); #end
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
		var script = scriptPack.importScript(path, absolute);
		if(script == null) {
			FunkinLua.luaTrace('importScript: Path "$path" does not exist!', true, false, 0xFFFF0000);
			return false;
		}
		return true;
	}
	#end

	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && sys)
		return new CustomShader(name);
		#else
		Log.error("Platform unsupported for Runtime Shaders!");
		return new FlxRuntimeShader();
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120):Bool
	{
		if(!ClientPrefs.data.shaders) return false;

		if(CustomShader.shaderCache.exists(name)) return true;

		#if (MODS_ALLOWED && !flash && sys)
		var tempShader = new CustomShader(name);
	
		if (CustomShader.shaderCache.exists(name))
			return true;

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
}
