package funkin.game.modchart.modifiers;

// I got crazy trying to find a way to make this less laggy
// Literally the laggiest mod ever

private class DrunkTerm {
	public var kind:Int;
	public var tan:Bool;
	public var useMain:Bool;
	public var perc:Modifier;
	public var speed:Modifier;
	public var period:Modifier;
	public var offset:Modifier;

	public function new(kind:Int, tan:Bool, useMain:Bool, perc:Modifier, speed:Modifier, period:Modifier, offset:Modifier) {
		this.kind = kind;
		this.tan = tan;
		this.useMain = useMain;
		this.perc = perc;
		this.speed = speed;
		this.period = period;
		this.offset = offset;
	}
}

class DrunkModifier extends NoteModifier {
	override function getName() return 'drunk';

	var termCache:Array<Array<DrunkTerm>> = [];
	function drunk(axis:String, tan:Bool):DrunkTerm {
		return new DrunkTerm(0, tan, axis == '', axis == '' ? null : submods.get('drunk${axis}'),
			submods.get('drunk${axis}Speed'), submods.get('drunk${axis}Period'), submods.get('drunk${axis}Offset'));
	}

	function tipsy(axis:String, tan:Bool):DrunkTerm {
		return new DrunkTerm(1, tan, false, submods.get('tipsy${axis}'),
			submods.get('tipsy${axis}Speed'), null, submods.get('tipsy${axis}Offset'));
	}

	function bumpy(axis:String, tan:Bool):DrunkTerm {
		return new DrunkTerm(2, tan, false, submods.get('bumpy${axis}'),
			null, submods.get('bumpy${axis}Period'), submods.get('bumpy${axis}Offset'));
	}

	function buildTerms(ds:String):Array<DrunkTerm> {
		return [
			drunk('', false), tipsy('X', false), bumpy('X', false),
			drunk('Y', false), tipsy('', false), bumpy('Y', false),
			drunk('Z', false), tipsy('Z', false), bumpy('', false),

			drunk(ds, false), tipsy('X' + ds, false), bumpy('X' + ds, false),
			drunk('Y' + ds, false), tipsy(ds, false), bumpy('Y' + ds, false),
			drunk('Z' + ds, false), tipsy('Z' + ds, false), bumpy(ds, false),

			drunk('Tan', true), tipsy('TanX', true), bumpy('TanX', true),
			drunk('TanY', true), tipsy('Tan', true), bumpy('TanY', true),
			drunk('TanZ', true), tipsy('TanZ', true), bumpy('Tan', true),

			drunk('Tan' + ds, true), tipsy('TanX' + ds, true), bumpy('TanX' + ds, true),
			drunk('TanY' + ds, true), tipsy('Tan' + ds, true), bumpy('TanY' + ds, true),
			drunk('TanZ' + ds, true), tipsy('TanZ' + ds, true), bumpy('Tan' + ds, true)
		];
	}

	function getTerms(data:Int):Array<DrunkTerm> {
		var t = (data >= 0 && data < termCache.length) ? termCache[data] : null;
		if (t == null) {
			t = buildTerms(Std.string(data));
			if (data >= 0) {
				while (termCache.length <= data) termCache.push(null);
				termCache[data] = t;
			}
		}
		return t;
	}

	function evalTerm(t:DrunkTerm, player:Int, time:Float, visualDiff:Float, data:Float):Float {
		var perc = t.useMain ? getValue(player) : subVal(t.perc, player);
		if (perc == 0) return 0;

		switch(t.kind){
			case 0:
				var speed = subVal(t.speed, player);
				var period = subVal(t.period, player);
				var offset = subVal(t.offset, player);
				var angle = time * (1 + speed) + data * ((offset * 0.2) + 0.2) + visualDiff * ((period * 10) + 10) / FlxG.height;
				return perc * ((t.tan ? Math.tan(angle) : Math.cos(angle)) * (Note.swagWidth * 0.5));
			case 1:
				var speed = subVal(t.speed, player);
				var offset = subVal(t.offset, player);
				var angle = (time * ((speed * 1.2) + 1.2) + data * ((offset * 1.8) + 1.8));
				return perc * ((t.tan ? Math.tan(angle) : Math.cos(angle)) * Note.swagWidth * .4);
			default:
				var period = subVal(t.period, player);
				if (period != -1) {
					var offset = subVal(t.offset, player);
					var angle = (visualDiff + (100.0 * offset)) / ((period * 24.0) + 24.0);
					return perc * 40 * (t.tan ? Math.tan(angle) : Math.sin(angle));
				}
				return 0;
		}
	}

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		var time = (Conductor.songPosition/1000);
		var t = getTerms(data);

		var i = 0;
		for(_ in 0...4){
			pos.x +=
				evalTerm(t[i], player, time, visualDiff, data)
				+ evalTerm(t[i + 1], player, time, visualDiff, data)
				+ evalTerm(t[i + 2], player, time, visualDiff, data);
			pos.y +=
				evalTerm(t[i + 3], player, time, visualDiff, data)
				+ evalTerm(t[i + 4], player, time, visualDiff, data)
				+ evalTerm(t[i + 5], player, time, visualDiff, data);
			pos.z +=
				(evalTerm(t[i + 6], player, time, visualDiff, data)
				+ evalTerm(t[i + 7], player, time, visualDiff, data)
				+ evalTerm(t[i + 8], player, time, visualDiff, data)) / 1280;
			i += 9;
		}

		return pos;
	}

	override function getAliases(){
		return [
			"tipZ" => "tipsyZ",
			"tipZSpeed" => "tipsyZSpeed",
			"tipZOffset" => "tipsyZOffset"
		];
	}

	override function getSubmods(){

		var axes = ["X", "Y", "Z"];
		var props = [
			["Speed", "Offset", "Period"],
			["Speed", "Offset"],
			["Offset", "Period"],
			["Speed", "Offset", "Period"],
			["Speed", "Offset"],
			["Offset", "Period"]
		];

		var shids:Array<String> = ["drunk","tipsy","bumpy","drunkTan","tipsyTan","bumpyTan"];
		var submods:Array<String> = [];
		
		for(i in 0...shids.length){
			var mod = shids[i];
			for(a in 0...axes.length){
				var axe = axes[a];
				if(a==(i % axes.length))axe='';
				submods.push('$mod$axe');
				var p = props[i];
				for(prop in p)submods.push('$mod$axe$prop');
				
				for(d in 0...PlayState.SONG.mania + 1){
					submods.push('$mod$axe$d');
					for(prop in p)submods.push('$mod$axe$d$prop');
				}
			}
		}
		
		submods.remove("drunk");
		return submods;
	}

}