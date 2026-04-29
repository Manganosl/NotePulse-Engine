package funkin.modchart.modifiers;

import flixel.math.FlxPoint;

class ScaleModifier extends NoteModifier
{
	override function getName() return 'tiny';
	
	override function getOrder() return PRE_REVERSE;
	
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	inline function getScale(prefix:String, sprite:Dynamic, scale:FlxPoint, data:Int, player:Int):FlxPoint
	{
		final isSus:Bool = ((sprite is Note) && sprite.isSustainNote && !sprite.isSustainEnd);
		
		final squish = lerp(1, 2, getSubmodValue("squish", player) + getSubmodValue('squish${data}', player));
		final stretch = lerp(1, .5, getSubmodValue("stretch", player) + getSubmodValue('stretch${data}', player));
		
		if (isSus)
		{
			scale.y = sprite.baseScale.y;
		}
		else
		{
			scale.y *= (0.7 - getValue(player));
			scale.y *= (1 - getSubmodValue('tinyY', player));
			scale.y *= (1 - getSubmodValue('tiny${data}Y', player));
			scale.y *= (1 - getSubmodValue('$prefix${data}ScaleY', player));
			
			scale.y /= squish;
			scale.y /= stretch;
		}
		
		scale.x *= (0.7 - getValue(player));
		scale.x *= (1 - getSubmodValue('tinyX', player));
		scale.x *= (1 - getSubmodValue('tiny${data}X', player));
		scale.x *= (1 - getSubmodValue('$prefix${data}ScaleX', player));
		
		scale.x *= squish;
		scale.x *= stretch;
		
		return scale;
	}
	
	function getObjectScale(obj:IModNote, prefix:String, player:Int):FlxPoint
	{
		if (getSubmodValue('${prefix}ScaleX', player) > 0 || getSubmodValue('${prefix}ScaleY', player) > 0)
		{
			var scaleX = getSubmodValue('${prefix}ScaleX', player);
			var scaleY = getSubmodValue('${prefix}ScaleY', player);
			if (scaleX == 0) scaleX = obj.baseScale.x;
			if (scaleY == 0) scaleY = obj.baseScale.y;
			
			return getScale(prefix, obj, FlxPoint.weak(scaleX, scaleY), obj.noteData, player);
		}
		
		return getScale(prefix, obj, FlxPoint.weak(obj.baseScale.x, obj.baseScale.y), obj.noteData, player);
	}
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int)
	{
		note.scale.copyFrom(getObjectScale(note, 'note', player));
	}
	
	override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int)
	{
		receptor.scale.copyFrom(getObjectScale(receptor, 'receptor', player));
	}
	
	override function updateNoteSplash(beat:Float, splash:NoteSplash, pos:Vector3, player:Int)
	{
		splash.scale.copyFrom(getObjectScale(splash, 'noteSplash', player));
	}
	
	override function updateSustainSplash(beat:Float, splash:SustainSplash, pos:Vector3, player:Int)
	{
		splash.scale.copyFrom(getObjectScale(splash, 'sustainSplash', player));
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [
			"squish",
			"stretch",
			"tinyX",
			"tinyY",
			"receptorScaleX",
			"receptorScaleY",
			"noteScaleX",
			"noteScaleY",
			"noteSplashScaleX",
			"noteSplashScaleY",
			"sustainSplashScaleX",
			"sustainSplashScaleY"
		];
		
		var receptors = modMgr.receptors[0];
		var kNum = receptors.length;
		for (i in 0...PlayState.SONG.mania+1)
		{
			subMods.push('tiny${i}X');
			subMods.push('tiny${i}Y');
			subMods.push('squish${i}');
			subMods.push('stretch${i}');
			subMods.push('receptor${i}ScaleX');
			subMods.push('receptor${i}ScaleY');
			subMods.push('note${i}ScaleX');
			subMods.push('note${i}ScaleY');
			subMods.push('noteSplash${i}ScaleX');
			subMods.push('noteSplash${i}ScaleY');
			subMods.push('sustainSplash${i}ScaleX');
			subMods.push('sustainSplash${i}ScaleY');
		}
		return subMods;
	}
}
