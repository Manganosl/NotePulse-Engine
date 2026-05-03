// @author Nebula_Zorua

package funkin.game.modchart;
import flixel.tweens.FlxEase;
import funkin.game.modchart.events.*;
import funkin.game.modchart.modifiers.*;

// Need to add nodes, aliases and all that shit -Manganos

// Weird amalgamation of Schmovin' modifier system, Andromeda modifier system and my own new shit -neb

class ModManager {
	public var swapPlayers:Bool = false;
	public function registerDefaultModifiers()
	{
		var quickRegs:Array<Any> = [
			FlipModifier,
			ReverseModifier,
			InvertModifier,
			DrunkModifier,
			BeatModifier,
			AlphaModifier,
			ReceptorScrollModifier, 
			ScaleModifier, 
			ConfusionModifier, 
			OpponentModifier, 
			TransformModifier, 
			InfinitePathModifier, 
			PerspectiveModifier, 
			AccelModifier, 
			XModifier
		];
		for (mod in quickRegs)
			quickRegister(Type.createInstance(mod, [this]));

		quickRegister(new RotateModifier(this));
		quickRegister(new RotateModifier(this, 'center', new Vector3((FlxG.width* 0.5) - (Note.swagWidth/2), (FlxG.height* 0.5) - Note.swagWidth/2)));
		quickRegister(new LocalRotateModifier(this, 'local'));
		quickRegister(new SubModifier("noteSpawnTime", this));
		setValue("noteSpawnTime", 2000);
		setValue("xmod", 1);
		for(i in 0...4)
			setValue('xmod$i', 1);
	}


    private var state:PlayState;
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
    
    inline public function quickRegister(mod:Modifier)
        registerMod(mod.getName(), mod);

