package funkin.game.modchart.engine.modifiers.list;

import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.core.VisualParameters;
import funkin.game.modchart.backend.util.ModchartUtil;

class Skew extends Modifier {
	var xID = 0;
	var yID = 0;

	public function new(pf) {
		super(pf);

		xID = findID('skewX');
		yID = findID('skewY');
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final receptorName = Std.string(params.lane);
		final player = params.player;

		final x = getUnsafe(xID, player) + getPercent('skewX' + receptorName, player);
		final y = getUnsafe(yID, player) + getPercent('skewY' + receptorName, player);

		data.skewX += x;
		data.skewY += y;

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
