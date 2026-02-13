package modchart.engine.modifiers.list;

import flixel.FlxG;
import flixel.math.FlxMath;
import modchart.Manager;
import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

// Default modifier
// Handles scroll speed, scroll angle and reverse modifiers
class Reverse extends Modifier {
	public function new(pf) {
		super(pf);

		setPercent('xmod', 1, -1);
	}

	public function getReverseValue(dir:Int, player:Int) {
		var kNum = getKeyCount();
		var val:Float = 0;
		if (dir >= Math.floor(kNum * 0.5))
			val = val + getPercent("split", player);

		if ((dir % 2) == 1)
			val = val + getPercent("alternate", player);

		var first = kNum * 0.25;
		var last = kNum - 1 - first;

		if (dir >= first && dir <= last)
			val = val + getPercent("cross", player);

		val = val + getPercent('reverse', player) + getPercent("reverse" + Std.string(dir), player);

		if (getPercent("unboundedReverse", player) == 0) {
			val %= 2;
			if (val > 1)
				val = 2 - val;
		}

		// downscroll
		if (Adapter.instance.getDownscroll())
			val = 1 - val;
		return val;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var initialY = Adapter.instance.getDefaultReceptorY(params.lane, player) + ARROW_SIZEDIV2;
		var reversePerc = getReverseValue(params.lane, player);
		var shift = FlxMath.lerp(initialY, HEIGHT - initialY, reversePerc);

		var centerPercent = getPercent('centered', params.player);
		shift = FlxMath.lerp(shift, (HEIGHT * 0.5) - ARROW_SIZEDIV2, centerPercent);

		var distance = params.distance;

		distance *= Adapter.instance.getCurrentScrollSpeed();

		var scroll = new Vector3(0, FlxMath.lerp(distance, -distance, reversePerc));
		scroll = applyScrollMods(scroll, params);

		curPos.x = curPos.x + scroll.x;
		curPos.y = shift + scroll.y;
		curPos.z = curPos.z + scroll.z;

		return curPos;
	}

	function applyScrollMods(scroll:Vector3, params:ModifierParameters) {
		var player = params.player;
		var laneStr = Std.string(params.lane);

		var totalXMod = getPercent('xmod', player) + getPercent('xmod' + laneStr, player);
		scroll.y *= totalXMod;

		var angleX = getPercent('scrollAngleX', player) + getPercent('scrollAngleX' + laneStr, player);
		var angleY = getPercent('scrollAngleY', player) + getPercent('scrollAngleY' + laneStr, player);
		var angleZ = getPercent('scrollAngleZ', player) + getPercent('scrollAngleZ' + laneStr, player);

		var totalPeriod = getPercent('curvedScrollPeriod', player) + getPercent('curvedScrollPeriod' + laneStr, player);
		final shift:Float = params.distance * 0.25 * (1 + totalPeriod);

		angleX += shift * (getPercent('curvedScrollX', player) + getPercent('curvedScrollX' + laneStr, player));
		angleY += shift * (getPercent('curvedScrollY', player) + getPercent('curvedScrollY' + laneStr, player));
		angleZ += shift * (getPercent('curvedScrollZ', player) + getPercent('curvedScrollZ' + laneStr, player));

		if (angleX == 0 && angleZ == 0)
			return scroll;

		return ModchartUtil.rotate3DVector(scroll, angleX, angleY, angleZ);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
