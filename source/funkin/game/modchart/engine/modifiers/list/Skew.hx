package funkin.game.modchart.engine.modifiers.list;

import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.core.VisualParameters;
import funkin.game.modchart.backend.util.ModchartUtil;

class Skew extends Modifier {
	var xID = 0;
	var yID = 0;

	// Per-lane IDs to avoid Std.string(lane) allocations.
	var xLaneIDs:Array<Int>;
	var yLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		xID = findID('skewX');
		yID = findID('skewY');

		xLaneIDs = [for (l in 0...16) findID('skewX' + l)];
		yLaneIDs = [for (l in 0...16) findID('skewY' + l)];
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final player = params.player;
		final lane = params.lane;

		final x = getUnsafe(xID, player) + getUnsafe(xLaneIDs[lane], player);
		final y = getUnsafe(yID, player) + getUnsafe(yLaneIDs[lane], player);

		data.skewX += x;
		data.skewY += y;

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}