package funkin.game.modchart.modifiers;

class SnapModifier extends NoteModifier {
	override function getOrder() return Modifier.ModifierOrder.LAST;

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		pos.x = FlxMath.lerp(pos.x, MathUtil.snap(pos.x, getSubmodValue("snapXInterval", player)), getValue(player));
		pos.y = FlxMath.lerp(pos.y, MathUtil.snap(pos.y, getSubmodValue("snapYInterval", player)), getSubmodValue("snapY", player));
		pos.z = FlxMath.lerp(pos.z, MathUtil.snap(pos.z, getSubmodValue("snapZInterval", player)), getSubmodValue("snapZ", player));
		return pos;
	}
	
	override function getName() return "snapX";
	override function getSubmods() return ["snapXInterval", "snapYInterval", "snapZInterval", "snapY", "snapZ"];
}