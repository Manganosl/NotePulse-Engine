package states.base;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import backend.PsychCamera;
import flixel.FlxState;
import hscript.Parser;
import hscript.Interp;
import sys.io.File;
import haxe.io.Path;
import psychlua.HScript;
import psychlua.LuaUtils;
import psychlua.FunkinLua;
import backend.Paths;
import tea.SScript;
import debug.CodenameBuildField;
import psychlua.HScript;

class MusicBeatState extends FlxUIState
{
	public static var globalScript:HScript = null;
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	public var sscriptArray:Array<HScript> = [];

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	function startGlobalScript(){
		try
		{
			var isCode:Bool = false;
			var input:String = Paths.mods('${Mods.currentModDirectory}/Global.hx');
			var newScript:HScript = new HScript(null, Paths.mods('${Mods.currentModDirectory}/Global.hx'));

			if (newScript.parsingException != null)
			{
				trace('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return null;
			}

			sscriptArray.push(newScript);

			if (newScript.exists('onGlobal'))
			{
				var callValue = newScript.call('onGlobal');
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if (len <= 0) len = e.message.length;
							trace('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
						}
					}

					newScript.destroy();
					sscriptArray.remove(newScript);
					trace('failed to initialize hscript!!! (${isCode ? "code string" : input})', FlxColor.RED);
					return null;
				}
				else
				{
					trace('initialized hscript successfully: ${isCode ? "code string" : input}', FlxColor.GREEN);
				}
			}
			globalScript = newScript;
			return newScript;
		}
		catch (e:Dynamic)
		{
			var msg:String = Std.is(e, String) ? (e:Dynamic) : (e.message != null ? e.message : 'Unknown HScript error');
			trace('HScript error: ' + msg, FlxColor.RED);

			var input:String = Paths.mods('${Mods.currentModDirectory}/Global.hx');
			var newScript:HScript = cast (SScript.global.get(input), HScript);
			if (newScript != null)
			{
				newScript.destroy();
				sscriptArray.remove(newScript);
			}

			return null;
		}
	}

	public function initSScript(input:String, ?isCode:Bool = false):HScript
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

			sscriptArray.push(newScript);

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
							addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
						}
					}

					newScript.destroy();
					sscriptArray.remove(newScript);
					addTextToDebug('failed to initialize hscript!!! (${isCode ? "code string" : input})', FlxColor.RED);
					return null;
				}
				else
				{
					addTextToDebug('initialized hscript successfully: ${isCode ? "code string" : input}', FlxColor.GREEN);
				}
			}

			return newScript;
		}
		catch (e:Dynamic)
		{
			var msg:String = Std.is(e, String) ? (e:Dynamic) : (e.message != null ? e.message : 'Unknown HScript error');
			addTextToDebug('HScript error: ' + msg, FlxColor.RED);

			var newScript:HScript = cast (SScript.global.get(input), HScript);
			if (newScript != null)
			{
				newScript.destroy();
				sscriptArray.remove(newScript);
			}

			return null;
		}
	}

	public function callOnSScript(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?exclusions:Array<String> = null, ?excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if (args == null) args = [];
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		#if HSCRIPT_ALLOWED
		var len:Int = sscriptArray.length;
		if (len < 1)
			return returnVal;

		for (i in 0...len)
		{
			var script:HScript = sscriptArray[i];
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			try
			{
				var callValue = script.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
					{
						var elen:Int = e.message.indexOf('\n') + 1;
						if (elen <= 0) elen = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, elen), FlxColor.RED);
					}
					continue;
				}

				var myValue:Dynamic = callValue.returnValue;

				if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if (myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
			catch (err:Dynamic)
			{
				var msg:String = (err != null && err.message != null) ? err.message : Std.string(err);
				var elen:Int = msg.indexOf('\n') + 1;
				if (elen <= 0) elen = msg.length;
				addTextToDebug('Exception calling ${funcToCall} on hscript: ' + msg.substr(0, elen), FlxColor.RED);
			}
		}
		#end

		return returnVal;
	}

	var _psychCameraInitialized:Bool = false;

	override function destroy() {
		super.destroy();
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	override function create() {

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		if(luaDebugGroup == null){
			luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
			luaDebugGroup.cameras = FlxG.cameras.list;
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

		if (debug.Framerate != null){
			if (Type.getClassName(Type.getClass(FlxG.state)) == "states.MainMenuState"){
				if (debug.Framerate.offset.y != 110)
					FlxTween.tween(debug.Framerate.offset, {y: 110}, 1, {ease: FlxEase.cubeInOut});
			} else if (Type.getClassName(Type.getClass(FlxG.state)) == "options.OptionsState" || Type.getClassName(Type.getClass(FlxG.state)) == "states.FreeplayState"){
				if (debug.Framerate.offset.y != 90)
					FlxTween.tween(debug.Framerate.offset, {y: 90}, 1, {ease: FlxEase.cubeInOut});
			} else if (debug.Framerate.offset.y != 2){
				FlxTween.tween(debug.Framerate.offset, {y: 2}, 1, {ease: FlxEase.cubeInOut});
			}
		}
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
		if(globalScript != null){
			if(!sscriptArray.contains(globalScript))
				sscriptArray.push(globalScript);
		}
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

		callOnSScript('onUpdate', [elapsed], false, null, null);

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		callOnSScript('onUpdatePost', [elapsed], false, null, null);

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

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
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
}
