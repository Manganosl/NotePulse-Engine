package funkin.game.modchart;

import funkin.scripting.FunkinScript;

class ScriptedModifier extends Modifier {
	var name:String;
	var prefix:String;
	var modName:String;
	var modUpdate:Bool = false;
	var modOrder:Int = DEFAULT;
	var modType:ModifierType = MISC_MOD;
	
	var script:Null<FunkinScript> = null;
	
	public function new(modMgr:ModManager, scriptPath:String, name:String = '')
	{	
		this.prefix = "";
		modName = (this.name = name).toLowerCase();
		
		if (Paths.exists(scriptPath)) script = new FunkinScript(scriptPath);
		
		if (script == null){
			Log.warn('Modifier script "$name" could not be loaded');
		} else {
			script.set('NOTE_MOD', NOTE_MOD);
			script.set('MISC_MOD', MISC_MOD);
			
			script.set('FIRST', FIRST);
			script.set('PRE_REVERSE', PRE_REVERSE);
			script.set('REVERSE', REVERSE);
			script.set('POST_REVERSE', POST_REVERSE);
			script.set('DEFAULT', DEFAULT);
			script.set('LAST', LAST);

			script.set("getPercent", this.getPercent);
			script.set("getValue", this.getValue);
			script.set("getSubmodValue", this.getSubmodValue);
			script.set("getSubmodPercent", this.getSubmodPercent);
			
			modName = (script.call('getName', []) ?? modName);
			modType = (script.call('getModType', []) ?? MISC_MOD);
			modOrder = (script.call('getOrder', []) ?? DEFAULT);
			modUpdate = (script.call('doesUpdate', []) ?? (modType == MISC_MOD));
		}
		
		super(modMgr, parent);
		
		script?.call('onCreateMod', [modMgr, name, prefix, parent]);
	}
	
	public override function getOrder():Int return modOrder;
	public override function getName():String return modName;
	public override function doesUpdate():Bool return modUpdate;
	public override function getModType():ModifierType return modType;
	
	public override function getSubmods():Array<String> return cast (script?.call('getSubmods', []) ?? []);
	
	public override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		return (script?.call('getPos', [time, visualDiff, timeDiff, beat, pos, data, player, obj]) ?? pos);
	}
	
	public override function update(elapsed:Float):Void script?.call('onUpdate', [elapsed]);
	public override function updateNote(beat, obj, pos, player) script?.call('updateNote', [beat, obj, pos, player]);
	public override function updateReceptor(beat, obj, pos, player) script?.call('updateReceptor', [beat, obj, pos, player]);
}