    public function registerMod(modName:String, mod:Modifier, ?registerSubmods = true){
        register.set(modName, mod);
		//registerByType.get(mod.getModType()).set(modName, mod);
		switch (mod.getModType()){
			case NOTE_MOD:
				notemodRegister.set(modName, mod);
			case MISC_MOD:
				miscmodRegister.set(modName, mod);
		}
		timeline.addMod(modName);
		modArray.push(mod);

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

	private inline function getP(player:Int):Int {
        if (!swapPlayers || player == -1) return player;
        return 1 - player;
    }

	inline public function get(modName:String)
		return register.get(modName);
	
	inline public function getPercent(modName:String, player:Int)
		return !register.exists(modName)?0:get(modName).getPercent(player);

	inline public function getValue(modName:String, player:Int):Float
		return !register.exists(modName)?0:get(modName).getValue(player);

    inline public function setPercent(modName:String, val:Float, player:Int=-1)
		setValue(modName, val/100, player);

	inline public function setCurrentPercent(modName:String, val:Float, player:Int = -1)
		setCurrentValue(modName, val / 100, player);

	inline public function getTargetPercent(modName:String, player:Int)
		return !register.exists(modName) ? 0 : get(modName).getTargetPercent(player);

	inline public function getTargetValue(modName:String, player:Int)
		return !register.exists(modName) ? 0 : get(modName).getTargetValue(player);

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

	public function setValue(modName:String, val:Float, player:Int=-1){
		player = getP(player);
		if (player == -1)
		{
			for (pN in 0...2)
				setValue(modName, val, pN);
		}
		else
		{
			var daMod = register.get(modName);
			if (daMod == null)
			{
				Log.warn("The modifier " + modName + " cannot be set as it's null");
				return;
			}
			var mod = daMod.parent==null?daMod:daMod.parent;
			var name = mod.getName();
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
				activeMods[player]=[];

			register.get(modName).setValue(val, player);
			
			if (!activeMods[player].contains(name) && mod.shouldExecute(player, val)){
				if (daMod.getName() != name)
					activeMods[player].push(daMod.getName());
				activeMods[player].push(name);
			}else if (!mod.shouldExecute(player, val)){

				// there is prob a better way to do this
				// i just dont know it
				var modParent = daMod.parent;
				if(modParent==null){
					for (name => mod in daMod.submods)
					{
						modParent = daMod; // because if this gets called at all, there's atleast 1 submod!!
						break;
					}
				}
				if(daMod!=modParent)
					activeMods[player].remove(daMod.getName());
				if (modParent!=null){
					if (modParent.shouldExecute(player, modParent.getValue(player))){
						activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
						return;
					}
					for (subname => submod in modParent.submods){
						if(submod.shouldExecute(player, submod.getValue(player))){
							activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
							return;
						}
					}
					activeMods[player].remove(modParent.getName());
				}else
					activeMods[player].remove(daMod.getName());
			}

			activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
		}
    }

    public function new(state:PlayState) {
        this.state=state;
    }

	public function update(elapsed:Float)
	{
		for (mod in modArray)
		{
			if (mod.active && mod.doesUpdate())
			    mod.update(elapsed);
		}
	}

    public function updateTimeline(curStep:Float)
		timeline.update(curStep);

	public function getBaseX(direction:Int, player:Int):Float {
		return PlayField.fields[player].members[direction].defX;
	}

	public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int)
	{
		final note:Note = (obj is Note ? cast obj : null);
		
		obj.x = (pos.x - obj.width * .5);
		if(obj is Note && note.isSustainNote)
			obj.x += note.parent.width/2 - note.width;
		
		if (note != null && note.isSustainNote)
		{
			note.y = pos.y;
		}
		else
		{
			obj.y = (pos.y - obj.height * .5);
		}
		
		if (activeMods[player] != null)
		{
			for (name in activeMods[player])
			{
				var mod:Modifier = notemodRegister.get(name);
				if (mod == null || !obj.active) continue;
				
				if (obj is Note) mod.updateNote(beat, cast obj, pos, player);
				else if (obj is StrumNote) mod.updateReceptor(beat, cast obj, pos, player);
				//else if (obj is NoteSplash) mod.updateNoteSplash(beat, cast obj, pos, player);
				//else if (obj is SustainSplash) mod.updateSustainSplash(beat, cast obj, pos, player);
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
		if(exclusions==null)exclusions=[]; // since [] cant be a default value for.. some reason?? "its not constant!!" kys haxe
		if (pos == null)
			pos = new Vector3();

		if (!obj.active)return pos;

		pos.x = getBaseX(data, player);
		pos.y = 50 + diff;
		pos.z = 0;

		if(activeMods[player] != null){
			for (name in activeMods[player]){
				if (exclusions.contains(name))continue; // because some modifiers may want the path without reverse, for example. (which is actually more common than you'd think!)
				var mod:Modifier = notemodRegister.get(name);
				if (mod==null)continue;
				if(!obj.active)continue;
				pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
			}
		}
		return pos;
    }

	public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:String = 'linear', player:Int = -1, ?startVal:Float){
		if(player==-1){
			queueEase(step, endStep, modName, target, style, 0);
			queueEase(step, endStep, modName, target, style, 1);
		} else {
			var easeFunc = FlxEase.linear;
			try {
				var newEase = Reflect.getProperty(FlxEase, style);
				if (newEase != null)
					easeFunc = newEase;
			}
			timeline.addEvent(new ModEaseEvent(step, endStep, modName, target, easeFunc, player, this));
		}
	}

	public function queueSet(step:Float, modName:String, target:Float, player:Int = -1){
		if (player == -1){
			queueSet(step, modName, target, 0);
			queueSet(step, modName, target, 1);
		}
		else
			timeline.addEvent(new SetEvent(step, modName, target, player, this));
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

	public function ease(modName:String, beat:Float, len:Float, val:Float, easeFunc:EaseFunction, player:Int, ?_:Int)
		timeline.addEvent(new ModEaseEvent(beat * 4, (beat + len) * 4, modName, val, easeFunc, player, this));

	public function set(modName:String, beat:Float, val:Float, player:Int, ?_:Int)
		timeline.addEvent(new SetEvent(beat * 4, modName, val, player, this));
}