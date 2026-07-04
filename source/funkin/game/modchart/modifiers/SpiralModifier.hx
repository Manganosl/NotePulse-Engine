package funkin.game.modchart.modifiers;

class SpiralModifier extends NoteModifier {
	override function getName() return 'spiralX';
	override function getSubmods() { return [ "spiralY", "spiralZ", "spiralXOffset", "spiralXPeriod", "spiralYOffset", "spiralYPeriod", "spiralZOffset", "spiralZPeriod", ]; } 

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		var spiralX = getValue(player);
		var spiralY = getSubmodValue("spiralY", player); 
		var spiralZ = getSubmodValue("spiralZ", player) / 100; 

		if (spiralX != 0) { 
			var offset = getSubmodValue("spiralXOffset", player); 
			var period = getSubmodValue("spiralXPeriod", player); 
			var freq = (period + 1) * 0.01; 
			var phase = visualDiff * freq + offset; 

			pos.x += visualDiff * spiralX * 0.1 * Math.cos(phase); 
		} 
		if (spiralY != 0) { 
			var offset = getSubmodValue("spiralYOffset", player); 
			var period = getSubmodValue("spiralYPeriod", player);
			var freq = (period + 1) * 0.01; 
			var phase = visualDiff * freq + offset;

			pos.y += visualDiff * spiralY * 0.1 * Math.sin(phase); 
		} 
		if (spiralZ != 0) { 
			var offset = getSubmodValue("spiralZOffset", player); 
			var period = getSubmodValue("spiralZPeriod", player); 
			var freq = (period + 1) * 0.01; 
			var phase = visualDiff * freq + offset; 
			
			pos.z += visualDiff * spiralZ * 0.1 * Math.sin(phase); 
		} 
		
		return pos; 
	}
}