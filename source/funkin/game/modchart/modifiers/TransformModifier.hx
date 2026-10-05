package funkin.game.modchart.modifiers;

class TransformModifier extends NoteModifier { // this'll be transformX in ModManager
	override function getName() return 'transformX';
	
	override function getOrder() return Modifier.ModifierOrder.LAST;

	var sXa:Modifier;
	var sY:Modifier;
	var sYa:Modifier;
	var sZ:Modifier;
	var sZa:Modifier;
	var sNX:Modifier;
	var sNY:Modifier;
	var sNZ:Modifier;
	var cX:Array<Modifier>;
	var cY:Array<Modifier>;
	var cZ:Array<Modifier>;
	var cXa:Array<Modifier>;
	var cYa:Array<Modifier>;
	var cZa:Array<Modifier>;
	var cNX:Array<Modifier>;
	var cNY:Array<Modifier>;
	var cNZ:Array<Modifier>;

	override function bind() {
		sXa = submods.get("transformX-a");
		sY = submods.get("transformY");
		sYa = submods.get("transformY-a");
		sZ = submods.get("transformZ");
		sZa = submods.get("transformZ-a");
		sNX = submods.get("transformNoteX");
		sNY = submods.get("transformNoteY");
		sNZ = submods.get("transformNoteZ");
		cX = bindColumn('transform', 'X');
		cY = bindColumn('transform', 'Y');
		cZ = bindColumn('transform', 'Z');
		cXa = bindColumn('transform', 'X-a');
		cYa = bindColumn('transform', 'Y-a');
		cZa = bindColumn('transform', 'Z-a');
		cNX = bindColumn('transformNote', 'X');
		cNY = bindColumn('transformNote', 'Y');
		cNZ = bindColumn('transformNote', 'Z');
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		pos.x += getValue(player) + subVal(sXa, player);
		pos.y += subVal(sY, player) + subVal(sYa, player);
		pos.z += (subVal(sZ, player) + subVal(sZa, player)) / 1280;

		pos.x += colVal(cX, data, player) + colVal(cXa, data, player);
		pos.y += colVal(cY, data, player) + colVal(cYa, data, player);
		pos.z += (colVal(cZ, data, player) + colVal(cZa, data, player)) / 1280;

		if(obj is Note){
			pos.x += subVal(sNX, player);
			pos.y += subVal(sNY, player);
			pos.z += subVal(sNZ, player) / 1280;

			pos.x += colVal(cNX, data, player);
			pos.y += colVal(cNY, data, player);
			pos.z += colVal(cNZ, data, player) / 1280;
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
