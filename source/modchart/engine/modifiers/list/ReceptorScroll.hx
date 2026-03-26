package modchart.engine.modifiers.list;

import flixel.FlxG;
import flixel.math.FlxMath;
import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;
import modchart.backend.util.ModchartUtil;

class ReceptorScroll extends Modifier {
	public function new(pf) {
		super(pf);

		setPercent('receptorScrollSpeed', 1, -1);
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final perc = getPercent('receptorScroll', params.player);

		if (perc == 0)
			return curPos;

		final moveSpeed = (Conductor.crochet * 4) / getPercent('receptorScrollSpeed', params.player);

		var diff = -params.distance;
		var songTime = Conductor.songPosition;
		var vDiff = -(diff - songTime) / moveSpeed;
		var reversed = Math.floor(vDiff) % 2 == 0;

		var startY = curPos.y;
		var revPerc = reversed ? 1 - vDiff % 1 : vDiff % 1;
		// haha perc 30
		var upscrollOffset = 50;
		var downscrollOffset = HEIGHT - 150;

		var endY = upscrollOffset + ((downscrollOffset - ARROW_SIZEDIV2) * revPerc) + ARROW_SIZEDIV2;

		curPos.y = FlxMath.lerp(startY, endY, perc);
		return curPos;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final perc = getPercent('receptorScroll', params.player);
		if (perc == 0)
			return data;

		final moveSpeed = (Conductor.crochet * 4) / getPercent('receptorScrollSpeed', params.player);
		var songTime = Conductor.songPosition;
		var currentCycle = Math.floor(songTime / moveSpeed) % 2;
		var noteTime = songTime + params.distance;
		var noteCycle = Math.floor(noteTime / moveSpeed) % 2;

		if (currentCycle == noteCycle) {
			data.alpha = 1.0;
		} else {
			data.alpha = 0.3;
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
