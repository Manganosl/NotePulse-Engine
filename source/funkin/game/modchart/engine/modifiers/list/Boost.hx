package funkin.game.modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.util.ModchartUtil;

class Boost extends Modifier {
	// Pre-computed IDs to avoid Std.string(lane) allocations.
	var _boostID:Int;
	var _boostLaneIDs:Array<Int>;
	var _brakeID:Int;
	var _brakeLaneIDs:Array<Int>;
	var _waveID:Int;
	var _waveLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		setPercent('waveMult', 1, -1);

		final maxKeys = 16;
		_boostID = findID('boost');
		_boostLaneIDs = [for (l in 0...maxKeys) findID('boost' + l)];
		_brakeID = findID('brake');
		_brakeLaneIDs = [for (l in 0...maxKeys) findID('brake' + l)];
		_waveID = findID('wave');
		_waveLaneIDs = [for (l in 0...maxKeys) findID('wave' + l)];
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var lane = params.lane;

		var fYOffset = params.distance;

		final boost = getUnsafe(_boostID, player) + getUnsafe(_boostLaneIDs[lane], player);
		if (boost != 0) {
			var fEffectHeight = HEIGHT;
			var fNewYOffset = fYOffset * 1.5 / ((fYOffset + fEffectHeight / 1.2) / fEffectHeight);
			var fAccelYAdjust = .75 * boost * (fNewYOffset - fYOffset);
			fAccelYAdjust = ModchartUtil.clamp(fAccelYAdjust, -400, 400);

			curPos.y += fAccelYAdjust;
		}

		final brake = getUnsafe(_brakeID, player) + getUnsafe(_brakeLaneIDs[lane], player);

		if (brake != 0) {
			var fEffectHeight = HEIGHT;
			var fScale = FlxMath.remapToRange(fYOffset, 0., fEffectHeight, 0, 1.);
			var fNewYOffset = fYOffset * fScale;
			var fBrakeYAdjust = .75 * brake * (fNewYOffset - fYOffset);
			fBrakeYAdjust = ModchartUtil.clamp(fBrakeYAdjust, -400., 400.);
			curPos.y += fBrakeYAdjust;
		}
		final wave = getUnsafe(_waveID, player) + getUnsafe(_waveLaneIDs[lane], player);

		if (wave != 0) {
			curPos.y += wave * 20.0 * sin(fYOffset / 96.);
		}

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}