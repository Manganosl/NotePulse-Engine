package funkin.game.modchart.modifiers;

class SnapModifier extends NoteModifier {
	override function getOrder() return Modifier.ModifierOrder.LAST;

	var sXi:Modifier;
	var sYi:Modifier;
	var sZi:Modifier;
	var sY:Modifier;
	var sZ:Modifier;

	override function bind() {
		sXi = submods.get("snapXInterval");
		sYi = submods.get("snapYInterval");
		sZi = submods.get("snapZInterval");
		sY = submods.get("snapY");
		sZ = submods.get("snapZ");
	}

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		pos.x = FlxMath.lerp(pos.x, MathUtil.snap(pos.x, subVal(sXi, player)), getValue(player));
		pos.y = FlxMath.lerp(pos.y, MathUtil.snap(pos.y, subVal(sYi, player)), subVal(sY, player));
		pos.z = FlxMath.lerp(pos.z, MathUtil.snap(pos.z, subVal(sZi, player)), subVal(sZ, player));
		return pos;
	}
	
	override function getName() return "snapX";
	override function getSubmods() return ["snapXInterval", "snapYInterval", "snapZInterval", "snapY", "snapZ"];
}