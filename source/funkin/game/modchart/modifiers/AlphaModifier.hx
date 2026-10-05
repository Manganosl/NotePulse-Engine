package funkin.game.modchart.modifiers;

class AlphaModifier extends NoteModifier
{
	override function getName() return 'stealth';

	override function getModType()
		return NOTE_MOD;

	public static var fadeDistY = 120;

	var sAlpha:Modifier;
	var sNoteAlpha:Modifier;
	var sHidden:Modifier;
	var sHiddenOffset:Modifier;
	var sSudden:Modifier;
	var sSuddenOffset:Modifier;
	var sBlink:Modifier;
	var sRandomVanish:Modifier;
	var sDark:Modifier;
	var sStealthPast:Modifier;
	var sDontGlow:Modifier;
	var cAlpha:Array<Modifier>;
	var cNoteAlpha:Array<Modifier>;
	var cDark:Array<Modifier>;
	var cHidden:Array<Modifier>;
	var cHiddenOffset:Array<Modifier>;
	var cSudden:Array<Modifier>;
	var cSuddenOffset:Array<Modifier>;
	var cStealth:Array<Modifier>;

	override function bind(){
		sAlpha = submods.get("alpha");
		sNoteAlpha = submods.get("noteAlpha");
		sHidden = submods.get("hidden");
		sHiddenOffset = submods.get("hiddenOffset");
		sSudden = submods.get("sudden");
		sSuddenOffset = submods.get("suddenOffset");
		sBlink = submods.get("blink");
		sRandomVanish = submods.get("randomVanish");
		sDark = submods.get("dark");
		sStealthPast = submods.get("stealthPastReceptors");
		sDontGlow = submods.get("dontUseStealthGlow");
		cAlpha = bindColumn("alpha");
		cNoteAlpha = bindColumn("noteAlpha");
		cDark = bindColumn("dark");
		cHidden = bindColumn("hidden");
		cHiddenOffset = bindColumn("hiddenOffset");
		cSudden = bindColumn("sudden");
		cSuddenOffset = bindColumn("suddenOffset");
		cStealth = bindColumn("stealth");
	}

	inline function both(s:Modifier, c:Array<Modifier>, column:Int, player:Int):Float
		return subVal(s, player) + colVal(c, column, player);

	public function getHiddenSudden(player:Int = -1, column:Int = -1){
		return both(sHidden, cHidden, column, player) * both(sSudden, cSudden, column, player);
	}

	public function getHiddenEnd(player:Int = -1, column:Int = -1){
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, -1, -1.25)
			+ (FlxG.height * 0.5) * both(sHiddenOffset, cHiddenOffset, column, player);
	}

	public function getHiddenStart(player:Int = -1, column:Int = -1){
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, 0, -0.25)
			+ (FlxG.height * 0.5) * both(sHiddenOffset, cHiddenOffset, column, player);
	}

	public function getSuddenEnd(player:Int = -1, column:Int = -1){
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, 1, 1.25)
			+ (FlxG.height * 0.5) * both(sSuddenOffset, cSuddenOffset, column, player);
	}

	public function getSuddenStart(player:Int = -1, column:Int = -1){
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, 0, 0.25)
			+ (FlxG.height * 0.5) * both(sSuddenOffset, cSuddenOffset, column, player);
	}

	function getVisibility(yPos:Float, player:Int, column:Int):Float{
		var distFromCenter = yPos;
		var alpha:Float = 0;

		if (yPos < 0 && subVal(sStealthPast, player) == 0) return 1.0;

		var hiddenValue = both(sHidden, cHidden, column, player);
		if (hiddenValue != 0)
		{
			var hiddenAdjust = MathUtil.clamp(MathUtil.scale(yPos, getHiddenStart(player, column), getHiddenEnd(player, column), 0, -1), -1, 0);
			alpha += hiddenValue * hiddenAdjust;
		}

		var suddenValue = both(sSudden, cSudden, column, player);
		if (suddenValue != 0)
		{
			var suddenAdjust = MathUtil.clamp(MathUtil.scale(yPos, getSuddenStart(player, column), getSuddenEnd(player, column), 0, -1), -1, 0);
			alpha += suddenValue * suddenAdjust;
		}

		if (getValue(player) != 0) alpha -= getValue(player);

		alpha -= colVal(cStealth, column, player);

		if(subVal(sBlink, player) != 0){
			var time = Conductor.songPosition / 1000;
			var f = MathUtil.quantizeAlpha(Math.sin(time * 10), 0.3333);
			alpha += MathUtil.scale(f, 0, 1, -1, 0);
		}

		var vanish = subVal(sRandomVanish, player);
		if(vanish != 0){
			var realFadeDist:Float = 240;
			alpha += MathUtil.scale(Math.abs(distFromCenter), realFadeDist, 2 * realFadeDist, -1, 0) * vanish;
		}

		return MathUtil.clamp(alpha + 1, 0, 1);
	}

	function getGlow(visible:Float){
		var glow = MathUtil.scale(visible, 1, 0.5, 0, 1.3);
		return MathUtil.clamp(glow, 0, 1);
	}

	function getAlpha(visible:Float){
		var alpha = MathUtil.scale(visible, 0.5, 0, 1, 0);
		return MathUtil.clamp(alpha, 0, 1);
	}

	override function shouldExecute(player:Int, val:Float) return true;

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite):Vector3{
		if(!Std.isOfType(obj, StrumNote)){
			var column = data;
			var yPos:Float = visualDiff + 50;

			var alphaMod = (1 - subVal(sAlpha, player)) * (1 - colVal(cAlpha, column, player))
				* (1 - subVal(sNoteAlpha, player)) * (1 - colVal(cNoteAlpha, column, player));
			var visibility = getVisibility(yPos, player, column);

			var finalAlpha:Float;
			var glow:Float = 0;

			if(subVal(sDontGlow, player) == 0){
				finalAlpha = getAlpha(visibility);
				glow = getGlow(visibility);
			}
			else finalAlpha = visibility;

			pos.alpha = finalAlpha * alphaMod;
			pos.glow = glow;
		} else {
			var alphaMod = (1 - subVal(sAlpha, player)) * (1 - colVal(cAlpha, data, player));
			var dark = subVal(sDark, player);
			var darkCol = colVal(cDark, data, player);
			if (dark != 0 || darkCol != 0)
				alphaMod = alphaMod * (1 - dark) * (1 - darkCol);
			pos.alpha = alphaMod;
		}
		return pos;
	}

	override function getSubmods(){
		var subMods:Array<String> = [
			"noteAlpha",
			"alpha",
			"hidden",
			"hiddenOffset",
			"sudden",
			"suddenOffset",
			"blink",
			"randomVanish",
			"dark",
			"useStealthGlow",
			"stealthPastReceptors",
			"dontUseStealthGlow"
		];
		for(i in 0...PlayState.SONG.mania+1){
			subMods.push('noteAlpha$i');
			subMods.push('alpha$i');
			subMods.push('dark$i');
			subMods.push('hidden$i');
			subMods.push('hiddenOffset$i');
			subMods.push('sudden$i');
			subMods.push('suddenOffset$i');
			subMods.push('stealth$i');
		}
		return subMods;
	}
}
