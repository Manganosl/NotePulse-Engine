package funkin.game.modchart.modifiers;

class TransformModifier extends NoteModifier { // this'll be transformX in ModManager
	override function getName() return 'transformX';
	
	override function getOrder() return Modifier.ModifierOrder.LAST;
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		pos.x += getValue(player) + getSubmodValue("transformX-a", player);
		pos.y += getSubmodValue("transformY", player) + getSubmodValue("transformY-a", player);
		pos.z += (getSubmodValue('transformZ', player) + getSubmodValue("transformZ-a", player)) / 1280;

		pos.x += getColumnSubmodValue('transform', data, player, 'X') + getColumnSubmodValue('transform', data, player, 'X-a');
		pos.y += getColumnSubmodValue('transform', data, player, 'Y') + getColumnSubmodValue('transform', data, player, 'Y-a');
		pos.z += (getColumnSubmodValue('transform', data, player, 'Z') + getColumnSubmodValue('transform', data, player, 'Z-a')) / 1280;

		if(obj is Note){
			pos.x += getSubmodValue('transformNoteX', player);
			pos.y += getSubmodValue('transformNoteY', player);
			pos.z += getSubmodValue('transformNoteZ', player) / 1280;

			pos.x += getColumnSubmodValue('transformNote', data, player, 'X');
			pos.y += getColumnSubmodValue('transformNote', data, player, 'Y');
			pos.z += getColumnSubmodValue('transformNote', data, player, 'Z') / 1280;
		}
		
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = ["transformY", "transformZ", "transformX-a", "transformY-a", "transformZ-a", "transformNoteX", "transformNoteY", "transformNoteZ"];
		
		for (i in 0...PlayState.SONG.mania+1)
		{
			subMods.push('transform${i}X');
			subMods.push('transform${i}Y');
			subMods.push('transform${i}Z');
			subMods.push('transform${i}X-a');
			subMods.push('transform${i}Y-a');
			subMods.push('transform${i}Z-a');
			subMods.push('transformNote${i}X');
			subMods.push('transformNote${i}Y');
			subMods.push('transformNote${i}Z');
		}
		return subMods;
	}
}
