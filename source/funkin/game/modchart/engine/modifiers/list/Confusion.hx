package funkin.game.modchart.engine.modifiers.list;

import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.core.VisualParameters;

class Confusion extends Modifier {
	// Pre-computed IDs indexed by axisIdx (0='', 1='x', 2='y', 3='z') to avoid Std.string(lane) allocations.
	static final AXES = ['', 'x', 'y', 'z'];

	var confusionIDs:Array<Int>;
	var confusionLaneIDs:Array<Array<Int>>;
	var angleIDs:Array<Int>;
	var angleLaneIDs:Array<Array<Int>>;
	var confusionOffIDs:Array<Int>;
	var confusionOffLaneIDs:Array<Array<Int>>;
	// dizzy/roll/twirl IDs (realAxisIdx: 0=z/dizzy, 1=x/roll, 2=y/twirl)
	var dizzySpeedIDs:Array<Int>;
	var dizzyIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		final maxKeys = 16;
		confusionIDs = [for (a in AXES) findID('confusion' + a)];
		confusionLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('confusion' + a + l)]];
		angleIDs = [for (a in AXES) findID('angle' + a)];
		angleLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('angle' + a + l)]];
		confusionOffIDs = [for (a in AXES) findID('confusionOffset' + a)];
		confusionOffLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('confusionOffset' + a + l)]];
		// realAxisIdx 0='z'→dizzy, 1='x'→roll, 2='y'→twirl
		dizzyIDs = [findID('dizzy'), findID('roll'), findID('twirl')];
		dizzySpeedIDs = [findID('dizzySpeed'), findID('rollSpeed'), findID('twirlSpeed')];
	}

	// axisIdx: 0='' 1='x' 2='y' 3='z'; realAxisIdx: 0=z 1=x 2=y
	private inline function applyConfusion(vis:VisualParameters, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int) {
		final lane = params.lane;
		final player = params.player;

		var confVal = getUnsafe(confusionIDs[axisIdx], player);
		var offVal = getUnsafe(confusionOffIDs[axisIdx], player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS) {
			confVal += getUnsafe(confusionLaneIDs[axisIdx][lane], player);
			offVal += getUnsafe(confusionOffLaneIDs[axisIdx][lane], player);
		}

		var angle = 0.;
		angle -= (params.curBeat * confVal) % 360;
		angle += offVal;

		// dizzy/roll/twirl
		final dc = getUnsafe(dizzyIDs[realAxisIdx], player);
		if (dc != 0)
			angle += dc * (params.distance * 0.1 * (1 + getUnsafe(dizzySpeedIDs[realAxisIdx], player)));

		if (realAxisIdx == 1) vis.angleX += angle;
		else if (realAxisIdx == 2) vis.angleY += angle;
		else vis.angleZ += angle;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		applyConfusion(data, params, 0, 0); // '' → z
		applyConfusion(data, params, 1, 1); // 'x' → x
		applyConfusion(data, params, 2, 2); // 'y' → y
		applyConfusion(data, params, 3, 0); // 'z' → z

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}