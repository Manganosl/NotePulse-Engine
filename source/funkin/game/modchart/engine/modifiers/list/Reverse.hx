package funkin.game.modchart.engine.modifiers.list;

import flixel.FlxG;
import flixel.math.FlxMath;
import funkin.game.modchart.Manager;
import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.util.ModchartUtil;

// Default modifier
// Handles scroll speed, scroll angle and reverse modifiers
class Reverse extends Modifier {
	// Pre-computed IDs to avoid string allocations in the hot render path.
	var _splitID:Int;
	var _alternateID:Int;
	var _crossID:Int;
	var _reverseGlobalID:Int;
	var _reverseIDs:Array<Int>;
	var _unboundedReverseID:Int;
	var _centeredID:Int;
	var _xmodGlobalID:Int;
	var _xmodLaneIDs:Array<Int>;
	var _scrollAngleXID:Int;
	var _scrollAngleYID:Int;
	var _scrollAngleZID:Int;
	var _curvedScrollPeriodID:Int;
	var _curvedScrollXID:Int;
	var _curvedScrollYID:Int;
	var _curvedScrollZID:Int;

	public function new(pf) {
		super(pf);

		setPercent('xmod', 1, -1);

		final maxKeys = 16;
		_splitID = findID('split');
		_alternateID = findID('alternate');
		_crossID = findID('cross');
		_reverseGlobalID = findID('reverse');
		_reverseIDs = [for (l in 0...maxKeys) findID('reverse' + l)];
		_unboundedReverseID = findID('unboundedReverse');
		_centeredID = findID('centered');
		_xmodGlobalID = findID('xmod');
		_xmodLaneIDs = [for (l in 0...maxKeys) findID('xmod' + l)];
		_scrollAngleXID = findID('scrollAngleX');
		_scrollAngleYID = findID('scrollAngleY');
		_scrollAngleZID = findID('scrollAngleZ');
		_curvedScrollPeriodID = findID('curvedScrollPeriod');
		_curvedScrollXID = findID('curvedScrollX');
		_curvedScrollYID = findID('curvedScrollY');
		_curvedScrollZID = findID('curvedScrollZ');
	}

	public function getReverseValue(dir:Int, player:Int) {
		var kNum = getKeyCount();
		var val:Float = 0;
		if (dir >= Math.floor(kNum * 0.5))
			val += getUnsafe(_splitID, player);

		if ((dir % 2) == 1)
			val += getUnsafe(_alternateID, player);

		var first = kNum * 0.25;
		var last = kNum - 1 - first;

		if (dir >= first && dir <= last)
			val += getUnsafe(_crossID, player);

		val += getUnsafe(_reverseGlobalID, player) + getUnsafe(_reverseIDs[dir], player);

		if (getUnsafe(_unboundedReverseID, player) == 0) {
			val %= 2;
			if (val > 1)
				val = 2 - val;
		}

		// downscroll
		if (ClientPrefs.data.downScroll)
			val = 1 - val;
		return val;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var initialY = Adapter.getDefaultReceptorY(params.lane, player) + ARROW_SIZEDIV2;
		var reversePerc = getReverseValue(params.lane, player);
		var shift = FlxMath.lerp(initialY, HEIGHT - initialY, reversePerc);

		var centerPercent = getUnsafe(_centeredID, player);
		shift = FlxMath.lerp(shift, (HEIGHT * 0.5) - ARROW_SIZEDIV2, centerPercent);

		var distance = params.distance;

		distance *= Adapter.getCurrentScrollSpeed();

		var scroll = new Vector3(0, FlxMath.lerp(distance, -distance, reversePerc));
		scroll = applyScrollMods(scroll, params);

		curPos.x = curPos.x + scroll.x;
		curPos.y = shift + scroll.y;
		curPos.z = curPos.z + scroll.z;

		return curPos;
	}

	function applyScrollMods(scroll:Vector3, params:ModifierParameters) {
		var player = params.player;
		var angleX = 0.;
		var angleY = 0.;
		var angleZ = 0.;

		// Speed
		scroll.y *= getUnsafe(_xmodGlobalID, player) + getUnsafe(_xmodLaneIDs[params.lane], player);

		// Main
		angleX += getUnsafe(_scrollAngleXID, player);
		angleY += getUnsafe(_scrollAngleYID, player);
		angleZ += getUnsafe(_scrollAngleZID, player);

		// Curved
		final shift:Float = params.distance * 0.25 * (1 + getUnsafe(_curvedScrollPeriodID, player));

		angleX += shift * getUnsafe(_curvedScrollXID, player);
		angleY += shift * getUnsafe(_curvedScrollYID, player);
		angleZ += shift * getUnsafe(_curvedScrollZID, player);

		// angleY doesnt do anything if angleX and angleZ are disabled
		if (angleX == 0 && angleZ == 0)
			return scroll;

		scroll = ModchartUtil.rotate3DVector(scroll, angleX, angleY, angleZ);

		return scroll;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}