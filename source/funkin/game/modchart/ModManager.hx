// @author Nebula_Zorua

package funkin.game.modchart;

import funkin.scripting.LuaUtils;
import flixel.tweens.FlxEase;
import funkin.game.modchart.events.*;
import funkin.game.modchart.modifiers.*;

// Weird amalgamation of Schmovin' modifier system, Andromeda modifier system and my own new shit -neb
typedef Node = {
	var in_mods:Array<String>;
	var out_mods:Array<String>;
	var nodeFunc:(values:Array<Float>, player:Int) -> Array<Float>;
}

class ModManager {
	public var doTraces:Bool = true;
	public var swapPlayers:Bool = false;

	public var useNormalSustains:Bool = false;  // Some textures have problems with segmented sustains
	public var sustainSegments:Int = 4;

	public function registerDefaultModifiers(){
		var quickRegs:Array<Any> = [
			XModifier,
			FlipModifier,
			ReverseModifier,
			InvertModifier,
			DrunkModifier,
			BeatModifier,
			AlphaModifier,
			ReceptorScrollModifier, 
			RadionicModifier,
			ScaleModifier, 
			SkewModifier, 
			ConfusionModifier, 
			OpponentModifier, 
			TransformModifier, 
			InfinitePathModifier, 
			PerspectiveModifier, 
			SnapModifier,
			SpiralModifier,
			AccelModifier
		];
		for (mod in quickRegs)
			quickRegister(Type.createInstance(mod, [this]));

		quickRegister(new RotateModifier(this));
		quickRegister(new RotateModifier(this, 'center', new Vector3((FlxG.width* 0.5) - (Note.swagWidth/2), (FlxG.height* 0.5) - Note.swagWidth/2)));
		quickRegister(new LocalRotateModifier(this, 'local'));
		quickRegister(new SubModifier("noteSpawnTime", this));
		setValue("noteSpawnTime", 2000);
		setValue("scale", 1);
		setValue("scaleX", 1);
		setValue("scaleY", 1);
		setValue("xmod", 1);
		for(i in 0...PlayState.SONG.mania+1)
			setValue('xmod$i', 1);
	}

