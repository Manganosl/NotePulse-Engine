package funkin.game.modchart.modifiers;

class AlphaModifier extends NoteModifier
{
	override function getName() return 'stealth';

	override function getModType()
		return NOTE_MOD;

	public static var fadeDistY = 120;

	public function getHiddenSudden(player:Int = -1, column:Int = -1)
	{
		return getWithColumnVariant("hidden", player, column) * getWithColumnVariant("sudden", player, column);
	}

	public function getHiddenEnd(player:Int = -1, column:Int = -1)
	{
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, -1, -1.25)
			+ (FlxG.height * 0.5) * getWithColumnVariant("hiddenOffset", player, column);
	}

	public function getHiddenStart(player:Int = -1, column:Int = -1)
	{
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, 0, -0.25)
			+ (FlxG.height * 0.5) * getWithColumnVariant("hiddenOffset", player, column);
	}

	public function getSuddenEnd(player:Int = -1, column:Int = -1)
	{
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, 1, 1.25)
			+ (FlxG.height * 0.5) * getWithColumnVariant("suddenOffset", player, column);
	}

	public function getSuddenStart(player:Int = -1, column:Int = -1)
	{
		return (FlxG.height * 0.5)
			+ fadeDistY * MathUtil.scale(getHiddenSudden(player, column), 0, 1, 0, 0.25)
			+ (FlxG.height * 0.5) * getWithColumnVariant("suddenOffset", player, column);
	}

	inline function getWithColumnVariant(mod:String, player:Int, column:Int)
	{
		return getSubmodValue(mod, player) + getSubmodValue('$mod$column', player);
	}

	function getVisibility(yPos:Float, player:Int, column:Int):Float
	{
		var distFromCenter = yPos;
		var alpha:Float = 0;

		if (yPos < 0 && getSubmodValue("stealthPastReceptors", player) == 0) return 1.0;

		var time = Conductor.songPosition / 1000;

		var hiddenValue = getWithColumnVariant("hidden", player, column);
		if (hiddenValue != 0)
		{
			var hiddenAdjust = MathUtil.clamp(MathUtil.scale(yPos, getHiddenStart(player, column), getHiddenEnd(player, column), 0, -1), -1, 0);
			alpha += hiddenValue * hiddenAdjust;
		}

		var suddenValue = getWithColumnVariant("sudden", player, column);
		if (suddenValue != 0)
		{
			var suddenAdjust = MathUtil.clamp(MathUtil.scale(yPos, getSuddenStart(player, column), getSuddenEnd(player, column), 0, -1), -1, 0);
			alpha += suddenValue * suddenAdjust;
		}

		if (getValue(player) != 0) alpha -= getValue(player);

		alpha -= getSubmodValue('stealth$column', player);

		if (getSubmodValue("blink", player) != 0)
		{
			var f = MathUtil.quantizeAlpha(Math.sin(time * 10), 0.3333);
			alpha += MathUtil.scale(f, 0, 1, -1, 0);
		}

		if (getSubmodValue("randomVanish", player) != 0)
		{
			var realFadeDist:Float = 240;
			alpha += MathUtil.scale(Math.abs(distFromCenter), realFadeDist, 2 * realFadeDist, -1, 0) * getSubmodValue("randomVanish", player);
		}

		return MathUtil.clamp(alpha + 1, 0, 1);
	}

	function getGlow(visible:Float)
	{
		var glow = MathUtil.scale(visible, 1, 0.5, 0, 1.3);
		return MathUtil.clamp(glow, 0, 1);
	}

	function getAlpha(visible:Float)
	{
		var alpha = MathUtil.scale(visible, 0.5, 0, 1, 0);
		return MathUtil.clamp(alpha, 0, 1);
	}

	override function shouldExecute(player:Int, val:Float) return true;

	override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int)
	{
		if(note.isSustainNote && !note.isSustainEnd) return;
		var player = note.playField.player;
		var column = note.noteData;
		var speed = modMgr.state.songSpeed * (note.multSpeed * note.modSpeed);
		var yPos:Float = modMgr.getVisPos(Conductor.songPosition, note.strumTime, speed) + 50;

		note.rgbShader.flash = 0;
		var alphaMod = (1 - getSubmodValue("alpha", player)) * (1 - getSubmodValue('alpha$column', player))
			* (1 - getSubmodValue("noteAlpha", player)) * (1 - getSubmodValue('noteAlpha$column', player));
		var alpha = getVisibility(yPos, player, column);

		if (getSubmodValue("dontUseStealthGlow", player) == 0)
		{
			note.alphaMod = getAlpha(alpha);
			note.rgbShader.flash = getGlow(alpha);
		}
		else note.alphaMod = alpha;

		note.alphaMod *= alphaMod;
	}

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite):Vector3
	{
		var column = data;
		var yPos:Float = visualDiff + 50;

		var alphaMod = (1 - getSubmodValue("alpha", player)) * (1 - getSubmodValue('alpha$column', player))
			* (1 - getSubmodValue("noteAlpha", player)) * (1 - getSubmodValue('noteAlpha$column', player));
		var visibility = getVisibility(yPos, player, column);

		var finalAlpha:Float;
		var glow:Float = 0;

		if (getSubmodValue("dontUseStealthGlow", player) == 0)
		{
			finalAlpha = getAlpha(visibility);
			glow = getGlow(visibility);
		}
		else finalAlpha = visibility;

		pos.alpha = finalAlpha * alphaMod;
		pos.glow = glow;

		return pos;
	}

	override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int)
	{
		var column = receptor.noteData;
		var alpha = (1 - getSubmodValue("alpha", player)) * (1 - getSubmodValue('alpha$column', player));
		if (getSubmodValue("dark", player) != 0 || getSubmodValue('dark$column', player) != 0)
		{
			alpha = alpha * (1 - getSubmodValue("dark", player)) * (1 - getSubmodValue('dark$column', player));
		}
		receptor.rgbShader.alphaMult = alpha;
	}

	override function getSubmods()
	{
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
		for (i in 0...PlayState.SONG.mania+1)
		{
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