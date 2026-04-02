package funkin.game.modchart.engine.modifiers.list;

import flixel.FlxG;
import flixel.math.FlxMath;
import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.core.VisualParameters;
import funkin.game.modchart.backend.util.ModchartUtil;

class Stealth extends Modifier {
	// Pre-computed IDs to avoid Std.string(lane) allocations.
	var _stealthID:Int;
	var _darkID:Int;
	var _stealthLaneIDs:Array<Int>;
	var _darkLaneIDs:Array<Int>;
	var _alphaID:Int;
	var _alphaLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		setPercent('alpha', 1, -1);

		setPercent('suddenStart', 5, -1);
		setPercent('suddenEnd', 3, -1);
		setPercent('suddenGlow', 1, -1);

		setPercent('hiddenStart', 5, -1);
		setPercent('hiddenEnd', 3, -1);
		setPercent('hiddenGlow', 1, -1);

		final maxKeys = 16;
		_stealthID = findID('stealth');
		_darkID = findID('dark');
		_stealthLaneIDs = [for (l in 0...maxKeys) findID('stealth' + l)];
		_darkLaneIDs = [for (l in 0...maxKeys) findID('dark' + l)];
		_alphaID = findID('alpha');
		_alphaLaneIDs = [for (l in 0...maxKeys) findID('alpha' + l)];
	}

	private inline function computeSudden(data:VisualParameters, params:ModifierParameters) {
		final player = params.player;

		final sudden = getPercent('sudden', player);

		if (sudden == 0)
			return;

		final start = getPercent('suddenStart', player) * 100;
		final end = getPercent('suddenEnd', player) * 100;
		final glow = getPercent('suddenGlow', player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 1, 0);

		if (glow != 0)
			data.glow += Math.max(0, (1 - alpha) * sudden * 2) * glow;
		data.alpha *= alpha * sudden;
	}

	private inline function computeHidden(data:VisualParameters, params:ModifierParameters) {
		final player = params.player;

		final hidden = getPercent('hidden', player);

		if (hidden == 0)
			return;

		final start = getPercent('hiddenStart', player) * 100;
		final end = getPercent('hiddenEnd', player) * 100;
		final glow = getPercent('hiddenGlow', player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 0, 1);

		if (glow != 0)
			data.glow += Math.max(0, (1 - alpha) * hidden * 2) * glow;
		data.alpha *= alpha * hidden;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		final player = params.player;
		final lane = params.lane;

		final visibility = params.isTapArrow
			? getUnsafe(_stealthID, player) + getUnsafe(_stealthLaneIDs[lane], player)
			: getUnsafe(_darkID, player) + getUnsafe(_darkLaneIDs[lane], player);
		data.alpha = ((getUnsafe(_alphaID, player) + getUnsafe(_alphaLaneIDs[lane], player)) * (1 - ((Math.max(0.5, visibility) - 0.5) * 2)));
		data.glow += visibility * 2;

		// sudden & hidden
		if (params.isTapArrow) // non receptor
		{
			computeSudden(data, params);
			computeHidden(data, params);
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}