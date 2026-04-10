package funkin.game.modchart.engine.modifiers.list;

import flixel.FlxG;

class Zoom extends Modifier {
	var __localPercent:Null<Float> = -1;

	override public function render(curPos:Vector3, params:ModifierParameters) {
		updatePercent(params);

		// center zoom
		if (__localPercent != 1)
			curPos = __applyZoom(curPos, new Vector3(getReceptorX(Math.round(getKeyCount(params.player) * .5), params.player), FlxG.height * .5),
				__localPercent);
		return curPos;
	}

	inline function __applyZoom(pos:Vector3, origin:Vector3, amount:Float) {
		var diff = pos.subtract(origin);
		diff.scaleBy(amount);
		return diff.add(origin);
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		if (__localPercent == null)
			updatePercent(params);

		data.scaleX = data.scaleX * __localPercent;
		data.scaleY = data.scaleY * __localPercent;

		__localPercent = null;

		return data;
	}

	inline function updatePercent(params:ModifierParameters) {
		__localPercent = 1 + ((getPercent('zoom', params.player) - getPercent('mini', params.player)) * 0.5);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}