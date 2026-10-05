package funkin.game.modchart.modifiers;

class ReverseModifier extends NoteModifier {
	override function getOrder() return REVERSE;
	
	override function getName() return 'reverse';

	var sSplit:Modifier;
	var sAlternate:Modifier;
	var sCross:Modifier;
	var sSplitS:Modifier;
	var sAlternateS:Modifier;
	var sCrossS:Modifier;
	var sReverseS:Modifier;
	var sCentered:Modifier;
	var sUnbounded:Modifier;
	var cReverse:Array<Modifier>;

	override function bind() {
		sSplit = submods.get('split');
		sAlternate = submods.get('alternate');
		sCross = submods.get('cross');
		sSplitS = submods.get('splitScroll');
		sAlternateS = submods.get('alternateScroll');
		sCrossS = submods.get('crossScroll');
		sReverseS = submods.get('reverseScroll');
		sCentered = submods.get('centered');
		sUnbounded = submods.get('unboundedReverse');
		cReverse = bindColumn('reverse');
	}
	
	public function getReverseValue(dir:Int, player:Int, ?scrolling = false){
		var scroll = (scrolling == true);
		var kNum = modMgr.receptors[player].length;
		var val:Float = 0;
		if (dir >= kNum / 2) val += subVal(scroll ? sSplitS : sSplit, player);
		
		if ((dir % 2) == 1) val += subVal(scroll ? sAlternateS : sAlternate, player);
		
		var first = kNum / 4;
		var last = kNum - 1 - first;
		
		if (dir >= first && dir <= last) val += subVal(scroll ? sCrossS : sCross, player);
		
		if (!scroll) val += getValue(player) + colVal(cReverse, dir, player);
		else val += subVal(sReverseS, player);
		
		if (subVal(sUnbounded, player) == 0)
		{
			val %= 2;
			if (val > 1) val = 2 - val;
		}
		
		if (ClientPrefs.data.downScroll) val = 1 - val;
		
		return val;
	}
	
	public function getScrollReversePerc(dir:Int, player:Int) return getReverseValue(dir, player) * 100;
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
        var perc = getReverseValue(data, player);
		var shift = MathUtil.scale(perc, 0, 1, 50, FlxG.height - 150);
		var mult = MathUtil.scale(perc, 0, 1, 1, -1);
		shift = MathUtil.scale(subVal(sCentered, player), 0, 1, shift, (FlxG.height/2) - 56);
		
		pos.y = (shift + (visualDiff * mult));
		
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [
			"cross",
			"split",
			"alternate",
			"reverseScroll",
			"crossScroll",
			"splitScroll",
			"alternateScroll",
			"centered",
			"unboundedReverse"
		];
		
		var receptors = modMgr.receptors[0];
		for (i in 0...PlayState.SONG.mania+1)
		{
			subMods.push('reverse${i}');
		}
		return subMods;
	}
}