	public function registerScriptedModifiers(){
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/modifiers/')){
			for (file in FileSystem.readDirectory(folder)){
				if(file.toLowerCase().endsWith('.hx')){
					quickRegister(new ScriptedModifier(this, folder + file, file));
					if (doTraces)
						Log.info('Registered scripted modifier: $file');
				}
			}
		}
	}

	public var state:Dynamic;
	public var receptors:Array<Array<StrumNote>> = []; // for modifiers to be able to access receptors directly if they need to
	public var timeline:EventTimeline = new EventTimeline();

	public var notemodRegister:Map<String, Modifier> = [];
	public var miscmodRegister:Map<String, Modifier> = [];

	@:deprecated("Unused in place of notemodRegister and miscModRegister")
	public var registerByType:Map<ModifierType, Map<String, Modifier>> = [
        NOTE_MOD => [],
        MISC_MOD => []
    ];

    public var register:Map<String, Modifier> = [];

    public var modArray:Array<Modifier> = [];

    public var activeMods:Array<Array<String>> = [[], []]; // by player

	private var activeModsDirty:Array<Bool> = [false, false];
	private var activeNoteModObjs:Array<Array<Modifier>> = [[], []];

	var aliases:Map<String, String> = [];

	var nodes:Map<String, Array<Node>> = [];
	var nodeArray:Array<Node> = [];
	var touchedMods:Array<Array<String>> = [[], []];

    inline public function quickRegister(mod:Modifier)
        registerMod(mod.getName(), mod);

    public function registerMod(modName:String, mod:Modifier, ?registerSubmods = true){
        modName = modName.toLowerCase();
        mod.lowerCaseName = modName;
        register.set(modName, mod);
		switch (mod.getModType()){
			case NOTE_MOD:
				notemodRegister.set(modName, mod);
			case MISC_MOD:
				miscmodRegister.set(modName, mod);
		}
		timeline.addMod(modName);
		modArray.push(mod);

		for (a => m in mod.getAliases())
			registerAlias(a, m);

		if (registerSubmods){
			for (name in mod.submods.keys())
			{
				var submod = mod.submods.get(name);
				quickRegister(submod);
			}
        }

		setValue(modName, 0); // so if it should execute it gets added Automagically
		modArray.sort((a, b) -> Std.int(a.getOrder() - b.getOrder()));
        // TODO: sort by mod.getOrder()
    }

	inline public function registerAux(name:String)
		quickRegister(new SubModifier(name, this));

	public function registerAlias(alias:String, mod:String)
		aliases.set(alias.toLowerCase(), mod.toLowerCase());

	function getActualModName(m:String):String {
		var norm = m.toLowerCase();
		return aliases.exists(norm) ? aliases.get(norm) : norm;
	}

	public function registerNode(node:Node){
		for (inp in node.in_mods){
			var key = getActualModName(inp);
			if (!nodes.exists(key))
				nodes.set(key, []);
			nodes.get(key).push(node);
		}
		nodeArray.push(node);
	}

	public function quickNode(inputMods:Array<String>, nodeFunc:(values:Array<Float>, player:Int) -> Array<Float>, ?outputMods:Array<String>){
		registerNode({
			in_mods: inputMods,
			out_mods: outputMods ?? [],
			nodeFunc: nodeFunc
		});
	}

	inline public function registerAltNode(mod:String) {
		registerAux(mod + "-a");
		quickNode([mod + "-a"], function(values:Array<Float>, pN:Int) {
			return values;
		}, [mod]);
	}

	public function touchMod(name:String, player:Int)
	{
		if (player < 0) return;

		name = getActualModName(name);
		if (touchedMods[player] == null)
			touchedMods[player] = [];

		if (!touchedMods[player].contains(name))
			touchedMods[player].push(name);
	}

	function runNodes()
	{
		if (nodeArray.length == 0) return;

		for (player => mods in touchedMods){
			if (mods == null) continue;

			var runningNodes:Array<Node> = [];

			for (mod in mods){
				var nodeList = nodes.get(mod);
				if (nodeList == null) continue;
				for (node in nodeList)
					if (!runningNodes.contains(node))
						runningNodes.push(node);
			}

			for (node in runningNodes){
				var input:Array<Float> = [];
				for (mod in node.in_mods)
					input.push(getValue(mod, player));

				var output:Array<Float> = node.nodeFunc(input, player);

				if (node.out_mods.length > 0 && output.length < node.out_mods.length){
					for (i in output.length...node.out_mods.length)
						output.push(node.in_mods.contains(node.out_mods[i]) ? getValue(node.out_mods[i], player) : 0); // If input mods contains the output mod, use the current value, else use 0.
				}

				for (idx in 0...node.out_mods.length){
					var outputValue:Float = output[idx];
					var outputName:String = node.out_mods[idx];
					var outputMod:Modifier = get(outputName);

					if (outputMod == null){
						if (doTraces)
							Log.warn('$outputName is not a valid node output!');
						continue;
					}

					var currentValue = outputMod.getValue(player);

					if (node.in_mods.contains(outputName))
						outputMod.setCurrentValue(outputValue, player);
					else
						outputMod.setCurrentValue(currentValue + outputValue, player);
				}
			}
		}
	}

	private inline function getP(player:Int):Int {
        if (!swapPlayers || (player != 0 && player != 1)) return player;
        return 1 - player;
    }

	inline public function get(modName:String)
		return register.get(getActualModName(modName));
	
	inline public function getPercent(modName:String, player:Int)
		return !register.exists(getActualModName(modName)) ? 0 : get(modName).getPercent(player);

	inline public function getValue(modName:String, player:Int):Float
		return !register.exists(getActualModName(modName)) ? 0 : get(modName).getValue(player);

    inline public function setPercent(modName:String, val:Float, player:Int=-1)
		setValue(modName, val / 100, player);

	inline public function setCurrentPercent(modName:String, val:Float, player:Int = -1)
		setCurrentValue(modName, val / 100, player);

	inline public function getTargetPercent(modName:String, player:Int)
		return !register.exists(getActualModName(modName)) ? 0 : get(modName).getTargetPercent(player);

	inline public function getTargetValue(modName:String, player:Int)
		return !register.exists(getActualModName(modName)) ? 0 : get(modName).getTargetValue(player);

	public function setCurrentValue(modName:String, val:Float, player:Int = -1)
	{
		if (player == -1)
		{
			for (pN => mods in activeMods)
				setCurrentValue(modName, val, pN);
		}
		else
		{
			var daMod = get(modName);
			if (daMod == null)
				return;
			daMod.setCurrentValue(val, player);
		}
	}

	private function flushActiveMods(player:Int){
		if (activeModsDirty[player]){
			activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));

			var objs = activeNoteModObjs[player];
			if (objs == null) { objs = []; activeNoteModObjs[player] = objs; }
			while (objs.length > 0) objs.pop();
			for (name in activeMods[player]){
				var mod = notemodRegister.get(name);
				if (mod != null) objs.push(mod);
			}

			activeModsDirty[player] = false;
		}
	}

	private function shouldKeepParentActive(parent:Modifier, player:Int):Bool {
		if (parent.shouldExecute(player, parent.getValue(player))) return true;
		for (subname => submod in parent.submods){
			if (submod.shouldExecute(player, submod.getValue(player))) return true;
		}
		return false;
	}

	public function setValue(modName:String, val:Float, player:Int=-1){
		player = getP(player);
		if (player == -1)
		{
			for (field in PlayField.fields)
				setValue(modName, val, field.player);
		}
		else
		{
			var daMod = register.get(getActualModName(modName));
			if (daMod == null)
			{
				if (doTraces)
					Log.warn('Tried to set null modifier "$modName"');
				return;
			}
			var mod = daMod.parent == null ? daMod : daMod.parent;
			var name = mod.getName().toLowerCase();
            // optimization shit!! :)
            // thanks 4mbr0s3 for giving an alternative way to do all of this cus andromeda has smth similar in Flexy but like
            // this is a better way to do it
            // (ofc its not EXACTLY what 4mbr0s3 did but.. y'know, it's close to it)

			// so this actually has an issue
			// this doesnt take into account any other submods
			// so if you turn a submod off
			// it turns the parent mod off, too, when it shouldnt
			// so what I need to do is like, check other submods before removing the parent

			if (activeMods[player] == null)
				activeMods[player] = [];

			daMod.setValue(val, player);

			if (!activeMods[player].contains(name) && mod.shouldExecute(player, val)){
				if (daMod.getName().toLowerCase() != name)
					activeMods[player].push(daMod.getName().toLowerCase());
				activeMods[player].push(name);
			} else if (!mod.shouldExecute(player, val)){

				// there is prob a better way to do this
				// i just dont know it
				var modParent = daMod.parent;
				if (modParent == null){
					for (name => mod in daMod.submods)
					{
						modParent = daMod; // because if this gets called at all, there's atleast 1 submod!!
						break;
					}
				}
				if (daMod != modParent)
					activeMods[player].remove(daMod.getName().toLowerCase());
				if (modParent != null){
					if (!shouldKeepParentActive(modParent, player)){
						activeMods[player].remove(modParent.getName().toLowerCase());
					}
				} else
					activeMods[player].remove(daMod.getName().toLowerCase());
			}

			activeModsDirty[player] = true;
		}
    }

    public function new(daState:Dynamic){
		this.state = daState;
	}

	public function update(elapsed:Float){
		for (pN => mods in activeMods)
			touchedMods[pN] = mods == null ? [] : mods.copy();

		for (mod in modArray)
			if (mod.active && mod.doesUpdate())
			    mod.update(elapsed);

		runNodes();

		for (pN in 0...touchedMods.length)
			touchedMods[pN] = [];
	}

    public function updateTimeline(curStep:Float)
		timeline.update(curStep);

	public function getBaseX(direction:Int, player:Int):Float {
		var obj:StrumNote = PlayField.fields[player].members[direction];
		return obj != null ? obj.x : 0;
	}

	public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int){
		final note:Note = (obj is Note ? cast obj : null);
		final strum:StrumNote = (obj is StrumNote ? cast obj : null);
		
		if(strum != null) strum.modPos.x = (pos.x - obj.width * .5);
		else obj.x = (pos.x - obj.width * .5);
		if(obj is Note && note.isSustainNote)
			obj.x += note.parent.width/2 - note.width + note.offsetX;
		
		if (note != null && note.isSustainNote)
			note.y = pos.y + note.offsetY + (note.strum.y - 50);
		else {
			if(strum != null) strum.modPos.y = (pos.y - obj.height * .5 + strum.y - 50);
			else if (note != null) note.y = (note.offsetY + pos.y - obj.height * .5);
			else obj.y = (pos.y - obj.height * .5);
		}
		
		if (activeMods[player] != null){
			flushActiveMods(player);
			if(obj.active){
				var isNote = obj is Note;
				var isStrum = !isNote && (obj is StrumNote);
				if(isNote || isStrum){
					for (mod in activeNoteModObjs[player]){
						if(isNote) mod.updateNote(beat, cast obj, pos, player);
						else mod.updateReceptor(beat, cast obj, pos, player);
					}
				}
			}
		}
		
		obj.centerOrigin();
		obj.centerOffsets();

		if((obj is Note)){
			var cum:Note = cast obj;
			if (cum.isSustainNote) cum.origin.y = cum.offset.y = 0;
			cum.offset.x += cum.typeOffsetX;
			cum.offset.y += cum.typeOffsetY;
		}
    }

	public inline function getVisPos(songPos:Float=0, strumTime:Float=0, songSpeed:Float=1){
		return -(0.45 * (songPos - strumTime) * songSpeed);
	}
	
	public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:FlxSprite, ?exclusions:Array<String>, ?pos:Vector3):Vector3
	{
		if (pos == null)
			pos = new Vector3();

		if (!obj.active) return pos;

		pos.x = PlayField.fields[player].members[data].x;
		pos.y = PlayField.fields[player].members[data].y + diff;
		pos.z = 0;

		pos.alpha = 1;
		pos.glow = 0;

		if (activeMods[player] != null && obj.active){
			flushActiveMods(player);
			var hasExclusions = exclusions != null && exclusions.length > 0;
			for (mod in activeNoteModObjs[player]){
				if (hasExclusions && exclusions.contains(mod.lowerCaseName)) continue;
				pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
			}
		}
		return pos;
    }

	public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:String = 'linear', player:Int = -1, ?startVal:Float){
		if(player == -1){
			for (field in PlayField.fields)
				queueEase(step, endStep, modName, target, style, field.player);
		} else {
			var easeFunc = FlxEase.linear;
			try {
				var newEase = LuaUtils.getTweenEaseByString(style);
				if (newEase != null)
					easeFunc = newEase;
				else
					if (doTraces)
						Log.warn('Unknown ease style: $style');
			} catch(e) {
				if (doTraces)
					Log.warn('Unknown ease style: $style');
			}
			timeline.addEvent(new ModEaseEvent(step, endStep, modName.toLowerCase(), target, easeFunc, player, this));
		}
	}

	public function queueSet(step:Float, modName:String, target:Float, player:Int = -1){
		if (player == -1){
			for (field in PlayField.fields)
				queueSet(step, modName, target, field.player);
		}
		else
			timeline.addEvent(new SetEvent(step, modName.toLowerCase(), target, player, this));
	}

	public function queueEaseL(step:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
		queueEase(step, step + length, modName, value, style, player, startVal);
	
	public function queueEaseLB(beat:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
		queueEase(beat * 4, (beat + length) * 4, modName, value, style, player, startVal);

	public function queueEaseB(beat:Float, endBeat:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
		queueEase(beat * 4, endBeat * 4, modName, value, style, player, startVal);

	public function queueSetB(beat:Float, modName:String, value:Float, player = -1)
		queueSet(beat * 4, modName, value, player);

	public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:Dynamic = 'linear', player:Int = -1, ?startVal:Float)
		queueEase(step, endStep, modName, percent * 0.01, style, player, startVal * 0.01);
	
	public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1)
		queueSet(step, modName, percent * 0.01, player);

	public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void)
		timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
	
	public function queueFuncL(step:Float, length:Float, callback:(CallbackEvent, Float) -> Void)
		timeline.addEvent(new StepCallbackEvent(step, step + length, callback, this));

	public function queueFuncB(beat:Float, endBeat:Float, callback:(CallbackEvent, Float) -> Void)
		timeline.addEvent(new StepCallbackEvent(beat * 4, endBeat * 4, callback, this));

	public function queueFuncLB(beat:Float, length:Float, callback:(CallbackEvent, Float) -> Void)
		timeline.addEvent(new StepCallbackEvent(beat * 4, (beat + length) * 4, callback, this));

	public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void)
		timeline.addEvent(new CallbackEvent(step, callback, this));
	
	public function queueEaseFunc(step:Float, endStep:Float, func:EaseFunction, callback:(EaseEvent, Float, Float) -> Void)
		timeline.addEvent(new EaseEvent(step, endStep, func, callback, this));

	public function queueEaseFuncL(step:Float, length:Float, func:EaseFunction, callback:(EaseEvent, Float, Float) -> Void)
		timeline.addEvent(new EaseEvent(step, step + length, func, callback, this));

	public function queueEaseFuncB(beat:Float, endBeat:Float, func:EaseFunction, callback:(EaseEvent, Float, Float) -> Void)
		timeline.addEvent(new EaseEvent(beat * 4, endBeat * 4, func, callback, this));

	public function queueEaseFuncLB(beat:Float, length:Float, func:EaseFunction, callback:(EaseEvent, Float, Float) -> Void)
		timeline.addEvent(new EaseEvent(beat * 4, (beat + length) * 4, func, callback, this));

	public function queueEaseProps(step:Float, endStep:Float, object:Dynamic, values:Dynamic, ?options:EasePropertiesEvent.TweenOptions)
		timeline.addEvent(new EasePropertiesEvent(step, endStep - step, object, values, options, this));

	public function queueEasePropsL(step:Float, length:Float, object:Dynamic, values:Dynamic, ?options:EasePropertiesEvent.TweenOptions)
		timeline.addEvent(new EasePropertiesEvent(step, length, object, values, options, this));

	public function queueEasePropsB(beat:Float, endBeat:Float, object:Dynamic, values:Dynamic, ?options:EasePropertiesEvent.TweenOptions)
		timeline.addEvent(new EasePropertiesEvent(beat * 4, (endBeat - beat) * 4, object, values, options, this));

	public function queueEasePropsLB(beat:Float, length:Float, object:Dynamic, values:Dynamic, ?options:EasePropertiesEvent.TweenOptions)
		timeline.addEvent(new EasePropertiesEvent(beat * 4, length * 4, object, values, options, this));

	// FunkinModchart compatibility functions

	public function ease(modName:String, beat:Float, len:Float, val:Float, easeFunc:EaseFunction, player:Int, ?_:Int){
		if(player == -1){
			for (field in PlayField.fields)
				ease(modName, beat, len, val, easeFunc, field.player);
		} else {
			timeline.addEvent(new ModEaseEvent(beat * 4, (beat + len) * 4, modName.toLowerCase(), val, easeFunc, player, this));
		}
	}

	public function set(modName:String, beat:Float, val:Float, player:Int, ?_:Int){
		if(player == -1){
			for (field in PlayField.fields)
				set(modName, beat, val, field.player);
		} else {
			timeline.addEvent(new SetEvent(beat * 4, modName.toLowerCase(), val, player, this));
		}
	}
}
