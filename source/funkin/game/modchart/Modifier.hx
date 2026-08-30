// @author Nebula_Zorua

package funkin.game.modchart;

// Based on Schmovin' and Andromeda's modifier systems

enum ModifierType {
    NOTE_MOD; // used when the mod moves notes
    MISC_MOD; // used for anything else
}

@:enum
abstract ModifierOrder(Int) to Int{
	var FIRST = -1000;
    var PRE_REVERSE = -3;
    var REVERSE = -2;
    var POST_REVERSE = -1;
    var DEFAULT = 0;
	var LAST = 1000;
	
}

class Modifier {
	public var modMgr:ModManager;
	public var percents:Array<Float> = [0, 0];
	public var submods:Map<String, Modifier> = [];
	public var parent:Modifier; // for submods
    public var active:Bool = false; // used for performance reasons

	public var lowerCaseName:String;

    public function getModType()
		return MISC_MOD; // if this is NOTE_MOD then this will be called on notes & receptors
	
	public function ignorePos()
		return false;

	public function ignoreUpdateReceptor()
		return true;

	public function ignoreUpdateNote()
		return true;

    public function doesUpdate()
        return getModType()==MISC_MOD; // override in your modifier if you want it to have update(elapsed) called
    
	public function shouldExecute(player:Int, value:Float):Bool
	{
		return value != 0; // override if your modifier should run, even if percent isn't 0
	}

    public function getOrder():Int
		return DEFAULT;

    public function getName():String{
		throw new haxe.exceptions.NotImplementedException(); // override in your modifier!!! 
		return '';
	}

	public function getAliases():Map<String,String> {
		return [];
	}

	inline public function getTargetOtherValue(modName:String, player:Int)
		return modMgr.getTargetValue(modName, player);

	public function getOtherValue(modName:String, player:Int)
		return modMgr.getValue(modName, player);

	public function getTargetValue(player:Int):Float // because most the time when you getValue you wanna get the CURRENT value, not the target
		return percents[player];

	inline public function getTargetPercent(player:Int):Float
		return getTargetValue(player) * 100;

	public function getValue(player:Int):Float
		return percents[player];

	public function getPercent(player:Int):Float
		return getValue(player) * 100;

	public function setValue(value:Float, player:Int = -1){ // because most the time when you setValue you wanna set the TARGET value, not the current
		setCurrentValue(value, player);
		if (player == -1)
			for (idx in 0...percents.length)
				percents[idx] = value;
		else
			percents[player] = value;
	}

	public function setCurrentValue(value:Float, player:Int = -1){
		if(player == -1){
			for(idx in 0...percents.length){
				modMgr.touchMod(getName(), idx);
				percents[idx] = value;
			} 
		} else {
			modMgr.touchMod(getName(), player);
			percents[player] = value;
		}
	}

	public function setPercent(percent:Float, player:Int = -1)
		setValue(percent * 0.01, player);
	

	public function getSubmods():Array<String>
		return [];
	
	inline function lerp(a:Float, b:Float, c:Float)
		return a + (b - a) * c;

	public function getSubmodPercent(modName:String, player:Int){
		var m = submods.get(modName);
		return m == null ? 0 : m.getPercent(player);
	}

	public function getSubmodValue(modName:String, player:Int){
		var m = submods.get(modName);
		return m == null ? 0 : m.getValue(player);
	}

	var submodColumnCache:Map<String, Array<Modifier>> = [];
	function getColumnSubmodEntry(baseName:String, data:Int, suffix:String = ''):Modifier {
		if (data < 0) return null;
		var cacheKey = suffix == '' ? baseName : '$baseName\000$suffix';
		var arr = submodColumnCache.get(cacheKey);
		if (arr == null){
			arr = [];
			submodColumnCache.set(cacheKey, arr);
		}
		var cached = (data < arr.length) ? arr[data] : null;
		if (cached == null){
			cached = submods.get('$baseName$data$suffix');
			while (arr.length <= data)
				arr.push(null);
			arr[data] = cached;
		}
		return cached;
	}

	public function getColumnSubmodValue(baseName:String, data:Int, player:Int, suffix:String = ''):Float {
		var m = getColumnSubmodEntry(baseName, data, suffix);
		return m == null ? 0 : m.getValue(player);
	}

	public function getColumnSubmodPercent(baseName:String, data:Int, player:Int, suffix:String = ''):Float {
		var m = getColumnSubmodEntry(baseName, data, suffix);
		return m == null ? 0 : m.getPercent(player);
	}

	public function setSubmodPercent(modName:String, endPercent:Float, player:Int)
		return submods.get(modName).setPercent(endPercent, player);

	public function setSubmodValue(modName:String, endValue:Float, player:Int)
		return submods.get(modName).setValue(endValue, player);
    
	public function new(modMgr:ModManager, ?parent:Modifier)
	{
		this.modMgr = modMgr;
		this.parent = parent;
		for (submod in getSubmods())
			submods.set(submod, new SubModifier(submod, modMgr, this));
		
	}

	// time is the note/receptor strumtime
	// diff is the 'visual difference' aka the strumTime - currentTime w/ math for scrollspeed, etc
    // beat is the curBeat, but with decimals
    // pos is the current position of the note/receptor
    // player is 0 for bf, 1 for dad
    // data is the column/direction/notedata
    // note/receptor is self-explanatory

    public function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int){}
	public function updateNote(beat:Float, note:Note, pos:Vector3, player:Int){}
	public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)return pos;

    public function update(elapsed:Float){}
}